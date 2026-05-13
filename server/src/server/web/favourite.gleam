import given
import gleam/http.{Delete, Get, Put}
import gleam/json
import gleam/list
import gleam/string
import pog
import server/model/favourite
import server/sql
import server/web
import wisp.{type Request, type Response}
import youid/uuid

pub fn put(
  req: Request,
  activity_id_str: String,
  ctx: web.Context,
) -> Response {
  use <- wisp.require_method(req, Put)
  use user_id <- web.with_authenticated_user(ctx)
  use activity_id <- given.ok(uuid.from_string(activity_id_str), fn(_) {
    wisp.bad_request("Invalid activity ID format")
  })
  let id = uuid.v7()

  case sql.create_favourite(ctx.db_connection, id, user_id, activity_id) {
    Error(error) -> {
      wisp.log_error("QueryError " <> string.inspect(error))
      wisp.internal_server_error()
    }
    Ok(pog.Returned(_, [row, ..])) ->
      wisp.json_response(
        row
          |> favourite.from_create_favourite_row
          |> favourite.to_json
          |> json.to_string,
        200,
      )
    Ok(pog.Returned(_, [])) ->
      wisp.json_response(
        json.object([
          #("user_id", user_id |> uuid.to_string |> json.string),
          #("activity_id", activity_id |> uuid.to_string |> json.string),
        ])
          |> json.to_string,
        200,
      )
  }
}

pub fn delete(
  req: Request,
  activity_id_str: String,
  ctx: web.Context,
) -> Response {
  use <- wisp.require_method(req, Delete)
  use user_id <- web.with_authenticated_user(ctx)
  use activity_id <- given.ok(uuid.from_string(activity_id_str), fn(_) {
    wisp.bad_request("Invalid activity ID format")
  })

  case
    sql.get_booking_by_user_and_activity(
      ctx.db_connection,
      user_id,
      activity_id,
    )
  {
    Error(error) -> {
      wisp.log_error("QueryError " <> string.inspect(error))
      wisp.internal_server_error()
    }
    Ok(pog.Returned(_, [_, ..])) ->
      wisp.json_response(
        json.object([
          #("error", json.string("Cannot unfavourite a booked activity")),
        ])
          |> json.to_string,
        409,
      )
    Ok(pog.Returned(_, [])) ->
      case sql.delete_favourite(ctx.db_connection, user_id, activity_id) {
        Error(error) -> {
          wisp.log_error("QueryError " <> string.inspect(error))
          wisp.internal_server_error()
        }
        Ok(pog.Returned(_, [])) -> wisp.not_found()
        Ok(pog.Returned(_, [_, ..])) -> wisp.no_content()
      }
  }
}

pub fn get_mine(req: Request, ctx: web.Context) -> Response {
  use <- wisp.require_method(req, Get)
  use user_id <- web.with_authenticated_user(ctx)

  case sql.get_favourites_by_user(ctx.db_connection, user_id) {
    Error(error) -> {
      wisp.log_error("QueryError " <> string.inspect(error))
      wisp.internal_server_error()
    }
    Ok(pog.Returned(_, rows)) -> {
      let favourites =
        rows |> list.map(favourite.from_get_favourites_by_user_row)
      wisp.json_response(
        json.object([
          #("favourites", json.array(favourites, favourite.to_json)),
        ])
          |> json.to_string,
        200,
      )
    }
  }
}

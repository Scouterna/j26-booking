import given
import gleam/dynamic/decode
import gleam/http.{Delete, Get, Post, Put}
import gleam/int
import gleam/json
import gleam/list
import gleam/result
import gleam/string
import pog
import server/model/booking
import server/sql
import server/utils
import server/web
import wisp.{type Request, type Response}
import youid/uuid

const page_size = 20

const default_page = 0

pub type BookingInput {
  BookingInput(
    group_free_text: String,
    responsible_name: String,
    phone_number: String,
    participant_count: Int,
  )
}

fn booking_input_decoder() -> decode.Decoder(BookingInput) {
  use group_free_text <- decode.field("group_free_text", decode.string)
  use responsible_name <- decode.field("responsible_name", decode.string)
  use phone_number <- decode.field("phone_number", decode.string)
  use participant_count <- decode.field("participant_count", decode.int)
  decode.success(BookingInput(
    group_free_text:,
    responsible_name:,
    phone_number:,
    participant_count:,
  ))
}

pub fn create(
  req: Request,
  activity_id_str: String,
  ctx: web.Context,
) -> Response {
  use <- wisp.require_method(req, Post)
  use activity_id <- given.ok(uuid.from_string(activity_id_str), fn(_) {
    wisp.bad_request("Invalid activity ID format")
  })
  use json_body <- wisp.require_json(req)
  use input <- given.ok(decode.run(json_body, booking_input_decoder()), fn(_) {
    wisp.bad_request("Invalid JSON payload")
  })
  let id = uuid.v7()
  // TODO: Get user_id from JWT authentication
  let assert Ok(user_id) =
    uuid.from_string("a1b2c3d4-e5f6-4a90-abcd-ef1234567890")
  // TODO: Get booker_group_id and booker_group_name from JWT
  let booker_group_id = 0
  let booker_group_name = "TODO: from JWT"

  case
    sql.create_booking(
      ctx.db_connection,
      id,
      user_id,
      activity_id,
      booker_group_id,
      booker_group_name,
      input.group_free_text,
      input.responsible_name,
      input.phone_number,
      input.participant_count,
    )
  {
    Error(error) -> {
      wisp.log_error("QueryError " <> string.inspect(error))
      wisp.internal_server_error()
    }
    Ok(pog.Returned(_, [])) -> wisp.internal_server_error()
    Ok(pog.Returned(_, [row, ..])) -> {
      let created_booking = booking.from_create_booking_row(row)
      let location =
        web.base_path <> "/api/bookings/" <> uuid.to_string(created_booking.id)
      wisp.json_response(
        booking.to_json(created_booking) |> json.to_string,
        201,
      )
      |> wisp.set_header("location", location)
    }
  }
}

pub fn get_one(req: Request, id: String, ctx: web.Context) -> Response {
  use <- wisp.require_method(req, Get)
  use booking_id <- given.ok(uuid.from_string(id), fn(_) {
    wisp.bad_request("Invalid booking ID format")
  })
  case sql.get_booking(ctx.db_connection, booking_id) {
    Error(error) -> {
      wisp.log_error("QueryError " <> string.inspect(error))
      wisp.internal_server_error()
    }
    Ok(pog.Returned(_, [])) -> wisp.not_found()
    Ok(pog.Returned(_, [row, ..])) ->
      wisp.json_response(
        row
          |> booking.from_get_booking_row
          |> booking.to_json
          |> json.to_string,
        200,
      )
  }
}

pub fn get_mine(req: Request, ctx: web.Context) -> Response {
  use <- wisp.require_method(req, Get)
  case ctx.authentication_result {
    web.Authenticated(user) ->
      case uuid.from_string(user.user_id) {
        Ok(user_id) ->
          case sql.get_bookings_by_user(ctx.db_connection, user_id) {
            Error(error) -> {
              wisp.log_error("QueryError " <> string.inspect(error))
              wisp.internal_server_error()
            }
            Ok(pog.Returned(_, rows)) -> {
              let bookings =
                rows |> list.map(booking.from_get_bookings_by_user_row)
              wisp.json_response(
                json.object([
                  #("bookings", json.array(bookings, booking.to_json)),
                ])
                  |> json.to_string,
                200,
              )
            }
          }
        Error(_) -> wisp.json_response("{\"bookings\":[]}", 200)
      }
    _ -> wisp.json_response("{\"bookings\":[]}", 200)
  }
}

pub fn get_by_activity(
  req: Request,
  activity_id_str: String,
  ctx: web.Context,
) -> Response {
  use <- wisp.require_method(req, Get)
  use activity_id <- given.ok(uuid.from_string(activity_id_str), fn(_) {
    wisp.bad_request("Invalid activity ID format")
  })
  let request_query = wisp.get_query(req)

  use page <- web.ensure_valid_query_param(
    in: request_query,
    with_name: "page",
    if_missing_return: default_page,
    using: fn(i) { int.parse(i) |> result.try(utils.ensure_non_negative) },
    else_respond_with: "Invalid page parameter. Must be a non-negative integer",
  )

  let limit = page_size
  let offset = page * page_size
  case
    sql.get_bookings_by_activity(ctx.db_connection, activity_id, limit, offset)
  {
    Error(error) -> {
      wisp.log_error("QueryError " <> string.inspect(error))
      wisp.internal_server_error()
    }
    Ok(pog.Returned(_, rows)) -> {
      let bookings = rows |> list.map(booking.from_get_bookings_by_activity_row)
      wisp.json_response(
        json.object([
          #("bookings", json.array(bookings, booking.to_json)),
        ])
          |> json.to_string,
        200,
      )
    }
  }
}

pub fn update(req: Request, id: String, ctx: web.Context) -> Response {
  use <- wisp.require_method(req, Put)
  use booking_id <- given.ok(uuid.from_string(id), fn(_) {
    wisp.bad_request("Invalid booking ID format")
  })
  use json_body <- wisp.require_json(req)
  use input <- given.ok(decode.run(json_body, booking_input_decoder()), fn(_) {
    wisp.bad_request("Invalid JSON payload")
  })

  case
    sql.update_booking(
      ctx.db_connection,
      booking_id,
      input.group_free_text,
      input.responsible_name,
      input.phone_number,
      input.participant_count,
    )
  {
    Error(error) -> {
      wisp.log_error("QueryError " <> string.inspect(error))
      wisp.internal_server_error()
    }
    Ok(pog.Returned(_, [])) -> wisp.not_found()
    Ok(pog.Returned(_, [row, ..])) ->
      wisp.json_response(
        row
          |> booking.from_update_booking_row
          |> booking.to_json
          |> json.to_string,
        200,
      )
  }
}

pub fn delete(req: Request, id: String, ctx: web.Context) -> Response {
  use <- wisp.require_method(req, Delete)
  use booking_id <- given.ok(uuid.from_string(id), fn(_) {
    wisp.bad_request("Invalid booking ID format")
  })

  case sql.delete_booking(ctx.db_connection, booking_id) {
    Error(error) -> {
      wisp.log_error("QueryError " <> string.inspect(error))
      wisp.internal_server_error()
    }
    Ok(pog.Returned(_, [])) -> wisp.not_found()
    Ok(pog.Returned(_, [_, ..])) -> wisp.no_content()
  }
}

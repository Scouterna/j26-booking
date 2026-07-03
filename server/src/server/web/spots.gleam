import given
import gleam/http.{Get}
import gleam/json.{type Json}
import pog
import server/sql
import server/web
import wisp.{type Request, type Response}
import youid/uuid

/// Booked-spot counts for every activity, as `{ "spots": [{ activity_id,
/// spots_booked }] }`. Not user-specific and cheap to poll — no auth required.
/// The count is volatile (changes on every booking, by any user), so it lives
/// on its own endpoint rather than on the cacheable activity read shapes.
pub fn get_all(req: Request, ctx: web.Context) -> Response {
  use <- wisp.require_method(req, Get)
  case sql.list_activity_spots(ctx.db_connection) {
    Error(error) -> web.query_error(error)
    Ok(pog.Returned(_, rows)) ->
      wisp.json_response(
        json.object([#("spots", json.array(rows, row_to_json))])
          |> json.to_string,
        200,
      )
  }
}

/// Booked-spot count for a single activity, as `{ "spots_booked": <int> }`.
/// Used by the detail page and after booking mutations to read the live total.
pub fn get_one(req: Request, id: String, ctx: web.Context) -> Response {
  use <- wisp.require_method(req, Get)
  use activity_id <- given.ok(uuid.from_string(id), fn(_) {
    wisp.bad_request("Invalid activity ID format")
  })
  case sql.get_activity_spots(ctx.db_connection, activity_id) {
    Error(error) -> web.query_error(error)
    Ok(pog.Returned(_, [row, ..])) ->
      wisp.json_response(
        json.object([#("spots_booked", json.int(row.spots_booked))])
          |> json.to_string,
        200,
      )
    Ok(pog.Returned(_, [])) ->
      // The aggregate always returns a row; treat the impossible empty case as 0.
      wisp.json_response(
        json.object([#("spots_booked", json.int(0))]) |> json.to_string,
        200,
      )
  }
}

fn row_to_json(row: sql.ListActivitySpotsRow) -> Json {
  json.object([
    #("activity_id", row.activity_id |> uuid.to_string |> json.string),
    #("spots_booked", json.int(row.spots_booked)),
  ])
}

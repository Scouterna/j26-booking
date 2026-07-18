import gleam/dict.{type Dict}
import gleam/http.{Get}
import gleam/json.{type Json}
import gleam/list
import gleam/option
import gleam/set
import pog
import server/model/booking
import server/model/favourite
import server/sql
import server/web
import shared/model.{type Booking}
import wisp.{type Request, type Response}
import youid/uuid.{type Uuid}

/// Combined per-user activity status: the authenticated user's bookings and
/// favourites merged into a single sparse list. Only activities the user has
/// booked or favourited appear; `booked` dominates `favourited`, so an
/// activity that is both is reported once as `booked`. A `booked` entry
/// carries every booking the user holds on that activity (a
/// `bookings:others:create` holder can stack several on-behalf bookings).
pub fn get_mine(req: Request, ctx: web.Context) -> Response {
  use <- wisp.require_method(req, Get)
  use user <- web.with_authenticated_user(ctx)
  let user_id = user.id

  case sql.get_bookings_by_user(ctx.db_connection, user_id) {
    Error(error) -> web.query_error(error)
    Ok(pog.Returned(_, booking_rows)) ->
      case sql.get_favourites_by_user(ctx.db_connection, user_id) {
        Error(error) -> web.query_error(error)
        Ok(pog.Returned(_, favourite_rows)) -> {
          let bookings =
            booking_rows |> list.map(booking.from_get_bookings_by_user_row)
          let booked_ids =
            bookings |> list.map(fn(b) { b.activity_id }) |> set.from_list

          let booked_entries =
            bookings
            |> group_by_activity
            |> dict.to_list
            |> list.map(fn(pair) { booked_entry(pair.0, pair.1) })
          let favourite_entries =
            favourite_rows
            |> list.map(favourite.from_get_favourites_by_user_row)
            |> list.filter(fn(f) { !set.contains(booked_ids, f.activity_id) })
            |> list.map(fn(f) { favourited_entry(f.activity_id) })

          wisp.json_response(
            json.object([
              #(
                "statuses",
                json.preprocessed_array(list.append(
                  booked_entries,
                  favourite_entries,
                )),
              ),
            ])
              |> json.to_string,
            200,
          )
        }
      }
  }
}

/// Bucket the user's bookings per activity, preserving the query's row order
/// within each bucket, so each activity gets exactly one `booked` entry.
/// Public so tests can exercise the grouping directly; production code only
/// reaches it through `get_mine`.
pub fn group_by_activity(bookings: List(Booking)) -> Dict(Uuid, List(Booking)) {
  bookings
  |> list.fold(dict.new(), fn(acc, b) {
    dict.upsert(acc, b.activity_id, fn(existing) {
      case existing {
        option.Some(others) -> [b, ..others]
        option.None -> [b]
      }
    })
  })
  |> dict.map_values(fn(_, reversed) { list.reverse(reversed) })
}

fn booked_entry(activity_id: Uuid, bookings: List(Booking)) -> Json {
  json.object([
    #("activity_id", activity_id |> uuid.to_string |> json.string),
    #("status", json.string("booked")),
    #("bookings", json.array(bookings, booking.to_json)),
  ])
}

fn favourited_entry(activity_id: Uuid) -> Json {
  json.object([
    #("activity_id", activity_id |> uuid.to_string |> json.string),
    #("status", json.string("favourited")),
  ])
}

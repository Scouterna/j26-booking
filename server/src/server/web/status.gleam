import gleam/http.{Get}
import gleam/json.{type Json}
import gleam/list
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
/// activity that is both is reported once as `booked`.
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

          let booked_entries = list.map(bookings, booked_entry)
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

fn booked_entry(b: Booking) -> Json {
  json.object([
    #("activity_id", b.activity_id |> uuid.to_string |> json.string),
    #("status", json.string("booked")),
    #("booking", booking.to_json(b)),
  ])
}

fn favourited_entry(activity_id: Uuid) -> Json {
  json.object([
    #("activity_id", activity_id |> uuid.to_string |> json.string),
    #("status", json.string("favourited")),
  ])
}

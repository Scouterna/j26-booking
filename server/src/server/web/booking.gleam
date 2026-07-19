import given
import gleam/dynamic/decode
import gleam/float
import gleam/http.{Delete, Get, Post, Put}
import gleam/int
import gleam/json
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import gleam/time/timestamp
import pog
import server/model/booking
import server/scout_group
import server/sql
import server/utils
import server/web
import shared/model.{type Booking}
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
    /// The kår to book on behalf of. `Some` makes this a book-for-other
    /// request (requires `bookings:others:create`); absent books for the
    /// caller's own token group as always. Only honoured on create — the
    /// update handler ignores it (the booked-for kår is immutable).
    booker_group_id: option.Option(Int),
  )
}

fn booking_input_decoder() -> decode.Decoder(BookingInput) {
  use group_free_text <- decode.field("group_free_text", decode.string)
  use responsible_name <- decode.field("responsible_name", decode.string)
  use phone_number <- decode.field("phone_number", decode.string)
  use participant_count <- decode.field("participant_count", decode.int)
  use booker_group_id <- decode.optional_field(
    "booker_group_id",
    option.None,
    decode.optional(decode.int),
  )
  decode.success(BookingInput(
    group_free_text:,
    responsible_name:,
    phone_number:,
    participant_count:,
    booker_group_id:,
  ))
}

/// Rollback reasons for the booking create/update transactions, so the handler
/// can map each to the right HTTP status.
type BookingError {
  ActivityNotFound
  ActivityCalledOff
  /// Booking has not opened for the activity yet (issue #36); carries the
  /// effective opens-at so the 409 body can tell the client when it will.
  BookingNotYetOpen(opens_at: timestamp.Timestamp)
  /// The activity is over — past its end time (or start time, had it no end)
  /// — so it can no longer be booked (issue #35).
  ActivityHasPassed
  BookingNotFound
  /// The caller may not edit/delete this booking (see `may_manage`).
  NotBookingManager
  /// The booking is soft-cancelled: it cannot be edited or cancelled again
  /// (issue #43) — only restored or hard-deleted.
  BookingAlreadyCancelled
  /// Restore was asked of a booking that is not cancelled.
  BookingNotCancelled
  /// The user has a cancelled booking on the activity, which blocks booking
  /// it again until staff restores or removes it (issue #43).
  CancelledBookingExists
  CapacityExceeded(max: Int, spots_booked: Int)
  BookingQueryFailed(pog.QueryError)
}

/// A 409 with a machine-readable error message, the shape every booking
/// conflict answer shares.
fn conflict_response(message: String) -> Response {
  wisp.json_response(
    json.object([#("error", json.string(message))]) |> json.to_string,
    409,
  )
}

/// Whether `user` may edit or delete `booking`. Any holder of
/// `bookings:others:create` (which `Admin` implies, via `has_role`) manages
/// every booking; everyone else only their own. `booked_for_other` no longer
/// affects authorization — it is purely informational.
/// Public so tests can exercise the rule directly; production code only
/// reaches it through the update/delete handlers.
pub fn may_manage(user: web.User, booking: Booking) -> Bool {
  booking.user_id == user.id || web.has_role(user, web.BookingsOthersCreate)
}

/// `may_manage` as a transaction step: rolls back with `NotBookingManager`
/// (mapped to a 403) when the caller may not manage the booking.
fn ensure_may_manage(
  user: web.User,
  booking: Booking,
) -> Result(Nil, BookingError) {
  case may_manage(user, booking) {
    True -> Ok(Nil)
    False -> Error(NotBookingManager)
  }
}

pub fn create(
  req: Request,
  activity_id_str: String,
  ctx: web.Context,
) -> Response {
  use <- wisp.require_method(req, Post)
  use user <- web.with_authenticated_user(ctx)
  use activity_id <- given.ok(uuid.from_string(activity_id_str), fn(_) {
    wisp.bad_request("Invalid activity ID format")
  })
  use json_body <- wisp.require_json(req)
  use input <- given.ok(decode.run(json_body, booking_input_decoder()), fn(_) {
    wisp.bad_request("Invalid JSON payload")
  })
  // The required role follows the mode: a request naming a booker group books
  // on behalf of that kår, anything else books for the caller's own group.
  let required_role = case input.booker_group_id {
    option.Some(_) -> web.BookingsOthersCreate
    option.None -> web.BookingsSelfCreate
  }
  use <- web.require_role(user, required_role)
  use <- given.that(input.participant_count >= 1, else_return: fn() {
    wisp.bad_request("participant_count must be at least 1")
  })
  let id = uuid.v7()
  let user_id = user.id
  let now = timestamp.system_time()

  // Lock the activity row, verify the booking window and capacity, and insert
  // in one transaction so concurrent bookings for the same activity serialise
  // and can't overbook.
  let transaction_result =
    pog.transaction(ctx.db_connection, fn(conn) {
      use activity <- result.try(lock_activity(conn, activity_id))
      // A called-off activity accepts no new bookings. Checked inside the same
      // transaction that locks the activity so it can't race a concurrent
      // call-off.
      use _ <- result.try(ensure_not_called_off(conn, activity_id))
      use _ <- result.try(ensure_bookable(now, activity, ctx.booking_opens_at))
      use _ <- result.try(ensure_no_cancelled_booking(
        conn,
        user_id,
        activity_id,
      ))
      use spots_booked <- result.try(booked_spots(conn, activity_id))
      case
        web.exceeds_capacity(
          activity.max_attendees,
          spots_booked,
          input.participant_count,
        )
      {
        True ->
          Error(CapacityExceeded(
            option.unwrap(activity.max_attendees, 0),
            spots_booked,
          ))
        False -> insert_booking(conn, id, user_id, user, activity_id, input)
      }
    })

  case transaction_result {
    Ok(created_booking) -> {
      // Auto-favourite on booking. Idempotent via ON CONFLICT DO NOTHING. Kept
      // outside the transaction so a favourite failure can't undo the booking.
      case
        sql.create_favourite(ctx.db_connection, uuid.v7(), user_id, activity_id)
      {
        Error(error) ->
          wisp.log_error(
            "Auto-favourite failed after booking: " <> string.inspect(error),
          )
        Ok(_) -> Nil
      }
      let location =
        web.base_path <> "/api/bookings/" <> uuid.to_string(created_booking.id)
      wisp.json_response(
        booking.to_json(created_booking) |> json.to_string,
        201,
      )
      |> wisp.set_header("location", location)
    }
    Error(pog.TransactionRolledBack(ActivityNotFound)) -> wisp.not_found()
    Error(pog.TransactionRolledBack(ActivityCalledOff)) ->
      wisp.json_response(
        json.object([#("error", json.string("Activity is called off"))])
          |> json.to_string,
        409,
      )
    Error(pog.TransactionRolledBack(BookingNotYetOpen(opens_at))) ->
      wisp.json_response(
        json.object([
          #("error", json.string("Booking is not open yet")),
          #(
            "booking_opens_at",
            json.int(timestamp.to_unix_seconds(opens_at) |> float.round),
          ),
        ])
          |> json.to_string,
        409,
      )
    Error(pog.TransactionRolledBack(ActivityHasPassed)) ->
      wisp.json_response(
        json.object([#("error", json.string("Activity has passed"))])
          |> json.to_string,
        409,
      )
    Error(pog.TransactionRolledBack(CancelledBookingExists)) ->
      conflict_response("Cancelled booking exists")
    Error(pog.TransactionRolledBack(CapacityExceeded(max, spots_booked))) ->
      web.capacity_exceeded(max, spots_booked)
    Error(pog.TransactionRolledBack(BookingQueryFailed(error))) ->
      web.query_error(error)
    Error(error) -> {
      wisp.log_error("TransactionError " <> string.inspect(error))
      wisp.internal_server_error()
    }
  }
}

/// Rolls back the create transaction with `CancelledBookingExists` when the
/// calling user has a cancelled booking on the activity — a cancelled booking
/// blocks re-booking until staff restores or hard-deletes it (issue #43).
fn ensure_no_cancelled_booking(
  conn: pog.Connection,
  user_id: uuid.Uuid,
  activity_id: uuid.Uuid,
) -> Result(Nil, BookingError) {
  case
    sql.get_cancelled_booking_by_user_and_activity(conn, user_id, activity_id)
  {
    Error(error) -> Error(BookingQueryFailed(error))
    Ok(pog.Returned(_, [])) -> Ok(Nil)
    Ok(pog.Returned(_, [_, ..])) -> Error(CancelledBookingExists)
  }
}

/// The booking-window check (issues #35 and #36) as a transaction step: rolls
/// back with `BookingNotYetOpen` before the activity's effective opens-at
/// (its own override, else the global `BOOKING_OPENS_AT` default) and with
/// `ActivityHasPassed` once the activity is over. The window itself is
/// defined by the shared `model.booking_window`, which the client mirrors.
fn ensure_bookable(
  now: timestamp.Timestamp,
  activity: sql.LockActivityForBookingRow,
  default_booking_opens_at: option.Option(timestamp.Timestamp),
) -> Result(Nil, BookingError) {
  let opens_at = option.or(activity.booking_opens_at, default_booking_opens_at)
  case
    model.booking_window(
      now:,
      opens_at:,
      start_time: activity.start_time,
      end_time: option.Some(activity.end_time),
    )
  {
    model.BookingOpen -> Ok(Nil)
    model.BookingNotYetOpen(opens_at) -> Error(BookingNotYetOpen(opens_at))
    model.BookingClosed -> Error(ActivityHasPassed)
  }
}

/// Rolls back the booking transaction with `ActivityCalledOff` when a call-off
/// row exists for the activity, so a called-off activity accepts no new
/// bookings.
fn ensure_not_called_off(
  conn: pog.Connection,
  activity_id: uuid.Uuid,
) -> Result(Nil, BookingError) {
  case sql.get_call_off_by_activity(conn, activity_id) {
    Error(error) -> Error(BookingQueryFailed(error))
    Ok(pog.Returned(_, [])) -> Ok(Nil)
    Ok(pog.Returned(_, [_, ..])) -> Error(ActivityCalledOff)
  }
}

/// Locks the activity row for the transaction and returns what the booking
/// flow validates against (capacity + booking window times). Missing activity
/// rolls back the transaction as `ActivityNotFound`.
fn lock_activity(
  conn: pog.Connection,
  activity_id: uuid.Uuid,
) -> Result(sql.LockActivityForBookingRow, BookingError) {
  case sql.lock_activity_for_booking(conn, activity_id) {
    Error(error) -> Error(BookingQueryFailed(error))
    Ok(pog.Returned(_, [])) -> Error(ActivityNotFound)
    Ok(pog.Returned(_, [row, ..])) -> Ok(row)
  }
}

/// Current summed `participant_count` for an activity. The aggregate always
/// returns one row, so an empty result is treated as a query failure.
fn booked_spots(
  conn: pog.Connection,
  activity_id: uuid.Uuid,
) -> Result(Int, BookingError) {
  case sql.get_activity_spots(conn, activity_id) {
    Error(error) -> Error(BookingQueryFailed(error))
    Ok(pog.Returned(_, [row, ..])) -> Ok(row.spots_booked)
    Ok(pog.Returned(_, [])) ->
      Error(BookingQueryFailed(pog.UnexpectedResultType([])))
  }
}

/// Inserts the booking. A book-for-other request (`input.booker_group_id` is
/// `Some`) stores the requested kår and flags the row; a self-booking stores
/// the user's token group as before. Assumes capacity and the mode's role have
/// already been checked.
fn insert_booking(
  conn: pog.Connection,
  id: uuid.Uuid,
  user_id: uuid.Uuid,
  user: web.User,
  activity_id: uuid.Uuid,
  input: BookingInput,
) -> Result(Booking, BookingError) {
  // Book-for-other takes the kår from the request; a self-booking takes it
  // from the token. A token without one still creates a booking — the group
  // columns are simply left NULL.
  let #(group_id, booked_for_other) = case input.booker_group_id {
    option.Some(group_id) -> #(option.Some(group_id), True)
    option.None -> #(user.group_id, False)
  }
  let inserted = case group_id {
    option.Some(group_id) ->
      sql.create_booking_with_group(
        conn,
        id,
        user_id,
        activity_id,
        user.name,
        group_id,
        scout_group.group_id_to_name(group_id),
        input.group_free_text,
        input.responsible_name,
        input.phone_number,
        input.participant_count,
        booked_for_other,
      )
      |> result.map(fn(returned) {
        list.map(returned.rows, booking.from_create_booking_with_group_row)
      })
    option.None ->
      sql.create_booking_without_group(
        conn,
        id,
        user_id,
        activity_id,
        user.name,
        input.group_free_text,
        input.responsible_name,
        input.phone_number,
        input.participant_count,
      )
      |> result.map(fn(returned) {
        list.map(returned.rows, booking.from_create_booking_without_group_row)
      })
  }
  case inserted {
    Error(error) -> Error(BookingQueryFailed(error))
    Ok([created_booking, ..]) -> Ok(created_booking)
    Ok([]) -> Error(BookingQueryFailed(pog.UnexpectedResultType([])))
  }
}

pub fn get_one(req: Request, id: String, ctx: web.Context) -> Response {
  use <- wisp.require_method(req, Get)
  use user <- web.with_authenticated_user(ctx)
  // bookings:others:create holders read bookings too: the manage variant of
  // the per-activity bookings page needs the full list.
  use <- web.require_any_role(user, [
    web.BookingsRead,
    web.ActivitiesManage,
    web.BookingsOthersCreate,
  ])
  use booking_id <- given.ok(uuid.from_string(id), fn(_) {
    wisp.bad_request("Invalid booking ID format")
  })
  case sql.get_booking(ctx.db_connection, booking_id) {
    Error(error) -> web.query_error(error)
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

pub fn get_by_activity(
  req: Request,
  activity_id_str: String,
  ctx: web.Context,
) -> Response {
  use <- wisp.require_method(req, Get)
  use user <- web.with_authenticated_user(ctx)
  // Same read access as `get_one` (see the note there).
  use <- web.require_any_role(user, [
    web.BookingsRead,
    web.ActivitiesManage,
    web.BookingsOthersCreate,
  ])
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
    Error(error) -> web.query_error(error)
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

/// Badbuss overview: every beach-bus slot with its per-kår booking breakdown.
pub fn get_beach_bus_overview(req: Request, ctx: web.Context) -> Response {
  recurring_overview(req, ctx, "beach-bus")
}

/// Klättervägg overview: every climbing-wall slot with its per-kår breakdown.
pub fn get_climbing_wall_overview(req: Request, ctx: web.Context) -> Response {
  recurring_overview(req, ctx, "climbing-wall")
}

/// Shared handler for the recurring-activity booking overviews. Returns
/// `{"slots": [...]}` for a single event day (`?day=`, defaulting to today) with
/// each slot's participant total and per-kår breakdown. Called-off slots are
/// excluded, so the response is identical for every authorized user
/// (`SharedAcrossUsers`) and revalidates via ETag like the activity lists.
fn recurring_overview(
  req: Request,
  ctx: web.Context,
  kind: String,
) -> Response {
  use <- wisp.require_method(req, Get)
  use user <- web.with_authenticated_user(ctx)
  use <- web.require_any_role(user, [web.BookingsRead, web.ActivitiesManage])
  use day <- web.with_day(req)
  let #(day_start, day_end) = web.day_bounds(day)
  case
    sql.list_recurring_bookings_overview(
      ctx.db_connection,
      kind,
      day_start,
      day_end,
    )
  {
    Error(error) -> web.query_error(error)
    Ok(pog.Returned(_, rows)) -> {
      let body =
        booking.from_recurring_overview_rows(rows)
        |> model.booking_slots_to_json
        |> json.to_string
      web.json_response_with_etag(
        req,
        body,
        200,
        "private, no-cache",
        web.SharedAcrossUsers,
      )
    }
  }
}

pub fn update(req: Request, id: String, ctx: web.Context) -> Response {
  use <- wisp.require_method(req, Put)
  use user <- web.with_authenticated_user(ctx)
  use booking_id <- given.ok(uuid.from_string(id), fn(_) {
    wisp.bad_request("Invalid booking ID format")
  })
  use json_body <- wisp.require_json(req)
  use input <- given.ok(decode.run(json_body, booking_input_decoder()), fn(_) {
    wisp.bad_request("Invalid JSON payload")
  })
  use <- given.that(input.participant_count >= 1, else_return: fn() {
    wisp.bad_request("participant_count must be at least 1")
  })

  // Same locking transaction as create: an edit that raises participant_count
  // must not push the activity past its cap. The booking's own current count is
  // excluded from the "already booked" figure it's checked against.
  let transaction_result =
    pog.transaction(ctx.db_connection, fn(conn) {
      use existing <- result.try(load_booking(conn, booking_id))
      use _ <- result.try(ensure_may_manage(user, existing))
      use _ <- result.try(ensure_not_cancelled(existing))
      use activity <- result.try(lock_activity(conn, existing.activity_id))
      use spots_booked <- result.try(booked_spots(conn, existing.activity_id))
      let already_booked = spots_booked - existing.participant_count
      case
        web.exceeds_capacity(
          activity.max_attendees,
          already_booked,
          input.participant_count,
        )
      {
        True ->
          Error(CapacityExceeded(
            option.unwrap(activity.max_attendees, 0),
            spots_booked,
          ))
        False -> update_booking(conn, booking_id, input)
      }
    })

  case transaction_result {
    Ok(updated) ->
      wisp.json_response(updated |> booking.to_json |> json.to_string, 200)
    Error(pog.TransactionRolledBack(BookingNotFound)) -> wisp.not_found()
    Error(pog.TransactionRolledBack(ActivityNotFound)) -> wisp.not_found()
    Error(pog.TransactionRolledBack(NotBookingManager)) -> wisp.response(403)
    Error(pog.TransactionRolledBack(BookingAlreadyCancelled)) ->
      conflict_response("Booking is cancelled")
    Error(pog.TransactionRolledBack(CapacityExceeded(max, spots_booked))) ->
      web.capacity_exceeded(max, spots_booked)
    Error(pog.TransactionRolledBack(BookingQueryFailed(error))) ->
      web.query_error(error)
    Error(error) -> {
      wisp.log_error("TransactionError " <> string.inspect(error))
      wisp.internal_server_error()
    }
  }
}

/// A cancelled booking may not be edited or cancelled again — only restored
/// or hard-deleted (issue #43).
fn ensure_not_cancelled(booking: Booking) -> Result(Nil, BookingError) {
  case booking.cancellation {
    option.None -> Ok(Nil)
    option.Some(_) -> Error(BookingAlreadyCancelled)
  }
}

/// Soft-cancel a booking with a reason (issue #43): POST
/// /api/bookings/:id/cancel with `{"reason": "..."}`. Requires
/// `bookings:others:create` (which `admin` implies) — deliberately stricter
/// than `may_manage`; owners without the role hard-delete instead. The
/// cancelled booking keeps its row (both sides see the reason), stops
/// occupying spots, and blocks the booker from re-booking the activity.
pub fn cancel(req: Request, id: String, ctx: web.Context) -> Response {
  use <- wisp.require_method(req, Post)
  use user <- web.with_authenticated_user(ctx)
  use <- web.require_role(user, web.BookingsOthersCreate)
  use booking_id <- given.ok(uuid.from_string(id), fn(_) {
    wisp.bad_request("Invalid booking ID format")
  })
  use json_body <- wisp.require_json(req)
  use reason <- given.ok(
    decode.run(json_body, {
      use reason <- decode.field("reason", decode.string)
      decode.success(reason)
    }),
    fn(_) { wisp.bad_request("Invalid JSON payload") },
  )
  let reason = string.trim(reason)
  use <- given.that(reason != "", else_return: fn() {
    wisp.bad_request("reason must not be empty")
  })

  // Load first so the not-cancelled invariant can answer a clean 409; the
  // races that remain (concurrent cancel/delete) resolve harmlessly.
  case sql.get_booking(ctx.db_connection, booking_id) {
    Error(error) -> web.query_error(error)
    Ok(pog.Returned(_, [])) -> wisp.not_found()
    Ok(pog.Returned(_, [row, ..])) ->
      case ensure_not_cancelled(booking.from_get_booking_row(row)) {
        Error(_) -> conflict_response("Booking is already cancelled")
        Ok(Nil) ->
          case sql.cancel_booking(ctx.db_connection, booking_id, reason) {
            Error(error) -> web.query_error(error)
            Ok(pog.Returned(_, [])) -> wisp.not_found()
            Ok(pog.Returned(_, [row, ..])) ->
              wisp.json_response(
                row
                  |> booking.from_cancel_booking_row
                  |> booking.to_json
                  |> json.to_string,
                200,
              )
          }
      }
  }
}

/// Restore a cancelled booking to active (issue #43): POST
/// /api/bookings/:id/restore. Requires `bookings:others:create`. Runs the
/// same locking transaction shape as create — a restored booking occupies
/// spots again, so capacity and the call-off state are re-checked. The
/// booking-window opens-at is deliberately not re-checked: the booking
/// predates it.
pub fn restore(req: Request, id: String, ctx: web.Context) -> Response {
  use <- wisp.require_method(req, Post)
  web.discard_body(req)
  use user <- web.with_authenticated_user(ctx)
  use <- web.require_role(user, web.BookingsOthersCreate)
  use booking_id <- given.ok(uuid.from_string(id), fn(_) {
    wisp.bad_request("Invalid booking ID format")
  })

  let transaction_result =
    pog.transaction(ctx.db_connection, fn(conn) {
      use existing <- result.try(load_booking(conn, booking_id))
      use _ <- result.try(case existing.cancellation {
        option.Some(_) -> Ok(Nil)
        option.None -> Error(BookingNotCancelled)
      })
      use activity <- result.try(lock_activity(conn, existing.activity_id))
      use _ <- result.try(ensure_not_called_off(conn, existing.activity_id))
      use spots_booked <- result.try(booked_spots(conn, existing.activity_id))
      case
        web.exceeds_capacity(
          activity.max_attendees,
          spots_booked,
          existing.participant_count,
        )
      {
        True ->
          Error(CapacityExceeded(
            option.unwrap(activity.max_attendees, 0),
            spots_booked,
          ))
        False ->
          case sql.restore_booking(conn, booking_id) {
            Error(error) -> Error(BookingQueryFailed(error))
            Ok(pog.Returned(_, [])) -> Error(BookingNotFound)
            Ok(pog.Returned(_, [row, ..])) ->
              Ok(booking.from_restore_booking_row(row))
          }
      }
    })

  case transaction_result {
    Ok(restored) ->
      wisp.json_response(restored |> booking.to_json |> json.to_string, 200)
    Error(pog.TransactionRolledBack(BookingNotFound)) -> wisp.not_found()
    Error(pog.TransactionRolledBack(ActivityNotFound)) -> wisp.not_found()
    Error(pog.TransactionRolledBack(BookingNotCancelled)) ->
      conflict_response("Booking is not cancelled")
    Error(pog.TransactionRolledBack(ActivityCalledOff)) ->
      conflict_response("Activity is called off")
    Error(pog.TransactionRolledBack(CapacityExceeded(max, spots_booked))) ->
      web.capacity_exceeded(max, spots_booked)
    Error(pog.TransactionRolledBack(BookingQueryFailed(error))) ->
      web.query_error(error)
    Error(error) -> {
      wisp.log_error("TransactionError " <> string.inspect(error))
      wisp.internal_server_error()
    }
  }
}

/// Loads the booking being edited (for its activity + current count). Missing
/// booking rolls back the transaction as `BookingNotFound`.
fn load_booking(
  conn: pog.Connection,
  booking_id: uuid.Uuid,
) -> Result(Booking, BookingError) {
  case sql.get_booking(conn, booking_id) {
    Error(error) -> Error(BookingQueryFailed(error))
    Ok(pog.Returned(_, [])) -> Error(BookingNotFound)
    Ok(pog.Returned(_, [row, ..])) -> Ok(booking.from_get_booking_row(row))
  }
}

/// Applies the edit. Assumes capacity has already been checked.
fn update_booking(
  conn: pog.Connection,
  booking_id: uuid.Uuid,
  input: BookingInput,
) -> Result(Booking, BookingError) {
  case
    sql.update_booking(
      conn,
      booking_id,
      input.group_free_text,
      input.responsible_name,
      input.phone_number,
      input.participant_count,
    )
  {
    Error(error) -> Error(BookingQueryFailed(error))
    Ok(pog.Returned(_, [])) -> Error(BookingNotFound)
    Ok(pog.Returned(_, [row, ..])) -> Ok(booking.from_update_booking_row(row))
  }
}

pub fn delete(req: Request, id: String, ctx: web.Context) -> Response {
  use <- wisp.require_method(req, Delete)
  web.discard_body(req)
  use user <- web.with_authenticated_user(ctx)
  use booking_id <- given.ok(uuid.from_string(id), fn(_) {
    wisp.bad_request("Invalid booking ID format")
  })

  // Load first so a booking the caller may not manage answers 403 (they can
  // read it) rather than a misleading 404.
  case sql.get_booking(ctx.db_connection, booking_id) {
    Error(error) -> web.query_error(error)
    Ok(pog.Returned(_, [])) -> wisp.not_found()
    Ok(pog.Returned(_, [row, ..])) -> {
      let existing = booking.from_get_booking_row(row)
      use <- given.that(may_manage(user, existing), else_return: fn() {
        wisp.response(403)
      })
      case sql.delete_booking(ctx.db_connection, booking_id) {
        Error(error) -> web.query_error(error)
        Ok(pog.Returned(_, [])) -> wisp.not_found()
        Ok(pog.Returned(_, [_, ..])) -> wisp.no_content()
      }
    }
  }
}

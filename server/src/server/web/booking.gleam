import given
import gleam/dynamic/decode
import gleam/http.{Delete, Get, Post, Put}
import gleam/int
import gleam/json
import gleam/list
import gleam/option
import gleam/result
import gleam/string
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

/// Rollback reasons for the booking create/update transactions, so the handler
/// can map each to the right HTTP status.
type BookingError {
  ActivityNotFound
  ActivityCalledOff
  BookingNotFound
  CapacityExceeded(max: Int, spots_booked: Int)
  BookingQueryFailed(pog.QueryError)
}

pub fn create(
  req: Request,
  activity_id_str: String,
  ctx: web.Context,
) -> Response {
  use <- wisp.require_method(req, Post)
  use user <- web.with_authenticated_user(ctx)
  // TODO(bookings-others): holders of bookings:others:create should be able
  // to pick a booker group (likely from a hardcoded list) instead of booking
  // for their own token group.
  use <- web.require_role(user, web.BookingsSelfCreate)
  use activity_id <- given.ok(uuid.from_string(activity_id_str), fn(_) {
    wisp.bad_request("Invalid activity ID format")
  })
  use json_body <- wisp.require_json(req)
  use input <- given.ok(decode.run(json_body, booking_input_decoder()), fn(_) {
    wisp.bad_request("Invalid JSON payload")
  })
  use <- given.that(input.participant_count >= 1, else_return: fn() {
    wisp.bad_request("participant_count must be at least 1")
  })
  let id = uuid.v7()
  let user_id = user.id

  // Lock the activity row, verify capacity, and insert in one transaction so
  // concurrent bookings for the same activity serialise and can't overbook.
  let transaction_result =
    pog.transaction(ctx.db_connection, fn(conn) {
      use max_attendees <- result.try(lock_activity(conn, activity_id))
      // A called-off activity accepts no new bookings. Checked inside the same
      // transaction that locks the activity so it can't race a concurrent
      // call-off.
      use _ <- result.try(ensure_not_called_off(conn, activity_id))
      use spots_booked <- result.try(booked_spots(conn, activity_id))
      case
        web.exceeds_capacity(
          max_attendees,
          spots_booked,
          input.participant_count,
        )
      {
        True ->
          Error(CapacityExceeded(option.unwrap(max_attendees, 0), spots_booked))
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

/// Locks the activity row for the transaction and returns its cap. Missing
/// activity rolls back the transaction as `ActivityNotFound`.
fn lock_activity(
  conn: pog.Connection,
  activity_id: uuid.Uuid,
) -> Result(option.Option(Int), BookingError) {
  case sql.lock_activity_max_attendees(conn, activity_id) {
    Error(error) -> Error(BookingQueryFailed(error))
    Ok(pog.Returned(_, [])) -> Error(ActivityNotFound)
    Ok(pog.Returned(_, [row, ..])) -> Ok(row.max_attendees)
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

/// Inserts the booking, choosing the with/without-group variant from the
/// user's token group. Assumes capacity has already been checked.
fn insert_booking(
  conn: pog.Connection,
  id: uuid.Uuid,
  user_id: uuid.Uuid,
  user: web.User,
  activity_id: uuid.Uuid,
  input: BookingInput,
) -> Result(Booking, BookingError) {
  // The booker group comes from the token. A token without one still creates a
  // booking — the group columns are simply left NULL.
  let inserted = case user.group_id {
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
  use <- web.require_any_role(user, [web.BookingsRead, web.ActivitiesManage])
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
  use <- web.require_any_role(user, [web.BookingsRead, web.ActivitiesManage])
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
/// `{"slots": [...]}` covering every slot of `kind` (all days; the client
/// filters by day) with each slot's participant total and per-kår breakdown.
fn recurring_overview(
  req: Request,
  ctx: web.Context,
  kind: String,
) -> Response {
  use <- wisp.require_method(req, Get)
  use user <- web.with_authenticated_user(ctx)
  use <- web.require_any_role(user, [web.BookingsRead, web.ActivitiesManage])
  case sql.list_recurring_bookings_overview(ctx.db_connection, kind) {
    Error(error) -> web.query_error(error)
    Ok(pog.Returned(_, rows)) -> {
      let slots = booking.from_recurring_overview_rows(rows)
      wisp.json_response(
        model.booking_slots_to_json(slots) |> json.to_string,
        200,
      )
    }
  }
}

pub fn update(req: Request, id: String, ctx: web.Context) -> Response {
  use <- wisp.require_method(req, Put)
  // TODO(booking-ownership): only authentication is required for now — the
  // own-booking vs others-booking role semantics are not decided yet.
  use _user <- web.with_authenticated_user(ctx)
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
      use max_attendees <- result.try(lock_activity(conn, existing.activity_id))
      use spots_booked <- result.try(booked_spots(conn, existing.activity_id))
      let already_booked = spots_booked - existing.participant_count
      case
        web.exceeds_capacity(
          max_attendees,
          already_booked,
          input.participant_count,
        )
      {
        True ->
          Error(CapacityExceeded(option.unwrap(max_attendees, 0), spots_booked))
        False -> update_booking(conn, booking_id, input)
      }
    })

  case transaction_result {
    Ok(updated) ->
      wisp.json_response(updated |> booking.to_json |> json.to_string, 200)
    Error(pog.TransactionRolledBack(BookingNotFound)) -> wisp.not_found()
    Error(pog.TransactionRolledBack(ActivityNotFound)) -> wisp.not_found()
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
  // TODO(booking-ownership): only authentication is required for now — the
  // own-booking vs others-booking role semantics are not decided yet.
  use _user <- web.with_authenticated_user(ctx)
  use booking_id <- given.ok(uuid.from_string(id), fn(_) {
    wisp.bad_request("Invalid booking ID format")
  })

  case sql.delete_booking(ctx.db_connection, booking_id) {
    Error(error) -> web.query_error(error)
    Ok(pog.Returned(_, [])) -> wisp.not_found()
    Ok(pog.Returned(_, [_, ..])) -> wisp.no_content()
  }
}

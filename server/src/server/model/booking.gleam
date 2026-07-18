import gleam/json.{type Json}
import gleam/list
import gleam/option.{None}
import server/sql
import shared/model.{
  type Booking, type BookingSlot, Booking, BookingSlot, GroupCount,
}
import youid/uuid

pub fn from_create_booking_with_group_row(
  row: sql.CreateBookingWithGroupRow,
) -> Booking {
  Booking(
    id: row.id,
    user_id: row.user_id,
    activity_id: row.activity_id,
    booker_name: row.booker_name,
    booker_group_id: row.booker_group_id,
    booker_group_name: row.booker_group_name,
    group_free_text: row.group_free_text,
    responsible_name: row.responsible_name,
    phone_number: row.phone_number,
    participant_count: row.participant_count,
    booked_for_other: row.booked_for_other,
  )
}

pub fn from_create_booking_without_group_row(
  row: sql.CreateBookingWithoutGroupRow,
) -> Booking {
  Booking(
    id: row.id,
    user_id: row.user_id,
    activity_id: row.activity_id,
    booker_name: row.booker_name,
    booker_group_id: None,
    booker_group_name: None,
    group_free_text: row.group_free_text,
    responsible_name: row.responsible_name,
    phone_number: row.phone_number,
    participant_count: row.participant_count,
    // The without-group insert is only ever a self-booking (a token with no
    // kår); the column keeps its FALSE default.
    booked_for_other: False,
  )
}

pub fn from_get_booking_row(row: sql.GetBookingRow) -> Booking {
  Booking(
    id: row.id,
    user_id: row.user_id,
    activity_id: row.activity_id,
    booker_name: row.booker_name,
    booker_group_id: row.booker_group_id,
    booker_group_name: row.booker_group_name,
    group_free_text: row.group_free_text,
    responsible_name: row.responsible_name,
    phone_number: row.phone_number,
    participant_count: row.participant_count,
    booked_for_other: row.booked_for_other,
  )
}

pub fn from_get_bookings_by_activity_row(
  row: sql.GetBookingsByActivityRow,
) -> Booking {
  Booking(
    id: row.id,
    user_id: row.user_id,
    activity_id: row.activity_id,
    booker_name: row.booker_name,
    booker_group_id: row.booker_group_id,
    booker_group_name: row.booker_group_name,
    group_free_text: row.group_free_text,
    responsible_name: row.responsible_name,
    phone_number: row.phone_number,
    participant_count: row.participant_count,
    booked_for_other: row.booked_for_other,
  )
}

pub fn from_get_bookings_by_user_row(row: sql.GetBookingsByUserRow) -> Booking {
  Booking(
    id: row.id,
    user_id: row.user_id,
    activity_id: row.activity_id,
    booker_name: row.booker_name,
    booker_group_id: row.booker_group_id,
    booker_group_name: row.booker_group_name,
    group_free_text: row.group_free_text,
    responsible_name: row.responsible_name,
    phone_number: row.phone_number,
    participant_count: row.participant_count,
    booked_for_other: row.booked_for_other,
  )
}

pub fn from_update_booking_row(row: sql.UpdateBookingRow) -> Booking {
  Booking(
    id: row.id,
    user_id: row.user_id,
    activity_id: row.activity_id,
    booker_name: row.booker_name,
    booker_group_id: row.booker_group_id,
    booker_group_name: row.booker_group_name,
    group_free_text: row.group_free_text,
    responsible_name: row.responsible_name,
    phone_number: row.phone_number,
    participant_count: row.participant_count,
    booked_for_other: row.booked_for_other,
  )
}

/// Group the flat overview rows (one per activity × booker group, ordered so a
/// slot's rows are contiguous) into one `BookingSlot` per activity. Rows with
/// `booking_count == 0` are the LEFT JOIN placeholders for slots that have no
/// bookings — they contribute the slot itself but no group entry.
pub fn from_recurring_overview_rows(
  rows: List(sql.ListRecurringBookingsOverviewRow),
) -> List(BookingSlot) {
  rows
  |> list.chunk(by: fn(row) { row.activity_id })
  |> list.map(overview_chunk_to_slot)
}

fn overview_chunk_to_slot(
  rows: List(sql.ListRecurringBookingsOverviewRow),
) -> BookingSlot {
  // `list.chunk` never yields an empty chunk, so the head is always present and
  // carries this slot's activity fields (shared across its rows).
  let assert [first, ..] = rows
  let groups =
    rows
    |> list.filter(fn(row) { row.booking_count > 0 })
    |> list.map(fn(row) {
      GroupCount(
        group_id: row.booker_group_id,
        group_name: row.booker_group_name,
        count: row.group_count,
      )
    })
  let total_booked = list.fold(groups, 0, fn(sum, group) { sum + group.count })
  BookingSlot(
    activity_id: first.activity_id,
    start_time: first.start_time,
    end_time: first.end_time,
    max_attendees: first.max_attendees,
    total_booked:,
    groups:,
  )
}

pub fn to_json(booking: Booking) -> Json {
  let Booking(
    id:,
    user_id:,
    activity_id:,
    booker_name:,
    booker_group_id:,
    booker_group_name:,
    group_free_text:,
    responsible_name:,
    phone_number:,
    participant_count:,
    booked_for_other:,
  ) = booking
  json.object([
    #("id", id |> uuid.to_string |> json.string),
    #("user_id", user_id |> uuid.to_string |> json.string),
    #("activity_id", activity_id |> uuid.to_string |> json.string),
    #("booker_name", json.string(booker_name)),
    #("booker_group_id", json.nullable(booker_group_id, json.int)),
    #("booker_group_name", json.nullable(booker_group_name, json.string)),
    #("group_free_text", json.string(group_free_text)),
    #("responsible_name", json.string(responsible_name)),
    #("phone_number", json.string(phone_number)),
    #("participant_count", json.int(participant_count)),
    #("booked_for_other", json.bool(booked_for_other)),
  ])
}

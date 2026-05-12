import gleam/json.{type Json}
import server/sql
import shared/model.{type Booking, Booking}
import youid/uuid

pub fn from_create_booking_row(row: sql.CreateBookingRow) -> Booking {
  Booking(
    id: row.id,
    user_id: row.user_id,
    activity_id: row.activity_id,
    booker_group_id: row.booker_group_id,
    booker_group_name: row.booker_group_name,
    group_free_text: row.group_free_text,
    responsible_name: row.responsible_name,
    phone_number: row.phone_number,
    participant_count: row.participant_count,
  )
}

pub fn from_get_booking_row(row: sql.GetBookingRow) -> Booking {
  Booking(
    id: row.id,
    user_id: row.user_id,
    activity_id: row.activity_id,
    booker_group_id: row.booker_group_id,
    booker_group_name: row.booker_group_name,
    group_free_text: row.group_free_text,
    responsible_name: row.responsible_name,
    phone_number: row.phone_number,
    participant_count: row.participant_count,
  )
}

pub fn from_get_bookings_by_activity_row(
  row: sql.GetBookingsByActivityRow,
) -> Booking {
  Booking(
    id: row.id,
    user_id: row.user_id,
    activity_id: row.activity_id,
    booker_group_id: row.booker_group_id,
    booker_group_name: row.booker_group_name,
    group_free_text: row.group_free_text,
    responsible_name: row.responsible_name,
    phone_number: row.phone_number,
    participant_count: row.participant_count,
  )
}

pub fn from_get_bookings_by_user_row(row: sql.GetBookingsByUserRow) -> Booking {
  Booking(
    id: row.id,
    user_id: row.user_id,
    activity_id: row.activity_id,
    booker_group_id: row.booker_group_id,
    booker_group_name: row.booker_group_name,
    group_free_text: row.group_free_text,
    responsible_name: row.responsible_name,
    phone_number: row.phone_number,
    participant_count: row.participant_count,
  )
}

pub fn from_update_booking_row(row: sql.UpdateBookingRow) -> Booking {
  Booking(
    id: row.id,
    user_id: row.user_id,
    activity_id: row.activity_id,
    booker_group_id: row.booker_group_id,
    booker_group_name: row.booker_group_name,
    group_free_text: row.group_free_text,
    responsible_name: row.responsible_name,
    phone_number: row.phone_number,
    participant_count: row.participant_count,
  )
}

pub fn to_json(booking: Booking) -> Json {
  let Booking(
    id:,
    user_id:,
    activity_id:,
    booker_group_id:,
    booker_group_name:,
    group_free_text:,
    responsible_name:,
    phone_number:,
    participant_count:,
  ) = booking
  json.object([
    #("id", id |> uuid.to_string |> json.string),
    #("user_id", user_id |> uuid.to_string |> json.string),
    #("activity_id", activity_id |> uuid.to_string |> json.string),
    #("booker_group_id", json.int(booker_group_id)),
    #("booker_group_name", json.string(booker_group_name)),
    #("group_free_text", json.string(group_free_text)),
    #("responsible_name", json.string(responsible_name)),
    #("phone_number", json.string(phone_number)),
    #("participant_count", json.int(participant_count)),
  ])
}

//// This module contains the code to run the sql queries defined in
//// `./src/server/sql`.
//// > 🐿️ This module was generated automatically using v4.7.0 of
//// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
////

import gleam/dynamic/decode
import gleam/json.{type Json}
import gleam/option.{type Option}
import gleam/time/timestamp.{type Timestamp}
import pog
import youid/uuid.{type Uuid}

/// A row you get from running the `cancel_booking` query
/// defined in `./src/server/sql/cancel_booking.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type CancelBookingRow {
  CancelBookingRow(
    id: Uuid,
    user_id: Uuid,
    activity_id: Uuid,
    booker_name: String,
    booker_group_id: Option(Int),
    booker_group_name: Option(String),
    group_free_text: String,
    responsible_name: String,
    phone_number: String,
    participant_count: Int,
    booked_for_other: Bool,
    cancellation_reason: Option(String),
  )
}

/// Soft-cancel a booking: store the reason a bookings:others:create holder
/// gave. A cancelled booking stops occupying spots (the capacity aggregates
/// exclude it) but stays visible in booking lists so both the booker and the
/// staff can see that it was removed and why.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn cancel_booking(
  db: pog.Connection,
  id: Uuid,
  cancellation_reason: String,
) -> Result(pog.Returned(CancelBookingRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use user_id <- decode.field(1, uuid_decoder())
    use activity_id <- decode.field(2, uuid_decoder())
    use booker_name <- decode.field(3, decode.string)
    use booker_group_id <- decode.field(4, decode.optional(decode.int))
    use booker_group_name <- decode.field(5, decode.optional(decode.string))
    use group_free_text <- decode.field(6, decode.string)
    use responsible_name <- decode.field(7, decode.string)
    use phone_number <- decode.field(8, decode.string)
    use participant_count <- decode.field(9, decode.int)
    use booked_for_other <- decode.field(10, decode.bool)
    use cancellation_reason <- decode.field(11, decode.optional(decode.string))
    decode.success(CancelBookingRow(
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
      cancellation_reason:,
    ))
  }

  "-- Soft-cancel a booking: store the reason a bookings:others:create holder
-- gave. A cancelled booking stops occupying spots (the capacity aggregates
-- exclude it) but stays visible in booking lists so both the booker and the
-- staff can see that it was removed and why.
UPDATE booking
SET cancellation_reason = $2
WHERE id = $1
RETURNING id,
    user_id,
    activity_id,
    booker_name,
    booker_group_id,
    booker_group_name,
    group_free_text,
    responsible_name,
    phone_number,
    participant_count,
    booked_for_other,
    cancellation_reason
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(id)))
  |> pog.parameter(pog.text(cancellation_reason))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// Clear an activity's booking-opens-at override so it falls back to the
/// global BOOKING_OPENS_AT default. Counterpart of
/// set_activity_booking_opens_at.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn clear_activity_booking_opens_at(
  db: pog.Connection,
  id: Uuid,
) -> Result(pog.Returned(Nil), pog.QueryError) {
  let decoder = decode.map(decode.dynamic, fn(_) { Nil })

  "-- Clear an activity's booking-opens-at override so it falls back to the
-- global BOOKING_OPENS_AT default. Counterpart of
-- set_activity_booking_opens_at.
UPDATE activity
SET booking_opens_at = NULL
WHERE id = $1
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(id)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// Runs the `clear_activity_location` query
/// defined in `./src/server/sql/clear_activity_location.sql`.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn clear_activity_location(
  db: pog.Connection,
  id: Uuid,
) -> Result(pog.Returned(Nil), pog.QueryError) {
  let decoder = decode.map(decode.dynamic, fn(_) { Nil })

  "UPDATE activity
SET location_id = NULL
WHERE id = $1
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(id)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `count_favourites_by_activity` query
/// defined in `./src/server/sql/count_favourites_by_activity.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type CountFavouritesByActivityRow {
  CountFavouritesByActivityRow(favourite_count: Int)
}

/// Runs the `count_favourites_by_activity` query
/// defined in `./src/server/sql/count_favourites_by_activity.sql`.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn count_favourites_by_activity(
  db: pog.Connection,
  activity_id: Uuid,
) -> Result(pog.Returned(CountFavouritesByActivityRow), pog.QueryError) {
  let decoder = {
    use favourite_count <- decode.field(0, decode.int)
    decode.success(CountFavouritesByActivityRow(favourite_count:))
  }

  "SELECT COUNT(*) AS favourite_count
FROM favourite
WHERE activity_id = $1
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(activity_id)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `create_activity_tag` query
/// defined in `./src/server/sql/create_activity_tag.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type CreateActivityTagRow {
  CreateActivityTagRow(id: Uuid, name: String, name_en: String)
}

/// Creates an activity tag and returns it.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn create_activity_tag(
  db: pog.Connection,
  arg_1: Uuid,
  arg_2: String,
  arg_3: String,
) -> Result(pog.Returned(CreateActivityTagRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use name <- decode.field(1, decode.string)
    use name_en <- decode.field(2, decode.string)
    decode.success(CreateActivityTagRow(id:, name:, name_en:))
  }

  "-- Creates an activity tag and returns it.
INSERT INTO activity_tag (id, name, name_en)
VALUES ($1, $2, $3)
RETURNING id,
    name,
    name_en;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.parameter(pog.text(arg_2))
  |> pog.parameter(pog.text(arg_3))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `create_activity_with_max_attendees` query
/// defined in `./src/server/sql/create_activity_with_max_attendees.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type CreateActivityWithMaxAttendeesRow {
  CreateActivityWithMaxAttendeesRow(
    id: Uuid,
    title: String,
    title_en: String,
    description: String,
    description_en: String,
    max_attendees: Option(Int),
    start_time: Timestamp,
    end_time: Timestamp,
    location_id: Option(Uuid),
    booking_opens_at: Option(Timestamp),
  )
}

/// Runs the `create_activity_with_max_attendees` query
/// defined in `./src/server/sql/create_activity_with_max_attendees.sql`.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn create_activity_with_max_attendees(
  db: pog.Connection,
  arg_1: Uuid,
  arg_2: String,
  arg_3: String,
  arg_4: String,
  arg_5: String,
  arg_6: Int,
  arg_7: Timestamp,
  arg_8: Timestamp,
) -> Result(pog.Returned(CreateActivityWithMaxAttendeesRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use title <- decode.field(1, decode.string)
    use title_en <- decode.field(2, decode.string)
    use description <- decode.field(3, decode.string)
    use description_en <- decode.field(4, decode.string)
    use max_attendees <- decode.field(5, decode.optional(decode.int))
    use start_time <- decode.field(6, pog.timestamp_decoder())
    use end_time <- decode.field(7, pog.timestamp_decoder())
    use location_id <- decode.field(8, decode.optional(uuid_decoder()))
    use booking_opens_at <- decode.field(
      9,
      decode.optional(pog.timestamp_decoder()),
    )
    decode.success(CreateActivityWithMaxAttendeesRow(
      id:,
      title:,
      title_en:,
      description:,
      description_en:,
      max_attendees:,
      start_time:,
      end_time:,
      location_id:,
      booking_opens_at:,
    ))
  }

  "INSERT INTO activity (
        id,
        title,
        title_en,
        description,
        description_en,
        max_attendees,
        start_time,
        end_time
    )
VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
RETURNING id,
    title,
    title_en,
    description,
    description_en,
    max_attendees,
    start_time,
    end_time,
    location_id,
    booking_opens_at"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.parameter(pog.text(arg_2))
  |> pog.parameter(pog.text(arg_3))
  |> pog.parameter(pog.text(arg_4))
  |> pog.parameter(pog.text(arg_5))
  |> pog.parameter(pog.int(arg_6))
  |> pog.parameter(pog.timestamp(arg_7))
  |> pog.parameter(pog.timestamp(arg_8))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `create_activity_without_max_attendees` query
/// defined in `./src/server/sql/create_activity_without_max_attendees.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type CreateActivityWithoutMaxAttendeesRow {
  CreateActivityWithoutMaxAttendeesRow(
    id: Uuid,
    title: String,
    title_en: String,
    description: String,
    description_en: String,
    start_time: Timestamp,
    end_time: Timestamp,
    location_id: Option(Uuid),
    booking_opens_at: Option(Timestamp),
  )
}

/// Runs the `create_activity_without_max_attendees` query
/// defined in `./src/server/sql/create_activity_without_max_attendees.sql`.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn create_activity_without_max_attendees(
  db: pog.Connection,
  arg_1: Uuid,
  arg_2: String,
  arg_3: String,
  arg_4: String,
  arg_5: String,
  arg_6: Timestamp,
  arg_7: Timestamp,
) -> Result(pog.Returned(CreateActivityWithoutMaxAttendeesRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use title <- decode.field(1, decode.string)
    use title_en <- decode.field(2, decode.string)
    use description <- decode.field(3, decode.string)
    use description_en <- decode.field(4, decode.string)
    use start_time <- decode.field(5, pog.timestamp_decoder())
    use end_time <- decode.field(6, pog.timestamp_decoder())
    use location_id <- decode.field(7, decode.optional(uuid_decoder()))
    use booking_opens_at <- decode.field(
      8,
      decode.optional(pog.timestamp_decoder()),
    )
    decode.success(CreateActivityWithoutMaxAttendeesRow(
      id:,
      title:,
      title_en:,
      description:,
      description_en:,
      start_time:,
      end_time:,
      location_id:,
      booking_opens_at:,
    ))
  }

  "INSERT INTO activity (
        id,
        title,
        title_en,
        description,
        description_en,
        max_attendees,
        start_time,
        end_time
    )
VALUES ($1, $2, $3, $4, $5, NULL, $6, $7)
RETURNING id,
    title,
    title_en,
    description,
    description_en,
    start_time,
    end_time,
    location_id,
    booking_opens_at"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.parameter(pog.text(arg_2))
  |> pog.parameter(pog.text(arg_3))
  |> pog.parameter(pog.text(arg_4))
  |> pog.parameter(pog.text(arg_5))
  |> pog.parameter(pog.timestamp(arg_6))
  |> pog.parameter(pog.timestamp(arg_7))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `create_booking_with_group` query
/// defined in `./src/server/sql/create_booking_with_group.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type CreateBookingWithGroupRow {
  CreateBookingWithGroupRow(
    id: Uuid,
    user_id: Uuid,
    activity_id: Uuid,
    booker_name: String,
    booker_group_id: Option(Int),
    booker_group_name: Option(String),
    group_free_text: String,
    responsible_name: String,
    phone_number: String,
    participant_count: Int,
    booked_for_other: Bool,
  )
}

/// Runs the `create_booking_with_group` query
/// defined in `./src/server/sql/create_booking_with_group.sql`.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn create_booking_with_group(
  db: pog.Connection,
  arg_1: Uuid,
  arg_2: Uuid,
  arg_3: Uuid,
  arg_4: String,
  arg_5: Int,
  arg_6: String,
  arg_7: String,
  arg_8: String,
  arg_9: String,
  arg_10: Int,
  arg_11: Bool,
) -> Result(pog.Returned(CreateBookingWithGroupRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use user_id <- decode.field(1, uuid_decoder())
    use activity_id <- decode.field(2, uuid_decoder())
    use booker_name <- decode.field(3, decode.string)
    use booker_group_id <- decode.field(4, decode.optional(decode.int))
    use booker_group_name <- decode.field(5, decode.optional(decode.string))
    use group_free_text <- decode.field(6, decode.string)
    use responsible_name <- decode.field(7, decode.string)
    use phone_number <- decode.field(8, decode.string)
    use participant_count <- decode.field(9, decode.int)
    use booked_for_other <- decode.field(10, decode.bool)
    decode.success(CreateBookingWithGroupRow(
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
    ))
  }

  "INSERT INTO booking (
        id,
        user_id,
        activity_id,
        booker_name,
        booker_group_id,
        booker_group_name,
        group_free_text,
        responsible_name,
        phone_number,
        participant_count,
        booked_for_other
    )
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
RETURNING id,
    user_id,
    activity_id,
    booker_name,
    booker_group_id,
    booker_group_name,
    group_free_text,
    responsible_name,
    phone_number,
    participant_count,
    booked_for_other
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.parameter(pog.text(uuid.to_string(arg_2)))
  |> pog.parameter(pog.text(uuid.to_string(arg_3)))
  |> pog.parameter(pog.text(arg_4))
  |> pog.parameter(pog.int(arg_5))
  |> pog.parameter(pog.text(arg_6))
  |> pog.parameter(pog.text(arg_7))
  |> pog.parameter(pog.text(arg_8))
  |> pog.parameter(pog.text(arg_9))
  |> pog.parameter(pog.int(arg_10))
  |> pog.parameter(pog.bool(arg_11))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `create_booking_without_group` query
/// defined in `./src/server/sql/create_booking_without_group.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type CreateBookingWithoutGroupRow {
  CreateBookingWithoutGroupRow(
    id: Uuid,
    user_id: Uuid,
    activity_id: Uuid,
    booker_name: String,
    group_free_text: String,
    responsible_name: String,
    phone_number: String,
    participant_count: Int,
  )
}

/// Runs the `create_booking_without_group` query
/// defined in `./src/server/sql/create_booking_without_group.sql`.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn create_booking_without_group(
  db: pog.Connection,
  arg_1: Uuid,
  arg_2: Uuid,
  arg_3: Uuid,
  arg_4: String,
  arg_5: String,
  arg_6: String,
  arg_7: String,
  arg_8: Int,
) -> Result(pog.Returned(CreateBookingWithoutGroupRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use user_id <- decode.field(1, uuid_decoder())
    use activity_id <- decode.field(2, uuid_decoder())
    use booker_name <- decode.field(3, decode.string)
    use group_free_text <- decode.field(4, decode.string)
    use responsible_name <- decode.field(5, decode.string)
    use phone_number <- decode.field(6, decode.string)
    use participant_count <- decode.field(7, decode.int)
    decode.success(CreateBookingWithoutGroupRow(
      id:,
      user_id:,
      activity_id:,
      booker_name:,
      group_free_text:,
      responsible_name:,
      phone_number:,
      participant_count:,
    ))
  }

  "INSERT INTO booking (
        id,
        user_id,
        activity_id,
        booker_name,
        booker_group_id,
        booker_group_name,
        group_free_text,
        responsible_name,
        phone_number,
        participant_count
    )
VALUES ($1, $2, $3, $4, NULL, NULL, $5, $6, $7, $8)
RETURNING id,
    user_id,
    activity_id,
    booker_name,
    group_free_text,
    responsible_name,
    phone_number,
    participant_count
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.parameter(pog.text(uuid.to_string(arg_2)))
  |> pog.parameter(pog.text(uuid.to_string(arg_3)))
  |> pog.parameter(pog.text(arg_4))
  |> pog.parameter(pog.text(arg_5))
  |> pog.parameter(pog.text(arg_6))
  |> pog.parameter(pog.text(arg_7))
  |> pog.parameter(pog.int(arg_8))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// Runs the `create_call_off` query
/// defined in `./src/server/sql/create_call_off.sql`.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn create_call_off(
  db: pog.Connection,
  arg_1: Uuid,
  arg_2: Uuid,
  arg_3: String,
) -> Result(pog.Returned(Nil), pog.QueryError) {
  let decoder = decode.map(decode.dynamic, fn(_) { Nil })

  "INSERT INTO call_off (id, activity_id, reason)
VALUES ($1, $2, $3) ON CONFLICT (activity_id) DO
UPDATE
SET reason = EXCLUDED.reason,
    cancelled_at = NOW();
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.parameter(pog.text(uuid.to_string(arg_2)))
  |> pog.parameter(pog.text(arg_3))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `create_favourite` query
/// defined in `./src/server/sql/create_favourite.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type CreateFavouriteRow {
  CreateFavouriteRow(id: Uuid, user_id: Uuid, activity_id: Uuid)
}

/// Runs the `create_favourite` query
/// defined in `./src/server/sql/create_favourite.sql`.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn create_favourite(
  db: pog.Connection,
  arg_1: Uuid,
  arg_2: Uuid,
  arg_3: Uuid,
) -> Result(pog.Returned(CreateFavouriteRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use user_id <- decode.field(1, uuid_decoder())
    use activity_id <- decode.field(2, uuid_decoder())
    decode.success(CreateFavouriteRow(id:, user_id:, activity_id:))
  }

  "INSERT INTO favourite (id, user_id, activity_id)
VALUES ($1, $2, $3) ON CONFLICT (user_id, activity_id) DO NOTHING
RETURNING id,
    user_id,
    activity_id
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.parameter(pog.text(uuid.to_string(arg_2)))
  |> pog.parameter(pog.text(uuid.to_string(arg_3)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `create_location_tag` query
/// defined in `./src/server/sql/create_location_tag.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type CreateLocationTagRow {
  CreateLocationTagRow(
    id: Uuid,
    name: String,
    name_en: String,
    icon_name: String,
    icon_variant: String,
  )
}

/// Creates a location tag and returns it.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn create_location_tag(
  db: pog.Connection,
  arg_1: Uuid,
  arg_2: String,
  arg_3: String,
  arg_4: String,
  arg_5: String,
) -> Result(pog.Returned(CreateLocationTagRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use name <- decode.field(1, decode.string)
    use name_en <- decode.field(2, decode.string)
    use icon_name <- decode.field(3, decode.string)
    use icon_variant <- decode.field(4, decode.string)
    decode.success(CreateLocationTagRow(
      id:,
      name:,
      name_en:,
      icon_name:,
      icon_variant:,
    ))
  }

  "-- Creates a location tag and returns it.
INSERT INTO location_tag (id, name, name_en, icon_name, icon_variant)
VALUES ($1, $2, $3, $4, $5)
RETURNING id,
    name,
    name_en,
    icon_name,
    icon_variant;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.parameter(pog.text(arg_2))
  |> pog.parameter(pog.text(arg_3))
  |> pog.parameter(pog.text(arg_4))
  |> pog.parameter(pog.text(arg_5))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `create_location_with_coordinates` query
/// defined in `./src/server/sql/create_location_with_coordinates.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type CreateLocationWithCoordinatesRow {
  CreateLocationWithCoordinatesRow(
    id: Uuid,
    name: String,
    name_en: String,
    description: String,
    description_en: String,
    icon_name: String,
    icon_variant: String,
    color: String,
    latitude: Option(Float),
    longitude: Option(Float),
    opening_hours: String,
  )
}

/// Creates a location that has coordinates and returns it. opening_hours is
/// sent as JSON text; the parameter type is inferred as jsonb from the target
/// column. Squirrel cannot generate optional query parameters, so a location
/// without coordinates is created by the _without_coordinates variant instead.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn create_location_with_coordinates(
  db: pog.Connection,
  arg_1: Uuid,
  arg_2: String,
  arg_3: String,
  arg_4: String,
  arg_5: String,
  arg_6: String,
  arg_7: String,
  arg_8: String,
  arg_9: Float,
  arg_10: Float,
  arg_11: Json,
) -> Result(pog.Returned(CreateLocationWithCoordinatesRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use name <- decode.field(1, decode.string)
    use name_en <- decode.field(2, decode.string)
    use description <- decode.field(3, decode.string)
    use description_en <- decode.field(4, decode.string)
    use icon_name <- decode.field(5, decode.string)
    use icon_variant <- decode.field(6, decode.string)
    use color <- decode.field(7, decode.string)
    use latitude <- decode.field(8, decode.optional(decode.float))
    use longitude <- decode.field(9, decode.optional(decode.float))
    use opening_hours <- decode.field(10, decode.string)
    decode.success(CreateLocationWithCoordinatesRow(
      id:,
      name:,
      name_en:,
      description:,
      description_en:,
      icon_name:,
      icon_variant:,
      color:,
      latitude:,
      longitude:,
      opening_hours:,
    ))
  }

  "-- Creates a location that has coordinates and returns it. opening_hours is
-- sent as JSON text; the parameter type is inferred as jsonb from the target
-- column. Squirrel cannot generate optional query parameters, so a location
-- without coordinates is created by the _without_coordinates variant instead.
INSERT INTO location (
        id,
        name,
        name_en,
        description,
        description_en,
        icon_name,
        icon_variant,
        color,
        latitude,
        longitude,
        opening_hours
    )
VALUES (
        $1,
        $2,
        $3,
        $4,
        $5,
        $6,
        $7,
        $8,
        $9,
        $10,
        $11
    )
RETURNING id,
    name,
    name_en,
    description,
    description_en,
    icon_name,
    icon_variant,
    color,
    latitude,
    longitude,
    opening_hours;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.parameter(pog.text(arg_2))
  |> pog.parameter(pog.text(arg_3))
  |> pog.parameter(pog.text(arg_4))
  |> pog.parameter(pog.text(arg_5))
  |> pog.parameter(pog.text(arg_6))
  |> pog.parameter(pog.text(arg_7))
  |> pog.parameter(pog.text(arg_8))
  |> pog.parameter(pog.float(arg_9))
  |> pog.parameter(pog.float(arg_10))
  |> pog.parameter(pog.text(json.to_string(arg_11)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `create_location_without_coordinates` query
/// defined in `./src/server/sql/create_location_without_coordinates.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type CreateLocationWithoutCoordinatesRow {
  CreateLocationWithoutCoordinatesRow(
    id: Uuid,
    name: String,
    name_en: String,
    description: String,
    description_en: String,
    icon_name: String,
    icon_variant: String,
    color: String,
    latitude: Option(Float),
    longitude: Option(Float),
    opening_hours: String,
  )
}

/// Creates a location that has no coordinates (name-only, no map marker) and
/// returns it. opening_hours is sent as JSON text; the parameter type is
/// inferred as jsonb from the target column. Squirrel cannot generate optional
/// query parameters, so the NULL coordinates are literals here rather than
/// parameters of the _with_coordinates variant.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn create_location_without_coordinates(
  db: pog.Connection,
  arg_1: Uuid,
  arg_2: String,
  arg_3: String,
  arg_4: String,
  arg_5: String,
  arg_6: String,
  arg_7: String,
  arg_8: String,
  arg_9: Json,
) -> Result(pog.Returned(CreateLocationWithoutCoordinatesRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use name <- decode.field(1, decode.string)
    use name_en <- decode.field(2, decode.string)
    use description <- decode.field(3, decode.string)
    use description_en <- decode.field(4, decode.string)
    use icon_name <- decode.field(5, decode.string)
    use icon_variant <- decode.field(6, decode.string)
    use color <- decode.field(7, decode.string)
    use latitude <- decode.field(8, decode.optional(decode.float))
    use longitude <- decode.field(9, decode.optional(decode.float))
    use opening_hours <- decode.field(10, decode.string)
    decode.success(CreateLocationWithoutCoordinatesRow(
      id:,
      name:,
      name_en:,
      description:,
      description_en:,
      icon_name:,
      icon_variant:,
      color:,
      latitude:,
      longitude:,
      opening_hours:,
    ))
  }

  "-- Creates a location that has no coordinates (name-only, no map marker) and
-- returns it. opening_hours is sent as JSON text; the parameter type is
-- inferred as jsonb from the target column. Squirrel cannot generate optional
-- query parameters, so the NULL coordinates are literals here rather than
-- parameters of the _with_coordinates variant.
INSERT INTO location (
        id,
        name,
        name_en,
        description,
        description_en,
        icon_name,
        icon_variant,
        color,
        latitude,
        longitude,
        opening_hours
    )
VALUES (
        $1,
        $2,
        $3,
        $4,
        $5,
        $6,
        $7,
        $8,
        NULL,
        NULL,
        $9
    )
RETURNING id,
    name,
    name_en,
    description,
    description_en,
    icon_name,
    icon_variant,
    color,
    latitude,
    longitude,
    opening_hours;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.parameter(pog.text(arg_2))
  |> pog.parameter(pog.text(arg_3))
  |> pog.parameter(pog.text(arg_4))
  |> pog.parameter(pog.text(arg_5))
  |> pog.parameter(pog.text(arg_6))
  |> pog.parameter(pog.text(arg_7))
  |> pog.parameter(pog.text(arg_8))
  |> pog.parameter(pog.text(json.to_string(arg_9)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `delete_activity` query
/// defined in `./src/server/sql/delete_activity.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type DeleteActivityRow {
  DeleteActivityRow(id: Uuid)
}

/// Runs the `delete_activity` query
/// defined in `./src/server/sql/delete_activity.sql`.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn delete_activity(
  db: pog.Connection,
  id: Uuid,
) -> Result(pog.Returned(DeleteActivityRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    decode.success(DeleteActivityRow(id:))
  }

  "DELETE FROM activity
WHERE id = $1
RETURNING id"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(id)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// Removes all activity links for a tag (used before deleting the tag).
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn delete_activity_links_by_tag(
  db: pog.Connection,
  arg_1: Uuid,
) -> Result(pog.Returned(Nil), pog.QueryError) {
  let decoder = decode.map(decode.dynamic, fn(_) { Nil })

  "-- Removes all activity links for a tag (used before deleting the tag).
DELETE FROM activity_tag_activity
WHERE activity_tag_id = $1;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `delete_activity_tag` query
/// defined in `./src/server/sql/delete_activity_tag.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type DeleteActivityTagRow {
  DeleteActivityTagRow(id: Uuid)
}

/// Deletes an activity tag, returning its id if it existed.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn delete_activity_tag(
  db: pog.Connection,
  id: Uuid,
) -> Result(pog.Returned(DeleteActivityTagRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    decode.success(DeleteActivityTagRow(id:))
  }

  "-- Deletes an activity tag, returning its id if it existed.
DELETE FROM activity_tag
WHERE id = $1
RETURNING id;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(id)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// Removes all tag links for an activity (used when re-syncing or deleting).
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn delete_activity_tag_links(
  db: pog.Connection,
  arg_1: Uuid,
) -> Result(pog.Returned(Nil), pog.QueryError) {
  let decoder = decode.map(decode.dynamic, fn(_) { Nil })

  "-- Removes all tag links for an activity (used when re-syncing or deleting).
DELETE FROM activity_tag_activity
WHERE activity_id = $1;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// Removes all target groups for an activity (used when re-syncing or deleting).
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn delete_activity_target_groups(
  db: pog.Connection,
  arg_1: Uuid,
) -> Result(pog.Returned(Nil), pog.QueryError) {
  let decoder = decode.map(decode.dynamic, fn(_) { Nil })

  "-- Removes all target groups for an activity (used when re-syncing or deleting).
DELETE FROM activity_target_group
WHERE activity_id = $1;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `delete_booking` query
/// defined in `./src/server/sql/delete_booking.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type DeleteBookingRow {
  DeleteBookingRow(id: Uuid)
}

/// Runs the `delete_booking` query
/// defined in `./src/server/sql/delete_booking.sql`.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn delete_booking(
  db: pog.Connection,
  id: Uuid,
) -> Result(pog.Returned(DeleteBookingRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    decode.success(DeleteBookingRow(id:))
  }

  "DELETE FROM booking
WHERE id = $1
RETURNING id
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(id)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `delete_favourite` query
/// defined in `./src/server/sql/delete_favourite.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type DeleteFavouriteRow {
  DeleteFavouriteRow(id: Uuid)
}

/// Runs the `delete_favourite` query
/// defined in `./src/server/sql/delete_favourite.sql`.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn delete_favourite(
  db: pog.Connection,
  user_id: Uuid,
  activity_id: Uuid,
) -> Result(pog.Returned(DeleteFavouriteRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    decode.success(DeleteFavouriteRow(id:))
  }

  "DELETE FROM favourite
WHERE user_id = $1
    AND activity_id = $2
RETURNING id
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(user_id)))
  |> pog.parameter(pog.text(uuid.to_string(activity_id)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `delete_location` query
/// defined in `./src/server/sql/delete_location.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type DeleteLocationRow {
  DeleteLocationRow(id: Uuid)
}

/// Deletes a location, returning its id if it existed.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn delete_location(
  db: pog.Connection,
  id: Uuid,
) -> Result(pog.Returned(DeleteLocationRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    decode.success(DeleteLocationRow(id:))
  }

  "-- Deletes a location, returning its id if it existed.
DELETE FROM location
WHERE id = $1
RETURNING id;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(id)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// Removes all location links for a tag (used before deleting the tag).
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn delete_location_links_by_tag(
  db: pog.Connection,
  arg_1: Uuid,
) -> Result(pog.Returned(Nil), pog.QueryError) {
  let decoder = decode.map(decode.dynamic, fn(_) { Nil })

  "-- Removes all location links for a tag (used before deleting the tag).
DELETE FROM location_tag_location
WHERE location_tag_id = $1;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `delete_location_tag` query
/// defined in `./src/server/sql/delete_location_tag.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type DeleteLocationTagRow {
  DeleteLocationTagRow(id: Uuid)
}

/// Deletes a location tag, returning its id if it existed.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn delete_location_tag(
  db: pog.Connection,
  id: Uuid,
) -> Result(pog.Returned(DeleteLocationTagRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    decode.success(DeleteLocationTagRow(id:))
  }

  "-- Deletes a location tag, returning its id if it existed.
DELETE FROM location_tag
WHERE id = $1
RETURNING id;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(id)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// Removes all tag links for a location (used when re-syncing or deleting).
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn delete_location_tag_links(
  db: pog.Connection,
  arg_1: Uuid,
) -> Result(pog.Returned(Nil), pog.QueryError) {
  let decoder = decode.map(decode.dynamic, fn(_) { Nil })

  "-- Removes all tag links for a location (used when re-syncing or deleting).
DELETE FROM location_tag_location
WHERE location_id = $1;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `get_activities_by_start_time` query
/// defined in `./src/server/sql/get_activities_by_start_time.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type GetActivitiesByStartTimeRow {
  GetActivitiesByStartTimeRow(
    id: Uuid,
    title: String,
    description: String,
    max_attendees: Option(Int),
    start_time: Timestamp,
    end_time: Timestamp,
    recurring_activity_kind: Option(String),
    location_id: Option(Uuid),
    title_en: String,
    description_en: String,
    booking_opens_at: Option(Timestamp),
  )
}

/// Runs the `get_activities_by_start_time` query
/// defined in `./src/server/sql/get_activities_by_start_time.sql`.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn get_activities_by_start_time(
  db: pog.Connection,
  arg_1: Int,
  arg_2: Int,
) -> Result(pog.Returned(GetActivitiesByStartTimeRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use title <- decode.field(1, decode.string)
    use description <- decode.field(2, decode.string)
    use max_attendees <- decode.field(3, decode.optional(decode.int))
    use start_time <- decode.field(4, pog.timestamp_decoder())
    use end_time <- decode.field(5, pog.timestamp_decoder())
    use recurring_activity_kind <- decode.field(
      6,
      decode.optional(decode.string),
    )
    use location_id <- decode.field(7, decode.optional(uuid_decoder()))
    use title_en <- decode.field(8, decode.string)
    use description_en <- decode.field(9, decode.string)
    use booking_opens_at <- decode.field(
      10,
      decode.optional(pog.timestamp_decoder()),
    )
    decode.success(GetActivitiesByStartTimeRow(
      id:,
      title:,
      description:,
      max_attendees:,
      start_time:,
      end_time:,
      recurring_activity_kind:,
      location_id:,
      title_en:,
      description_en:,
      booking_opens_at:,
    ))
  }

  "SELECT *
FROM activity
ORDER BY start_time ASC
LIMIT $1 OFFSET $2;"
  |> pog.query
  |> pog.parameter(pog.int(arg_1))
  |> pog.parameter(pog.int(arg_2))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `get_activities_by_title` query
/// defined in `./src/server/sql/get_activities_by_title.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type GetActivitiesByTitleRow {
  GetActivitiesByTitleRow(
    id: Uuid,
    title: String,
    description: String,
    max_attendees: Option(Int),
    start_time: Timestamp,
    end_time: Timestamp,
    recurring_activity_kind: Option(String),
    location_id: Option(Uuid),
    title_en: String,
    description_en: String,
    booking_opens_at: Option(Timestamp),
  )
}

/// Runs the `get_activities_by_title` query
/// defined in `./src/server/sql/get_activities_by_title.sql`.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn get_activities_by_title(
  db: pog.Connection,
  arg_1: Int,
  arg_2: Int,
) -> Result(pog.Returned(GetActivitiesByTitleRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use title <- decode.field(1, decode.string)
    use description <- decode.field(2, decode.string)
    use max_attendees <- decode.field(3, decode.optional(decode.int))
    use start_time <- decode.field(4, pog.timestamp_decoder())
    use end_time <- decode.field(5, pog.timestamp_decoder())
    use recurring_activity_kind <- decode.field(
      6,
      decode.optional(decode.string),
    )
    use location_id <- decode.field(7, decode.optional(uuid_decoder()))
    use title_en <- decode.field(8, decode.string)
    use description_en <- decode.field(9, decode.string)
    use booking_opens_at <- decode.field(
      10,
      decode.optional(pog.timestamp_decoder()),
    )
    decode.success(GetActivitiesByTitleRow(
      id:,
      title:,
      description:,
      max_attendees:,
      start_time:,
      end_time:,
      recurring_activity_kind:,
      location_id:,
      title_en:,
      description_en:,
      booking_opens_at:,
    ))
  }

  "SELECT *
FROM activity
ORDER BY title ASC
LIMIT $1 OFFSET $2;"
  |> pog.query
  |> pog.parameter(pog.int(arg_1))
  |> pog.parameter(pog.int(arg_2))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `get_activity` query
/// defined in `./src/server/sql/get_activity.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type GetActivityRow {
  GetActivityRow(
    id: Uuid,
    title: String,
    description: String,
    max_attendees: Option(Int),
    start_time: Timestamp,
    end_time: Timestamp,
    recurring_activity_kind: Option(String),
    location_id: Option(Uuid),
    title_en: String,
    description_en: String,
    booking_opens_at: Option(Timestamp),
  )
}

/// Runs the `get_activity` query
/// defined in `./src/server/sql/get_activity.sql`.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn get_activity(
  db: pog.Connection,
  arg_1: Uuid,
) -> Result(pog.Returned(GetActivityRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use title <- decode.field(1, decode.string)
    use description <- decode.field(2, decode.string)
    use max_attendees <- decode.field(3, decode.optional(decode.int))
    use start_time <- decode.field(4, pog.timestamp_decoder())
    use end_time <- decode.field(5, pog.timestamp_decoder())
    use recurring_activity_kind <- decode.field(
      6,
      decode.optional(decode.string),
    )
    use location_id <- decode.field(7, decode.optional(uuid_decoder()))
    use title_en <- decode.field(8, decode.string)
    use description_en <- decode.field(9, decode.string)
    use booking_opens_at <- decode.field(
      10,
      decode.optional(pog.timestamp_decoder()),
    )
    decode.success(GetActivityRow(
      id:,
      title:,
      description:,
      max_attendees:,
      start_time:,
      end_time:,
      recurring_activity_kind:,
      location_id:,
      title_en:,
      description_en:,
      booking_opens_at:,
    ))
  }

  "SELECT *
FROM activity
WHERE id = $1;"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `get_activity_spots` query
/// defined in `./src/server/sql/get_activity_spots.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type GetActivitySpotsRow {
  GetActivitySpotsRow(spots_booked: Int)
}

/// Booked spot count for a single activity. The aggregate has no GROUP BY, so
/// it always returns exactly one row (0 when the activity has no bookings).
/// Cancelled bookings don't occupy spots.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn get_activity_spots(
  db: pog.Connection,
  activity_id: Uuid,
) -> Result(pog.Returned(GetActivitySpotsRow), pog.QueryError) {
  let decoder = {
    use spots_booked <- decode.field(0, decode.int)
    decode.success(GetActivitySpotsRow(spots_booked:))
  }

  "-- Booked spot count for a single activity. The aggregate has no GROUP BY, so
-- it always returns exactly one row (0 when the activity has no bookings).
-- Cancelled bookings don't occupy spots.
SELECT COALESCE(SUM(participant_count), 0) AS spots_booked
FROM booking
WHERE activity_id = $1
    AND cancellation_reason IS NULL
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(activity_id)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `get_activity_tag` query
/// defined in `./src/server/sql/get_activity_tag.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type GetActivityTagRow {
  GetActivityTagRow(id: Uuid, name: String, name_en: String)
}

/// Gets a single activity tag by id.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn get_activity_tag(
  db: pog.Connection,
  arg_1: Uuid,
) -> Result(pog.Returned(GetActivityTagRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use name <- decode.field(1, decode.string)
    use name_en <- decode.field(2, decode.string)
    decode.success(GetActivityTagRow(id:, name:, name_en:))
  }

  "-- Gets a single activity tag by id.
SELECT id,
    name,
    name_en
FROM activity_tag
WHERE id = $1;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `get_booking` query
/// defined in `./src/server/sql/get_booking.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type GetBookingRow {
  GetBookingRow(
    id: Uuid,
    user_id: Uuid,
    activity_id: Uuid,
    booker_name: String,
    booker_group_id: Option(Int),
    booker_group_name: Option(String),
    group_free_text: String,
    responsible_name: String,
    phone_number: String,
    participant_count: Int,
    booked_for_other: Bool,
    cancellation_reason: Option(String),
  )
}

/// Runs the `get_booking` query
/// defined in `./src/server/sql/get_booking.sql`.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn get_booking(
  db: pog.Connection,
  id: Uuid,
) -> Result(pog.Returned(GetBookingRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use user_id <- decode.field(1, uuid_decoder())
    use activity_id <- decode.field(2, uuid_decoder())
    use booker_name <- decode.field(3, decode.string)
    use booker_group_id <- decode.field(4, decode.optional(decode.int))
    use booker_group_name <- decode.field(5, decode.optional(decode.string))
    use group_free_text <- decode.field(6, decode.string)
    use responsible_name <- decode.field(7, decode.string)
    use phone_number <- decode.field(8, decode.string)
    use participant_count <- decode.field(9, decode.int)
    use booked_for_other <- decode.field(10, decode.bool)
    use cancellation_reason <- decode.field(11, decode.optional(decode.string))
    decode.success(GetBookingRow(
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
      cancellation_reason:,
    ))
  }

  "SELECT id,
    user_id,
    activity_id,
    booker_name,
    booker_group_id,
    booker_group_name,
    group_free_text,
    responsible_name,
    phone_number,
    participant_count,
    booked_for_other,
    cancellation_reason
FROM booking
WHERE id = $1
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(id)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `get_booking_by_user_and_activity` query
/// defined in `./src/server/sql/get_booking_by_user_and_activity.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type GetBookingByUserAndActivityRow {
  GetBookingByUserAndActivityRow(id: Uuid)
}

/// Runs the `get_booking_by_user_and_activity` query
/// defined in `./src/server/sql/get_booking_by_user_and_activity.sql`.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn get_booking_by_user_and_activity(
  db: pog.Connection,
  user_id: Uuid,
  activity_id: Uuid,
) -> Result(pog.Returned(GetBookingByUserAndActivityRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    decode.success(GetBookingByUserAndActivityRow(id:))
  }

  "SELECT id
FROM booking
WHERE user_id = $1
    AND activity_id = $2
LIMIT 1
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(user_id)))
  |> pog.parameter(pog.text(uuid.to_string(activity_id)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `get_bookings_by_activity` query
/// defined in `./src/server/sql/get_bookings_by_activity.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type GetBookingsByActivityRow {
  GetBookingsByActivityRow(
    id: Uuid,
    user_id: Uuid,
    activity_id: Uuid,
    booker_name: String,
    booker_group_id: Option(Int),
    booker_group_name: Option(String),
    group_free_text: String,
    responsible_name: String,
    phone_number: String,
    participant_count: Int,
    booked_for_other: Bool,
    cancellation_reason: Option(String),
  )
}

/// Runs the `get_bookings_by_activity` query
/// defined in `./src/server/sql/get_bookings_by_activity.sql`.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn get_bookings_by_activity(
  db: pog.Connection,
  activity_id: Uuid,
  arg_2: Int,
  arg_3: Int,
) -> Result(pog.Returned(GetBookingsByActivityRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use user_id <- decode.field(1, uuid_decoder())
    use activity_id <- decode.field(2, uuid_decoder())
    use booker_name <- decode.field(3, decode.string)
    use booker_group_id <- decode.field(4, decode.optional(decode.int))
    use booker_group_name <- decode.field(5, decode.optional(decode.string))
    use group_free_text <- decode.field(6, decode.string)
    use responsible_name <- decode.field(7, decode.string)
    use phone_number <- decode.field(8, decode.string)
    use participant_count <- decode.field(9, decode.int)
    use booked_for_other <- decode.field(10, decode.bool)
    use cancellation_reason <- decode.field(11, decode.optional(decode.string))
    decode.success(GetBookingsByActivityRow(
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
      cancellation_reason:,
    ))
  }

  "SELECT id,
    user_id,
    activity_id,
    booker_name,
    booker_group_id,
    booker_group_name,
    group_free_text,
    responsible_name,
    phone_number,
    participant_count,
    booked_for_other,
    cancellation_reason
FROM booking
WHERE activity_id = $1
ORDER BY responsible_name ASC
LIMIT $2
OFFSET $3
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(activity_id)))
  |> pog.parameter(pog.int(arg_2))
  |> pog.parameter(pog.int(arg_3))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `get_bookings_by_user` query
/// defined in `./src/server/sql/get_bookings_by_user.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type GetBookingsByUserRow {
  GetBookingsByUserRow(
    id: Uuid,
    user_id: Uuid,
    activity_id: Uuid,
    booker_name: String,
    booker_group_id: Option(Int),
    booker_group_name: Option(String),
    group_free_text: String,
    responsible_name: String,
    phone_number: String,
    participant_count: Int,
    booked_for_other: Bool,
    cancellation_reason: Option(String),
  )
}

/// Runs the `get_bookings_by_user` query
/// defined in `./src/server/sql/get_bookings_by_user.sql`.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn get_bookings_by_user(
  db: pog.Connection,
  user_id: Uuid,
) -> Result(pog.Returned(GetBookingsByUserRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use user_id <- decode.field(1, uuid_decoder())
    use activity_id <- decode.field(2, uuid_decoder())
    use booker_name <- decode.field(3, decode.string)
    use booker_group_id <- decode.field(4, decode.optional(decode.int))
    use booker_group_name <- decode.field(5, decode.optional(decode.string))
    use group_free_text <- decode.field(6, decode.string)
    use responsible_name <- decode.field(7, decode.string)
    use phone_number <- decode.field(8, decode.string)
    use participant_count <- decode.field(9, decode.int)
    use booked_for_other <- decode.field(10, decode.bool)
    use cancellation_reason <- decode.field(11, decode.optional(decode.string))
    decode.success(GetBookingsByUserRow(
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
      cancellation_reason:,
    ))
  }

  "SELECT id,
    user_id,
    activity_id,
    booker_name,
    booker_group_id,
    booker_group_name,
    group_free_text,
    responsible_name,
    phone_number,
    participant_count,
    booked_for_other,
    cancellation_reason
FROM booking
WHERE user_id = $1
ORDER BY id;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(user_id)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `get_call_off_by_activity` query
/// defined in `./src/server/sql/get_call_off_by_activity.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type GetCallOffByActivityRow {
  GetCallOffByActivityRow(
    id: Uuid,
    activity_id: Uuid,
    reason: String,
    cancelled_at: Timestamp,
  )
}

/// Runs the `get_call_off_by_activity` query
/// defined in `./src/server/sql/get_call_off_by_activity.sql`.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn get_call_off_by_activity(
  db: pog.Connection,
  arg_1: Uuid,
) -> Result(pog.Returned(GetCallOffByActivityRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use activity_id <- decode.field(1, uuid_decoder())
    use reason <- decode.field(2, decode.string)
    use cancelled_at <- decode.field(3, pog.timestamp_decoder())
    decode.success(GetCallOffByActivityRow(
      id:,
      activity_id:,
      reason:,
      cancelled_at:,
    ))
  }

  "SELECT id,
    activity_id,
    reason,
    cancelled_at
FROM call_off
WHERE activity_id = $1;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `get_cancelled_booking_by_user_and_activity` query
/// defined in `./src/server/sql/get_cancelled_booking_by_user_and_activity.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type GetCancelledBookingByUserAndActivityRow {
  GetCancelledBookingByUserAndActivityRow(id: Uuid)
}

/// Whether the user has a cancelled booking on the activity. A cancelled
/// booking blocks re-booking until a bookings:others:create holder restores
/// or hard-deletes it (the create handler answers 409).
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn get_cancelled_booking_by_user_and_activity(
  db: pog.Connection,
  user_id: Uuid,
  activity_id: Uuid,
) -> Result(
  pog.Returned(GetCancelledBookingByUserAndActivityRow),
  pog.QueryError,
) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    decode.success(GetCancelledBookingByUserAndActivityRow(id:))
  }

  "-- Whether the user has a cancelled booking on the activity. A cancelled
-- booking blocks re-booking until a bookings:others:create holder restores
-- or hard-deletes it (the create handler answers 409).
SELECT id
FROM booking
WHERE user_id = $1
    AND activity_id = $2
    AND cancellation_reason IS NOT NULL
LIMIT 1
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(user_id)))
  |> pog.parameter(pog.text(uuid.to_string(activity_id)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `get_favourites_by_user` query
/// defined in `./src/server/sql/get_favourites_by_user.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type GetFavouritesByUserRow {
  GetFavouritesByUserRow(id: Uuid, user_id: Uuid, activity_id: Uuid)
}

/// Runs the `get_favourites_by_user` query
/// defined in `./src/server/sql/get_favourites_by_user.sql`.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn get_favourites_by_user(
  db: pog.Connection,
  user_id: Uuid,
) -> Result(pog.Returned(GetFavouritesByUserRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use user_id <- decode.field(1, uuid_decoder())
    use activity_id <- decode.field(2, uuid_decoder())
    decode.success(GetFavouritesByUserRow(id:, user_id:, activity_id:))
  }

  "SELECT id,
    user_id,
    activity_id
FROM favourite
WHERE user_id = $1
ORDER BY id
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(user_id)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `get_location` query
/// defined in `./src/server/sql/get_location.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type GetLocationRow {
  GetLocationRow(
    id: Uuid,
    name: String,
    name_en: String,
    description: String,
    description_en: String,
    icon_name: String,
    icon_variant: String,
    color: String,
    latitude: Option(Float),
    longitude: Option(Float),
    opening_hours: String,
  )
}

/// Gets a single location by id.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn get_location(
  db: pog.Connection,
  arg_1: Uuid,
) -> Result(pog.Returned(GetLocationRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use name <- decode.field(1, decode.string)
    use name_en <- decode.field(2, decode.string)
    use description <- decode.field(3, decode.string)
    use description_en <- decode.field(4, decode.string)
    use icon_name <- decode.field(5, decode.string)
    use icon_variant <- decode.field(6, decode.string)
    use color <- decode.field(7, decode.string)
    use latitude <- decode.field(8, decode.optional(decode.float))
    use longitude <- decode.field(9, decode.optional(decode.float))
    use opening_hours <- decode.field(10, decode.string)
    decode.success(GetLocationRow(
      id:,
      name:,
      name_en:,
      description:,
      description_en:,
      icon_name:,
      icon_variant:,
      color:,
      latitude:,
      longitude:,
      opening_hours:,
    ))
  }

  "-- Gets a single location by id.
SELECT id,
    name,
    name_en,
    description,
    description_en,
    icon_name,
    icon_variant,
    color,
    latitude,
    longitude,
    opening_hours
FROM location
WHERE id = $1;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `get_location_tag` query
/// defined in `./src/server/sql/get_location_tag.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type GetLocationTagRow {
  GetLocationTagRow(
    id: Uuid,
    name: String,
    name_en: String,
    icon_name: String,
    icon_variant: String,
  )
}

/// Gets a single location tag by id.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn get_location_tag(
  db: pog.Connection,
  arg_1: Uuid,
) -> Result(pog.Returned(GetLocationTagRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use name <- decode.field(1, decode.string)
    use name_en <- decode.field(2, decode.string)
    use icon_name <- decode.field(3, decode.string)
    use icon_variant <- decode.field(4, decode.string)
    decode.success(GetLocationTagRow(
      id:,
      name:,
      name_en:,
      icon_name:,
      icon_variant:,
    ))
  }

  "-- Gets a single location tag by id.
SELECT id,
    name,
    name_en,
    icon_name,
    icon_variant
FROM location_tag
WHERE id = $1;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `get_location_tag_ids` query
/// defined in `./src/server/sql/get_location_tag_ids.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type GetLocationTagIdsRow {
  GetLocationTagIdsRow(location_tag_id: Uuid)
}

/// Lists the tag ids linked to a location.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn get_location_tag_ids(
  db: pog.Connection,
  arg_1: Uuid,
) -> Result(pog.Returned(GetLocationTagIdsRow), pog.QueryError) {
  let decoder = {
    use location_tag_id <- decode.field(0, uuid_decoder())
    decode.success(GetLocationTagIdsRow(location_tag_id:))
  }

  "-- Lists the tag ids linked to a location.
SELECT location_tag_id
FROM location_tag_location
WHERE location_id = $1;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// Links an activity to the given tag ids in one statement. An empty array
/// inserts no rows.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn insert_activity_tag_links(
  db: pog.Connection,
  arg_1: Uuid,
  arg_2: List(Uuid),
) -> Result(pog.Returned(Nil), pog.QueryError) {
  let decoder = decode.map(decode.dynamic, fn(_) { Nil })

  "-- Links an activity to the given tag ids in one statement. An empty array
-- inserts no rows.
INSERT INTO activity_tag_activity (activity_id, activity_tag_id)
SELECT $1, unnest($2::uuid[]);
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.parameter(pog.array(
    fn(value) { pog.text(uuid.to_string(value)) },
    arg_2,
  ))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// Sets an activity's target groups in one statement. Casting the array to the
/// enum type makes Squirrel type the parameter as the generated target group
/// type. An empty array inserts no rows.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn insert_activity_target_groups(
  db: pog.Connection,
  arg_1: Uuid,
  arg_2: List(TargetGroup),
) -> Result(pog.Returned(Nil), pog.QueryError) {
  let decoder = decode.map(decode.dynamic, fn(_) { Nil })

  "-- Sets an activity's target groups in one statement. Casting the array to the
-- enum type makes Squirrel type the parameter as the generated target group
-- type. An empty array inserts no rows.
INSERT INTO activity_target_group (activity_id, target_group)
SELECT $1, unnest($2::target_group[]);
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.parameter(pog.array(fn(value) { target_group_encoder(value) }, arg_2))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// Links a location to the given tag ids in one statement. An empty array
/// inserts no rows.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn insert_location_tag_links(
  db: pog.Connection,
  arg_1: Uuid,
  arg_2: List(Uuid),
) -> Result(pog.Returned(Nil), pog.QueryError) {
  let decoder = decode.map(decode.dynamic, fn(_) { Nil })

  "-- Links a location to the given tag ids in one statement. An empty array
-- inserts no rows.
INSERT INTO location_tag_location (location_id, location_tag_id)
SELECT $1, unnest($2::uuid[]);
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.parameter(pog.array(
    fn(value) { pog.text(uuid.to_string(value)) },
    arg_2,
  ))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `list_activities_by_start_time` query
/// defined in `./src/server/sql/list_activities_by_start_time.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type ListActivitiesByStartTimeRow {
  ListActivitiesByStartTimeRow(
    id: Uuid,
    title: String,
    description: String,
    max_attendees: Option(Int),
    start_time: Timestamp,
    end_time: Timestamp,
    recurring_activity_kind: Option(String),
    location_id: Option(Uuid),
    title_en: String,
    description_en: String,
    booking_opens_at: Option(Timestamp),
  )
}

/// Runs the `list_activities_by_start_time` query
/// defined in `./src/server/sql/list_activities_by_start_time.sql`.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn list_activities_by_start_time(
  db: pog.Connection,
  arg_1: Bool,
  arg_2: Timestamp,
  arg_3: Timestamp,
) -> Result(pog.Returned(ListActivitiesByStartTimeRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use title <- decode.field(1, decode.string)
    use description <- decode.field(2, decode.string)
    use max_attendees <- decode.field(3, decode.optional(decode.int))
    use start_time <- decode.field(4, pog.timestamp_decoder())
    use end_time <- decode.field(5, pog.timestamp_decoder())
    use recurring_activity_kind <- decode.field(
      6,
      decode.optional(decode.string),
    )
    use location_id <- decode.field(7, decode.optional(uuid_decoder()))
    use title_en <- decode.field(8, decode.string)
    use description_en <- decode.field(9, decode.string)
    use booking_opens_at <- decode.field(
      10,
      decode.optional(pog.timestamp_decoder()),
    )
    decode.success(ListActivitiesByStartTimeRow(
      id:,
      title:,
      description:,
      max_attendees:,
      start_time:,
      end_time:,
      recurring_activity_kind:,
      location_id:,
      title_en:,
      description_en:,
      booking_opens_at:,
    ))
  }

  "SELECT *
FROM activity
WHERE recurring_activity_kind IS NULL
    AND (
        $1 = TRUE
        OR NOT EXISTS (
            SELECT 1 FROM call_off c WHERE c.activity_id = activity.id
        )
    )
    AND start_time >= $2
    AND start_time < $3
ORDER BY start_time ASC;
"
  |> pog.query
  |> pog.parameter(pog.bool(arg_1))
  |> pog.parameter(pog.timestamp(arg_2))
  |> pog.parameter(pog.timestamp(arg_3))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `list_activities_by_title` query
/// defined in `./src/server/sql/list_activities_by_title.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type ListActivitiesByTitleRow {
  ListActivitiesByTitleRow(
    id: Uuid,
    title: String,
    description: String,
    max_attendees: Option(Int),
    start_time: Timestamp,
    end_time: Timestamp,
    recurring_activity_kind: Option(String),
    location_id: Option(Uuid),
    title_en: String,
    description_en: String,
    booking_opens_at: Option(Timestamp),
  )
}

/// Runs the `list_activities_by_title` query
/// defined in `./src/server/sql/list_activities_by_title.sql`.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn list_activities_by_title(
  db: pog.Connection,
  arg_1: Bool,
  arg_2: Timestamp,
  arg_3: Timestamp,
) -> Result(pog.Returned(ListActivitiesByTitleRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use title <- decode.field(1, decode.string)
    use description <- decode.field(2, decode.string)
    use max_attendees <- decode.field(3, decode.optional(decode.int))
    use start_time <- decode.field(4, pog.timestamp_decoder())
    use end_time <- decode.field(5, pog.timestamp_decoder())
    use recurring_activity_kind <- decode.field(
      6,
      decode.optional(decode.string),
    )
    use location_id <- decode.field(7, decode.optional(uuid_decoder()))
    use title_en <- decode.field(8, decode.string)
    use description_en <- decode.field(9, decode.string)
    use booking_opens_at <- decode.field(
      10,
      decode.optional(pog.timestamp_decoder()),
    )
    decode.success(ListActivitiesByTitleRow(
      id:,
      title:,
      description:,
      max_attendees:,
      start_time:,
      end_time:,
      recurring_activity_kind:,
      location_id:,
      title_en:,
      description_en:,
      booking_opens_at:,
    ))
  }

  "SELECT *
FROM activity
WHERE recurring_activity_kind IS NULL
    AND (
        $1 = TRUE
        OR NOT EXISTS (
            SELECT 1 FROM call_off c WHERE c.activity_id = activity.id
        )
    )
    AND start_time >= $2
    AND start_time < $3
ORDER BY title ASC;
"
  |> pog.query
  |> pog.parameter(pog.bool(arg_1))
  |> pog.parameter(pog.timestamp(arg_2))
  |> pog.parameter(pog.timestamp(arg_3))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `list_activity_spots` query
/// defined in `./src/server/sql/list_activity_spots.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type ListActivitySpotsRow {
  ListActivitySpotsRow(activity_id: Uuid, spots_booked: Int)
}

/// Booked spot count per activity. LEFT JOIN so activities with no bookings
/// return 0 (not absent) — the client distinguishes known-zero from unknown.
/// Cancelled bookings don't occupy spots.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn list_activity_spots(
  db: pog.Connection,
) -> Result(pog.Returned(ListActivitySpotsRow), pog.QueryError) {
  let decoder = {
    use activity_id <- decode.field(0, uuid_decoder())
    use spots_booked <- decode.field(1, decode.int)
    decode.success(ListActivitySpotsRow(activity_id:, spots_booked:))
  }

  "-- Booked spot count per activity. LEFT JOIN so activities with no bookings
-- return 0 (not absent) — the client distinguishes known-zero from unknown.
-- Cancelled bookings don't occupy spots.
SELECT activity.id AS activity_id,
    COALESCE(SUM(booking.participant_count), 0) AS spots_booked
FROM activity
    LEFT JOIN booking ON booking.activity_id = activity.id
    AND booking.cancellation_reason IS NULL
GROUP BY activity.id
"
  |> pog.query
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `list_activity_tag_links` query
/// defined in `./src/server/sql/list_activity_tag_links.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type ListActivityTagLinksRow {
  ListActivityTagLinksRow(activity_id: Uuid, activity_tag_id: Uuid)
}

/// Lists every activity-to-tag link. Grouped by activity in the handler to embed
/// each activity's tag ids without an array aggregation.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn list_activity_tag_links(
  db: pog.Connection,
) -> Result(pog.Returned(ListActivityTagLinksRow), pog.QueryError) {
  let decoder = {
    use activity_id <- decode.field(0, uuid_decoder())
    use activity_tag_id <- decode.field(1, uuid_decoder())
    decode.success(ListActivityTagLinksRow(activity_id:, activity_tag_id:))
  }

  "-- Lists every activity-to-tag link. Grouped by activity in the handler to embed
-- each activity's tag ids without an array aggregation.
SELECT activity_id,
    activity_tag_id
FROM activity_tag_activity;
"
  |> pog.query
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `list_activity_tags` query
/// defined in `./src/server/sql/list_activity_tags.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type ListActivityTagsRow {
  ListActivityTagsRow(id: Uuid, name: String, name_en: String)
}

/// Lists all activity tags ordered by name.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn list_activity_tags(
  db: pog.Connection,
) -> Result(pog.Returned(ListActivityTagsRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use name <- decode.field(1, decode.string)
    use name_en <- decode.field(2, decode.string)
    decode.success(ListActivityTagsRow(id:, name:, name_en:))
  }

  "-- Lists all activity tags ordered by name.
SELECT id,
    name,
    name_en
FROM activity_tag
ORDER BY name ASC;
"
  |> pog.query
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `list_activity_target_groups` query
/// defined in `./src/server/sql/list_activity_target_groups.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type ListActivityTargetGroupsRow {
  ListActivityTargetGroupsRow(activity_id: Uuid, target_group: TargetGroup)
}

/// Lists every activity-to-target-group link. Grouped by activity in the handler
/// to embed each activity's target groups without an array aggregation.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn list_activity_target_groups(
  db: pog.Connection,
) -> Result(pog.Returned(ListActivityTargetGroupsRow), pog.QueryError) {
  let decoder = {
    use activity_id <- decode.field(0, uuid_decoder())
    use target_group <- decode.field(1, target_group_decoder())
    decode.success(ListActivityTargetGroupsRow(activity_id:, target_group:))
  }

  "-- Lists every activity-to-target-group link. Grouped by activity in the handler
-- to embed each activity's target groups without an array aggregation.
SELECT activity_id,
    target_group
FROM activity_target_group;
"
  |> pog.query
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `list_beach_bus_activities` query
/// defined in `./src/server/sql/list_beach_bus_activities.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type ListBeachBusActivitiesRow {
  ListBeachBusActivitiesRow(
    id: Uuid,
    title: String,
    description: String,
    max_attendees: Option(Int),
    start_time: Timestamp,
    end_time: Timestamp,
    recurring_activity_kind: Option(String),
    location_id: Option(Uuid),
    title_en: String,
    description_en: String,
    booking_opens_at: Option(Timestamp),
  )
}

/// Runs the `list_beach_bus_activities` query
/// defined in `./src/server/sql/list_beach_bus_activities.sql`.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn list_beach_bus_activities(
  db: pog.Connection,
  arg_1: Bool,
  arg_2: Timestamp,
  arg_3: Timestamp,
) -> Result(pog.Returned(ListBeachBusActivitiesRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use title <- decode.field(1, decode.string)
    use description <- decode.field(2, decode.string)
    use max_attendees <- decode.field(3, decode.optional(decode.int))
    use start_time <- decode.field(4, pog.timestamp_decoder())
    use end_time <- decode.field(5, pog.timestamp_decoder())
    use recurring_activity_kind <- decode.field(
      6,
      decode.optional(decode.string),
    )
    use location_id <- decode.field(7, decode.optional(uuid_decoder()))
    use title_en <- decode.field(8, decode.string)
    use description_en <- decode.field(9, decode.string)
    use booking_opens_at <- decode.field(
      10,
      decode.optional(pog.timestamp_decoder()),
    )
    decode.success(ListBeachBusActivitiesRow(
      id:,
      title:,
      description:,
      max_attendees:,
      start_time:,
      end_time:,
      recurring_activity_kind:,
      location_id:,
      title_en:,
      description_en:,
      booking_opens_at:,
    ))
  }

  "SELECT *
FROM activity
WHERE recurring_activity_kind = 'beach-bus'
    AND (
        $1 = TRUE
        OR NOT EXISTS (
            SELECT 1 FROM call_off c WHERE c.activity_id = activity.id
        )
    )
    AND start_time >= $2
    AND start_time < $3
ORDER BY start_time ASC;
"
  |> pog.query
  |> pog.parameter(pog.bool(arg_1))
  |> pog.parameter(pog.timestamp(arg_2))
  |> pog.parameter(pog.timestamp(arg_3))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `list_call_offs` query
/// defined in `./src/server/sql/list_call_offs.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type ListCallOffsRow {
  ListCallOffsRow(
    id: Uuid,
    activity_id: Uuid,
    reason: String,
    cancelled_at: Timestamp,
  )
}

/// Runs the `list_call_offs` query
/// defined in `./src/server/sql/list_call_offs.sql`.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn list_call_offs(
  db: pog.Connection,
) -> Result(pog.Returned(ListCallOffsRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use activity_id <- decode.field(1, uuid_decoder())
    use reason <- decode.field(2, decode.string)
    use cancelled_at <- decode.field(3, pog.timestamp_decoder())
    decode.success(ListCallOffsRow(id:, activity_id:, reason:, cancelled_at:))
  }

  "SELECT id,
    activity_id,
    reason,
    cancelled_at
FROM call_off;
"
  |> pog.query
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `list_climbing_wall_activities` query
/// defined in `./src/server/sql/list_climbing_wall_activities.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type ListClimbingWallActivitiesRow {
  ListClimbingWallActivitiesRow(
    id: Uuid,
    title: String,
    description: String,
    max_attendees: Option(Int),
    start_time: Timestamp,
    end_time: Timestamp,
    recurring_activity_kind: Option(String),
    location_id: Option(Uuid),
    title_en: String,
    description_en: String,
    booking_opens_at: Option(Timestamp),
  )
}

/// Runs the `list_climbing_wall_activities` query
/// defined in `./src/server/sql/list_climbing_wall_activities.sql`.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn list_climbing_wall_activities(
  db: pog.Connection,
  arg_1: Bool,
  arg_2: Timestamp,
  arg_3: Timestamp,
) -> Result(pog.Returned(ListClimbingWallActivitiesRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use title <- decode.field(1, decode.string)
    use description <- decode.field(2, decode.string)
    use max_attendees <- decode.field(3, decode.optional(decode.int))
    use start_time <- decode.field(4, pog.timestamp_decoder())
    use end_time <- decode.field(5, pog.timestamp_decoder())
    use recurring_activity_kind <- decode.field(
      6,
      decode.optional(decode.string),
    )
    use location_id <- decode.field(7, decode.optional(uuid_decoder()))
    use title_en <- decode.field(8, decode.string)
    use description_en <- decode.field(9, decode.string)
    use booking_opens_at <- decode.field(
      10,
      decode.optional(pog.timestamp_decoder()),
    )
    decode.success(ListClimbingWallActivitiesRow(
      id:,
      title:,
      description:,
      max_attendees:,
      start_time:,
      end_time:,
      recurring_activity_kind:,
      location_id:,
      title_en:,
      description_en:,
      booking_opens_at:,
    ))
  }

  "SELECT *
FROM activity
WHERE recurring_activity_kind = 'climbing-wall'
    AND (
        $1 = TRUE
        OR NOT EXISTS (
            SELECT 1 FROM call_off c WHERE c.activity_id = activity.id
        )
    )
    AND start_time >= $2
    AND start_time < $3
ORDER BY start_time ASC;
"
  |> pog.query
  |> pog.parameter(pog.bool(arg_1))
  |> pog.parameter(pog.timestamp(arg_2))
  |> pog.parameter(pog.timestamp(arg_3))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `list_favourited_activities` query
/// defined in `./src/server/sql/list_favourited_activities.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type ListFavouritedActivitiesRow {
  ListFavouritedActivitiesRow(
    id: Uuid,
    title: String,
    description: String,
    max_attendees: Option(Int),
    start_time: Timestamp,
    end_time: Timestamp,
    recurring_activity_kind: Option(String),
    location_id: Option(Uuid),
    title_en: String,
    description_en: String,
    booking_opens_at: Option(Timestamp),
  )
}

/// Runs the `list_favourited_activities` query
/// defined in `./src/server/sql/list_favourited_activities.sql`.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn list_favourited_activities(
  db: pog.Connection,
  arg_1: Uuid,
) -> Result(pog.Returned(ListFavouritedActivitiesRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use title <- decode.field(1, decode.string)
    use description <- decode.field(2, decode.string)
    use max_attendees <- decode.field(3, decode.optional(decode.int))
    use start_time <- decode.field(4, pog.timestamp_decoder())
    use end_time <- decode.field(5, pog.timestamp_decoder())
    use recurring_activity_kind <- decode.field(
      6,
      decode.optional(decode.string),
    )
    use location_id <- decode.field(7, decode.optional(uuid_decoder()))
    use title_en <- decode.field(8, decode.string)
    use description_en <- decode.field(9, decode.string)
    use booking_opens_at <- decode.field(
      10,
      decode.optional(pog.timestamp_decoder()),
    )
    decode.success(ListFavouritedActivitiesRow(
      id:,
      title:,
      description:,
      max_attendees:,
      start_time:,
      end_time:,
      recurring_activity_kind:,
      location_id:,
      title_en:,
      description_en:,
      booking_opens_at:,
    ))
  }

  "SELECT DISTINCT activity.*
FROM activity
WHERE activity.id IN (SELECT activity_id FROM favourite WHERE user_id = $1)
   OR activity.id IN (SELECT activity_id FROM booking WHERE user_id = $1)
ORDER BY activity.start_time ASC;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `list_location_tag_links` query
/// defined in `./src/server/sql/list_location_tag_links.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type ListLocationTagLinksRow {
  ListLocationTagLinksRow(location_id: Uuid, location_tag_id: Uuid)
}

/// Lists every location-to-tag link. Joined to locations in the handler to embed
/// each location's tag ids without an array aggregation.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn list_location_tag_links(
  db: pog.Connection,
) -> Result(pog.Returned(ListLocationTagLinksRow), pog.QueryError) {
  let decoder = {
    use location_id <- decode.field(0, uuid_decoder())
    use location_tag_id <- decode.field(1, uuid_decoder())
    decode.success(ListLocationTagLinksRow(location_id:, location_tag_id:))
  }

  "-- Lists every location-to-tag link. Joined to locations in the handler to embed
-- each location's tag ids without an array aggregation.
SELECT location_id,
    location_tag_id
FROM location_tag_location;
"
  |> pog.query
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `list_location_tags` query
/// defined in `./src/server/sql/list_location_tags.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type ListLocationTagsRow {
  ListLocationTagsRow(
    id: Uuid,
    name: String,
    name_en: String,
    icon_name: String,
    icon_variant: String,
  )
}

/// Lists all location tags ordered by name.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn list_location_tags(
  db: pog.Connection,
) -> Result(pog.Returned(ListLocationTagsRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use name <- decode.field(1, decode.string)
    use name_en <- decode.field(2, decode.string)
    use icon_name <- decode.field(3, decode.string)
    use icon_variant <- decode.field(4, decode.string)
    decode.success(ListLocationTagsRow(
      id:,
      name:,
      name_en:,
      icon_name:,
      icon_variant:,
    ))
  }

  "-- Lists all location tags ordered by name.
SELECT id,
    name,
    name_en,
    icon_name,
    icon_variant
FROM location_tag
ORDER BY name ASC;
"
  |> pog.query
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `list_locations` query
/// defined in `./src/server/sql/list_locations.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type ListLocationsRow {
  ListLocationsRow(
    id: Uuid,
    name: String,
    name_en: String,
    description: String,
    description_en: String,
    icon_name: String,
    icon_variant: String,
    color: String,
    latitude: Option(Float),
    longitude: Option(Float),
    opening_hours: String,
  )
}

/// Lists all locations ordered by name. `opening_hours` (jsonb) comes back as
/// its JSON text, which Squirrel maps to a String for the model layer to parse.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn list_locations(
  db: pog.Connection,
) -> Result(pog.Returned(ListLocationsRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use name <- decode.field(1, decode.string)
    use name_en <- decode.field(2, decode.string)
    use description <- decode.field(3, decode.string)
    use description_en <- decode.field(4, decode.string)
    use icon_name <- decode.field(5, decode.string)
    use icon_variant <- decode.field(6, decode.string)
    use color <- decode.field(7, decode.string)
    use latitude <- decode.field(8, decode.optional(decode.float))
    use longitude <- decode.field(9, decode.optional(decode.float))
    use opening_hours <- decode.field(10, decode.string)
    decode.success(ListLocationsRow(
      id:,
      name:,
      name_en:,
      description:,
      description_en:,
      icon_name:,
      icon_variant:,
      color:,
      latitude:,
      longitude:,
      opening_hours:,
    ))
  }

  "-- Lists all locations ordered by name. `opening_hours` (jsonb) comes back as
-- its JSON text, which Squirrel maps to a String for the model layer to parse.
SELECT id,
    name,
    name_en,
    description,
    description_en,
    icon_name,
    icon_variant,
    color,
    latitude,
    longitude,
    opening_hours
FROM location
ORDER BY name ASC;
"
  |> pog.query
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `list_recurring_bookings_overview` query
/// defined in `./src/server/sql/list_recurring_bookings_overview.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type ListRecurringBookingsOverviewRow {
  ListRecurringBookingsOverviewRow(
    activity_id: Uuid,
    start_time: Timestamp,
    end_time: Timestamp,
    max_attendees: Option(Int),
    booker_group_id: Option(Int),
    booker_group_name: Option(String),
    group_count: Int,
    booking_count: Int,
  )
}

/// Per-slot booking aggregate for a recurring activity kind ('beach-bus' /
/// 'climbing-wall'), powering the Badbuss / Klättervägg overview. Returns one
/// row per (activity, booker group): `group_count` is that group's participant
/// total and `booking_count` how many bookings it aggregates. An activity with
/// no bookings still yields a single row (LEFT JOIN) with NULL group columns and
/// a zero `booking_count`, so every bookable slot appears. Called-off slots and
/// cancelled bookings are excluded. Restricted to a single day window: `$2`
/// (inclusive) .. `$3` (exclusive), matching the activity list queries. Ordered
/// so a slot's rows are contiguous and groups sort by name.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn list_recurring_bookings_overview(
  db: pog.Connection,
  a_recurring_activity_kind: String,
  arg_2: Timestamp,
  arg_3: Timestamp,
) -> Result(pog.Returned(ListRecurringBookingsOverviewRow), pog.QueryError) {
  let decoder = {
    use activity_id <- decode.field(0, uuid_decoder())
    use start_time <- decode.field(1, pog.timestamp_decoder())
    use end_time <- decode.field(2, pog.timestamp_decoder())
    use max_attendees <- decode.field(3, decode.optional(decode.int))
    use booker_group_id <- decode.field(4, decode.optional(decode.int))
    use booker_group_name <- decode.field(5, decode.optional(decode.string))
    use group_count <- decode.field(6, decode.int)
    use booking_count <- decode.field(7, decode.int)
    decode.success(ListRecurringBookingsOverviewRow(
      activity_id:,
      start_time:,
      end_time:,
      max_attendees:,
      booker_group_id:,
      booker_group_name:,
      group_count:,
      booking_count:,
    ))
  }

  "-- Per-slot booking aggregate for a recurring activity kind ('beach-bus' /
-- 'climbing-wall'), powering the Badbuss / Klättervägg overview. Returns one
-- row per (activity, booker group): `group_count` is that group's participant
-- total and `booking_count` how many bookings it aggregates. An activity with
-- no bookings still yields a single row (LEFT JOIN) with NULL group columns and
-- a zero `booking_count`, so every bookable slot appears. Called-off slots and
-- cancelled bookings are excluded. Restricted to a single day window: `$2`
-- (inclusive) .. `$3` (exclusive), matching the activity list queries. Ordered
-- so a slot's rows are contiguous and groups sort by name.
SELECT
    a.id AS activity_id,
    a.start_time,
    a.end_time,
    a.max_attendees,
    b.booker_group_id,
    b.booker_group_name,
    COALESCE(SUM(b.participant_count), 0)::int AS group_count,
    COUNT(b.id) AS booking_count
FROM activity a
LEFT JOIN booking b ON b.activity_id = a.id
    AND b.cancellation_reason IS NULL
WHERE a.recurring_activity_kind = $1
    AND NOT EXISTS (
        SELECT 1 FROM call_off c WHERE c.activity_id = a.id
    )
    AND a.start_time >= $2
    AND a.start_time < $3
GROUP BY a.id, a.start_time, a.end_time, a.max_attendees,
    b.booker_group_id, b.booker_group_name
ORDER BY a.start_time ASC, a.id, b.booker_group_name ASC;
"
  |> pog.query
  |> pog.parameter(pog.text(a_recurring_activity_kind))
  |> pog.parameter(pog.timestamp(arg_2))
  |> pog.parameter(pog.timestamp(arg_3))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `lock_activity_for_booking` query
/// defined in `./src/server/sql/lock_activity_for_booking.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type LockActivityForBookingRow {
  LockActivityForBookingRow(
    max_attendees: Option(Int),
    start_time: Timestamp,
    end_time: Timestamp,
    booking_opens_at: Option(Timestamp),
  )
}

/// Lock a single activity row for the duration of the transaction and return
/// what the booking create flow validates against: the capacity and the booking
/// window (opens-at override plus start/end times). Locking serialises
/// concurrent bookings for the same activity so the checks can't be raced.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn lock_activity_for_booking(
  db: pog.Connection,
  id: Uuid,
) -> Result(pog.Returned(LockActivityForBookingRow), pog.QueryError) {
  let decoder = {
    use max_attendees <- decode.field(0, decode.optional(decode.int))
    use start_time <- decode.field(1, pog.timestamp_decoder())
    use end_time <- decode.field(2, pog.timestamp_decoder())
    use booking_opens_at <- decode.field(
      3,
      decode.optional(pog.timestamp_decoder()),
    )
    decode.success(LockActivityForBookingRow(
      max_attendees:,
      start_time:,
      end_time:,
      booking_opens_at:,
    ))
  }

  "-- Lock a single activity row for the duration of the transaction and return
-- what the booking create flow validates against: the capacity and the booking
-- window (opens-at override plus start/end times). Locking serialises
-- concurrent bookings for the same activity so the checks can't be raced.
SELECT max_attendees,
    start_time,
    end_time,
    booking_opens_at
FROM activity
WHERE id = $1
FOR UPDATE;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(id)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `restore_booking` query
/// defined in `./src/server/sql/restore_booking.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type RestoreBookingRow {
  RestoreBookingRow(
    id: Uuid,
    user_id: Uuid,
    activity_id: Uuid,
    booker_name: String,
    booker_group_id: Option(Int),
    booker_group_name: Option(String),
    group_free_text: String,
    responsible_name: String,
    phone_number: String,
    participant_count: Int,
    booked_for_other: Bool,
    cancellation_reason: Option(String),
  )
}

/// Restore a cancelled booking to active by clearing its reason. The handler
/// re-checks capacity first — a restored booking occupies spots again.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn restore_booking(
  db: pog.Connection,
  id: Uuid,
) -> Result(pog.Returned(RestoreBookingRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use user_id <- decode.field(1, uuid_decoder())
    use activity_id <- decode.field(2, uuid_decoder())
    use booker_name <- decode.field(3, decode.string)
    use booker_group_id <- decode.field(4, decode.optional(decode.int))
    use booker_group_name <- decode.field(5, decode.optional(decode.string))
    use group_free_text <- decode.field(6, decode.string)
    use responsible_name <- decode.field(7, decode.string)
    use phone_number <- decode.field(8, decode.string)
    use participant_count <- decode.field(9, decode.int)
    use booked_for_other <- decode.field(10, decode.bool)
    use cancellation_reason <- decode.field(11, decode.optional(decode.string))
    decode.success(RestoreBookingRow(
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
      cancellation_reason:,
    ))
  }

  "-- Restore a cancelled booking to active by clearing its reason. The handler
-- re-checks capacity first — a restored booking occupies spots again.
UPDATE booking
SET cancellation_reason = NULL
WHERE id = $1
RETURNING id,
    user_id,
    activity_id,
    booker_name,
    booker_group_id,
    booker_group_name,
    group_free_text,
    responsible_name,
    phone_number,
    participant_count,
    booked_for_other,
    cancellation_reason
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(id)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// Re-syncs an activity's tag links and target groups to the given sets in one
/// statement. A naive delete-all + insert-all can't be a single statement: all
/// data-modifying CTEs share one snapshot, so the inserts wouldn't see the
/// deletes and would collide with still-present rows on any overlap. Instead this
/// deletes only rows no longer wanted and inserts only rows not already present,
/// so the deletes and inserts touch disjoint rows and never conflict. The insert
/// filters read the pre-delete snapshot, which is exactly what we want. Empty
/// arrays delete everything and insert nothing.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn resync_activity_tags_and_target_groups(
  db: pog.Connection,
  activity_id: Uuid,
  arg_2: List(Uuid),
  arg_3: List(TargetGroup),
) -> Result(pog.Returned(Nil), pog.QueryError) {
  let decoder = decode.map(decode.dynamic, fn(_) { Nil })

  "-- Re-syncs an activity's tag links and target groups to the given sets in one
-- statement. A naive delete-all + insert-all can't be a single statement: all
-- data-modifying CTEs share one snapshot, so the inserts wouldn't see the
-- deletes and would collide with still-present rows on any overlap. Instead this
-- deletes only rows no longer wanted and inserts only rows not already present,
-- so the deletes and inserts touch disjoint rows and never conflict. The insert
-- filters read the pre-delete snapshot, which is exactly what we want. Empty
-- arrays delete everything and insert nothing.
WITH desired_tags AS (SELECT unnest($2::uuid[]) AS tag),
desired_target_groups AS (SELECT unnest($3::target_group[]) AS target_group),
deleted_tags AS (
  DELETE FROM activity_tag_activity
  WHERE activity_id = $1
    AND activity_tag_id NOT IN (SELECT tag FROM desired_tags)
),
inserted_tags AS (
  INSERT INTO activity_tag_activity (activity_id, activity_tag_id)
  SELECT $1, tag FROM desired_tags
  WHERE tag NOT IN (
    SELECT activity_tag_id FROM activity_tag_activity WHERE activity_id = $1
  )
),
deleted_target_groups AS (
  DELETE FROM activity_target_group
  WHERE activity_id = $1
    AND target_group NOT IN (SELECT target_group FROM desired_target_groups)
)
INSERT INTO activity_target_group (activity_id, target_group)
SELECT $1, target_group FROM desired_target_groups
WHERE target_group NOT IN (
  SELECT target_group FROM activity_target_group WHERE activity_id = $1
);
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(activity_id)))
  |> pog.parameter(pog.array(
    fn(value) { pog.text(uuid.to_string(value)) },
    arg_2,
  ))
  |> pog.parameter(pog.array(fn(value) { target_group_encoder(value) }, arg_3))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `search_activities` query
/// defined in `./src/server/sql/search_activities.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type SearchActivitiesRow {
  SearchActivitiesRow(
    id: Uuid,
    title: String,
    description: String,
    max_attendees: Option(Int),
    start_time: Timestamp,
    end_time: Timestamp,
    recurring_activity_kind: Option(String),
    location_id: Option(Uuid),
    title_en: String,
    description_en: String,
    booking_opens_at: Option(Timestamp),
  )
}

/// Search for activity titles
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn search_activities(
  db: pog.Connection,
  arg_1: String,
) -> Result(pog.Returned(SearchActivitiesRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use title <- decode.field(1, decode.string)
    use description <- decode.field(2, decode.string)
    use max_attendees <- decode.field(3, decode.optional(decode.int))
    use start_time <- decode.field(4, pog.timestamp_decoder())
    use end_time <- decode.field(5, pog.timestamp_decoder())
    use recurring_activity_kind <- decode.field(
      6,
      decode.optional(decode.string),
    )
    use location_id <- decode.field(7, decode.optional(uuid_decoder()))
    use title_en <- decode.field(8, decode.string)
    use description_en <- decode.field(9, decode.string)
    use booking_opens_at <- decode.field(
      10,
      decode.optional(pog.timestamp_decoder()),
    )
    decode.success(SearchActivitiesRow(
      id:,
      title:,
      description:,
      max_attendees:,
      start_time:,
      end_time:,
      recurring_activity_kind:,
      location_id:,
      title_en:,
      description_en:,
      booking_opens_at:,
    ))
  }

  "-- Search for activity titles
SELECT *
FROM activity
WHERE title ILIKE '%' || $1 || '%'
ORDER BY title;"
  |> pog.query
  |> pog.parameter(pog.text(arg_1))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// Set an activity's per-activity booking-opens-at override. Cleared with
/// clear_activity_booking_opens_at (the column is nullable and squirrel
/// parameters are not, hence the set/clear pair — same pattern as
/// set/clear_activity_location).
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn set_activity_booking_opens_at(
  db: pog.Connection,
  id: Uuid,
  booking_opens_at: Timestamp,
) -> Result(pog.Returned(Nil), pog.QueryError) {
  let decoder = decode.map(decode.dynamic, fn(_) { Nil })

  "-- Set an activity's per-activity booking-opens-at override. Cleared with
-- clear_activity_booking_opens_at (the column is nullable and squirrel
-- parameters are not, hence the set/clear pair — same pattern as
-- set/clear_activity_location).
UPDATE activity
SET booking_opens_at = $2
WHERE id = $1
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(id)))
  |> pog.parameter(pog.timestamp(booking_opens_at))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// Runs the `set_activity_location` query
/// defined in `./src/server/sql/set_activity_location.sql`.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn set_activity_location(
  db: pog.Connection,
  id: Uuid,
  location_id: Uuid,
) -> Result(pog.Returned(Nil), pog.QueryError) {
  let decoder = decode.map(decode.dynamic, fn(_) { Nil })

  "UPDATE activity
SET location_id = $2
WHERE id = $1
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(id)))
  |> pog.parameter(pog.text(uuid.to_string(location_id)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `update_activity_tag` query
/// defined in `./src/server/sql/update_activity_tag.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type UpdateActivityTagRow {
  UpdateActivityTagRow(id: Uuid, name: String, name_en: String)
}

/// Updates an activity tag and returns it.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn update_activity_tag(
  db: pog.Connection,
  id: Uuid,
  arg_2: String,
  name_en: String,
) -> Result(pog.Returned(UpdateActivityTagRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use name <- decode.field(1, decode.string)
    use name_en <- decode.field(2, decode.string)
    decode.success(UpdateActivityTagRow(id:, name:, name_en:))
  }

  "-- Updates an activity tag and returns it.
UPDATE activity_tag
SET name = $2,
    name_en = $3
WHERE id = $1
RETURNING id,
    name,
    name_en;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(id)))
  |> pog.parameter(pog.text(arg_2))
  |> pog.parameter(pog.text(name_en))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `update_activity_with_max_attendees` query
/// defined in `./src/server/sql/update_activity_with_max_attendees.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type UpdateActivityWithMaxAttendeesRow {
  UpdateActivityWithMaxAttendeesRow(
    id: Uuid,
    title: String,
    title_en: String,
    description: String,
    description_en: String,
    max_attendees: Option(Int),
    start_time: Timestamp,
    end_time: Timestamp,
    location_id: Option(Uuid),
    booking_opens_at: Option(Timestamp),
  )
}

/// Runs the `update_activity_with_max_attendees` query
/// defined in `./src/server/sql/update_activity_with_max_attendees.sql`.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn update_activity_with_max_attendees(
  db: pog.Connection,
  id: Uuid,
  arg_2: String,
  arg_3: String,
  arg_4: String,
  arg_5: String,
  arg_6: Int,
  arg_7: Timestamp,
  end_time: Timestamp,
) -> Result(pog.Returned(UpdateActivityWithMaxAttendeesRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use title <- decode.field(1, decode.string)
    use title_en <- decode.field(2, decode.string)
    use description <- decode.field(3, decode.string)
    use description_en <- decode.field(4, decode.string)
    use max_attendees <- decode.field(5, decode.optional(decode.int))
    use start_time <- decode.field(6, pog.timestamp_decoder())
    use end_time <- decode.field(7, pog.timestamp_decoder())
    use location_id <- decode.field(8, decode.optional(uuid_decoder()))
    use booking_opens_at <- decode.field(
      9,
      decode.optional(pog.timestamp_decoder()),
    )
    decode.success(UpdateActivityWithMaxAttendeesRow(
      id:,
      title:,
      title_en:,
      description:,
      description_en:,
      max_attendees:,
      start_time:,
      end_time:,
      location_id:,
      booking_opens_at:,
    ))
  }

  "UPDATE activity
SET title = $2,
    title_en = $3,
    description = $4,
    description_en = $5,
    max_attendees = $6,
    start_time = $7,
    end_time = $8
WHERE id = $1
RETURNING id,
    title,
    title_en,
    description,
    description_en,
    max_attendees,
    start_time,
    end_time,
    location_id,
    booking_opens_at"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(id)))
  |> pog.parameter(pog.text(arg_2))
  |> pog.parameter(pog.text(arg_3))
  |> pog.parameter(pog.text(arg_4))
  |> pog.parameter(pog.text(arg_5))
  |> pog.parameter(pog.int(arg_6))
  |> pog.parameter(pog.timestamp(arg_7))
  |> pog.parameter(pog.timestamp(end_time))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `update_activity_without_max_attendees` query
/// defined in `./src/server/sql/update_activity_without_max_attendees.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type UpdateActivityWithoutMaxAttendeesRow {
  UpdateActivityWithoutMaxAttendeesRow(
    id: Uuid,
    title: String,
    title_en: String,
    description: String,
    description_en: String,
    start_time: Timestamp,
    end_time: Timestamp,
    location_id: Option(Uuid),
    booking_opens_at: Option(Timestamp),
  )
}

/// Runs the `update_activity_without_max_attendees` query
/// defined in `./src/server/sql/update_activity_without_max_attendees.sql`.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn update_activity_without_max_attendees(
  db: pog.Connection,
  id: Uuid,
  arg_2: String,
  arg_3: String,
  arg_4: String,
  arg_5: String,
  arg_6: Timestamp,
  end_time: Timestamp,
) -> Result(pog.Returned(UpdateActivityWithoutMaxAttendeesRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use title <- decode.field(1, decode.string)
    use title_en <- decode.field(2, decode.string)
    use description <- decode.field(3, decode.string)
    use description_en <- decode.field(4, decode.string)
    use start_time <- decode.field(5, pog.timestamp_decoder())
    use end_time <- decode.field(6, pog.timestamp_decoder())
    use location_id <- decode.field(7, decode.optional(uuid_decoder()))
    use booking_opens_at <- decode.field(
      8,
      decode.optional(pog.timestamp_decoder()),
    )
    decode.success(UpdateActivityWithoutMaxAttendeesRow(
      id:,
      title:,
      title_en:,
      description:,
      description_en:,
      start_time:,
      end_time:,
      location_id:,
      booking_opens_at:,
    ))
  }

  "UPDATE activity
SET title = $2,
    title_en = $3,
    description = $4,
    description_en = $5,
    max_attendees = NULL,
    start_time = $6,
    end_time = $7
WHERE id = $1
RETURNING id,
    title,
    title_en,
    description,
    description_en,
    start_time,
    end_time,
    location_id,
    booking_opens_at"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(id)))
  |> pog.parameter(pog.text(arg_2))
  |> pog.parameter(pog.text(arg_3))
  |> pog.parameter(pog.text(arg_4))
  |> pog.parameter(pog.text(arg_5))
  |> pog.parameter(pog.timestamp(arg_6))
  |> pog.parameter(pog.timestamp(end_time))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `update_booking` query
/// defined in `./src/server/sql/update_booking.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type UpdateBookingRow {
  UpdateBookingRow(
    id: Uuid,
    user_id: Uuid,
    activity_id: Uuid,
    booker_name: String,
    booker_group_id: Option(Int),
    booker_group_name: Option(String),
    group_free_text: String,
    responsible_name: String,
    phone_number: String,
    participant_count: Int,
    booked_for_other: Bool,
    cancellation_reason: Option(String),
  )
}

/// Runs the `update_booking` query
/// defined in `./src/server/sql/update_booking.sql`.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn update_booking(
  db: pog.Connection,
  id: Uuid,
  arg_2: String,
  arg_3: String,
  arg_4: String,
  participant_count: Int,
) -> Result(pog.Returned(UpdateBookingRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use user_id <- decode.field(1, uuid_decoder())
    use activity_id <- decode.field(2, uuid_decoder())
    use booker_name <- decode.field(3, decode.string)
    use booker_group_id <- decode.field(4, decode.optional(decode.int))
    use booker_group_name <- decode.field(5, decode.optional(decode.string))
    use group_free_text <- decode.field(6, decode.string)
    use responsible_name <- decode.field(7, decode.string)
    use phone_number <- decode.field(8, decode.string)
    use participant_count <- decode.field(9, decode.int)
    use booked_for_other <- decode.field(10, decode.bool)
    use cancellation_reason <- decode.field(11, decode.optional(decode.string))
    decode.success(UpdateBookingRow(
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
      cancellation_reason:,
    ))
  }

  "UPDATE booking
SET group_free_text = $2,
    responsible_name = $3,
    phone_number = $4,
    participant_count = $5
WHERE id = $1
RETURNING id,
    user_id,
    activity_id,
    booker_name,
    booker_group_id,
    booker_group_name,
    group_free_text,
    responsible_name,
    phone_number,
    participant_count,
    booked_for_other,
    cancellation_reason
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(id)))
  |> pog.parameter(pog.text(arg_2))
  |> pog.parameter(pog.text(arg_3))
  |> pog.parameter(pog.text(arg_4))
  |> pog.parameter(pog.int(participant_count))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `update_location_tag` query
/// defined in `./src/server/sql/update_location_tag.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type UpdateLocationTagRow {
  UpdateLocationTagRow(
    id: Uuid,
    name: String,
    name_en: String,
    icon_name: String,
    icon_variant: String,
  )
}

/// Updates a location tag and returns it.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn update_location_tag(
  db: pog.Connection,
  id: Uuid,
  arg_2: String,
  arg_3: String,
  arg_4: String,
  icon_variant: String,
) -> Result(pog.Returned(UpdateLocationTagRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use name <- decode.field(1, decode.string)
    use name_en <- decode.field(2, decode.string)
    use icon_name <- decode.field(3, decode.string)
    use icon_variant <- decode.field(4, decode.string)
    decode.success(UpdateLocationTagRow(
      id:,
      name:,
      name_en:,
      icon_name:,
      icon_variant:,
    ))
  }

  "-- Updates a location tag and returns it.
UPDATE location_tag
SET name = $2,
    name_en = $3,
    icon_name = $4,
    icon_variant = $5
WHERE id = $1
RETURNING id,
    name,
    name_en,
    icon_name,
    icon_variant;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(id)))
  |> pog.parameter(pog.text(arg_2))
  |> pog.parameter(pog.text(arg_3))
  |> pog.parameter(pog.text(arg_4))
  |> pog.parameter(pog.text(icon_variant))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `update_location_with_coordinates` query
/// defined in `./src/server/sql/update_location_with_coordinates.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type UpdateLocationWithCoordinatesRow {
  UpdateLocationWithCoordinatesRow(
    id: Uuid,
    name: String,
    name_en: String,
    description: String,
    description_en: String,
    icon_name: String,
    icon_variant: String,
    color: String,
    latitude: Option(Float),
    longitude: Option(Float),
    opening_hours: String,
  )
}

/// Updates a location, setting its coordinates, and returns it. opening_hours
/// is sent as JSON text; the parameter type is inferred as jsonb from the
/// target column. Squirrel cannot generate optional query parameters, so
/// clearing the coordinates goes through the _without_coordinates variant.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn update_location_with_coordinates(
  db: pog.Connection,
  id: Uuid,
  arg_2: String,
  arg_3: String,
  arg_4: String,
  arg_5: String,
  arg_6: String,
  arg_7: String,
  arg_8: String,
  arg_9: Float,
  arg_10: Float,
  opening_hours: Json,
) -> Result(pog.Returned(UpdateLocationWithCoordinatesRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use name <- decode.field(1, decode.string)
    use name_en <- decode.field(2, decode.string)
    use description <- decode.field(3, decode.string)
    use description_en <- decode.field(4, decode.string)
    use icon_name <- decode.field(5, decode.string)
    use icon_variant <- decode.field(6, decode.string)
    use color <- decode.field(7, decode.string)
    use latitude <- decode.field(8, decode.optional(decode.float))
    use longitude <- decode.field(9, decode.optional(decode.float))
    use opening_hours <- decode.field(10, decode.string)
    decode.success(UpdateLocationWithCoordinatesRow(
      id:,
      name:,
      name_en:,
      description:,
      description_en:,
      icon_name:,
      icon_variant:,
      color:,
      latitude:,
      longitude:,
      opening_hours:,
    ))
  }

  "-- Updates a location, setting its coordinates, and returns it. opening_hours
-- is sent as JSON text; the parameter type is inferred as jsonb from the
-- target column. Squirrel cannot generate optional query parameters, so
-- clearing the coordinates goes through the _without_coordinates variant.
UPDATE location
SET name = $2,
    name_en = $3,
    description = $4,
    description_en = $5,
    icon_name = $6,
    icon_variant = $7,
    color = $8,
    latitude = $9,
    longitude = $10,
    opening_hours = $11
WHERE id = $1
RETURNING id,
    name,
    name_en,
    description,
    description_en,
    icon_name,
    icon_variant,
    color,
    latitude,
    longitude,
    opening_hours;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(id)))
  |> pog.parameter(pog.text(arg_2))
  |> pog.parameter(pog.text(arg_3))
  |> pog.parameter(pog.text(arg_4))
  |> pog.parameter(pog.text(arg_5))
  |> pog.parameter(pog.text(arg_6))
  |> pog.parameter(pog.text(arg_7))
  |> pog.parameter(pog.text(arg_8))
  |> pog.parameter(pog.float(arg_9))
  |> pog.parameter(pog.float(arg_10))
  |> pog.parameter(pog.text(json.to_string(opening_hours)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `update_location_without_coordinates` query
/// defined in `./src/server/sql/update_location_without_coordinates.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type UpdateLocationWithoutCoordinatesRow {
  UpdateLocationWithoutCoordinatesRow(
    id: Uuid,
    name: String,
    name_en: String,
    description: String,
    description_en: String,
    icon_name: String,
    icon_variant: String,
    color: String,
    latitude: Option(Float),
    longitude: Option(Float),
    opening_hours: String,
  )
}

/// Updates a location, clearing its coordinates, and returns it. opening_hours
/// is sent as JSON text; the parameter type is inferred as jsonb from the
/// target column. Squirrel cannot generate optional query parameters, so the
/// NULL coordinates are literals here rather than parameters of the
/// _with_coordinates variant.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn update_location_without_coordinates(
  db: pog.Connection,
  id: Uuid,
  arg_2: String,
  arg_3: String,
  arg_4: String,
  arg_5: String,
  arg_6: String,
  arg_7: String,
  arg_8: String,
  opening_hours: Json,
) -> Result(pog.Returned(UpdateLocationWithoutCoordinatesRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use name <- decode.field(1, decode.string)
    use name_en <- decode.field(2, decode.string)
    use description <- decode.field(3, decode.string)
    use description_en <- decode.field(4, decode.string)
    use icon_name <- decode.field(5, decode.string)
    use icon_variant <- decode.field(6, decode.string)
    use color <- decode.field(7, decode.string)
    use latitude <- decode.field(8, decode.optional(decode.float))
    use longitude <- decode.field(9, decode.optional(decode.float))
    use opening_hours <- decode.field(10, decode.string)
    decode.success(UpdateLocationWithoutCoordinatesRow(
      id:,
      name:,
      name_en:,
      description:,
      description_en:,
      icon_name:,
      icon_variant:,
      color:,
      latitude:,
      longitude:,
      opening_hours:,
    ))
  }

  "-- Updates a location, clearing its coordinates, and returns it. opening_hours
-- is sent as JSON text; the parameter type is inferred as jsonb from the
-- target column. Squirrel cannot generate optional query parameters, so the
-- NULL coordinates are literals here rather than parameters of the
-- _with_coordinates variant.
UPDATE location
SET name = $2,
    name_en = $3,
    description = $4,
    description_en = $5,
    icon_name = $6,
    icon_variant = $7,
    color = $8,
    latitude = NULL,
    longitude = NULL,
    opening_hours = $9
WHERE id = $1
RETURNING id,
    name,
    name_en,
    description,
    description_en,
    icon_name,
    icon_variant,
    color,
    latitude,
    longitude,
    opening_hours;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(id)))
  |> pog.parameter(pog.text(arg_2))
  |> pog.parameter(pog.text(arg_3))
  |> pog.parameter(pog.text(arg_4))
  |> pog.parameter(pog.text(arg_5))
  |> pog.parameter(pog.text(arg_6))
  |> pog.parameter(pog.text(arg_7))
  |> pog.parameter(pog.text(arg_8))
  |> pog.parameter(pog.text(json.to_string(opening_hours)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `upsert_user` query
/// defined in `./src/server/sql/upsert_user.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type UpsertUserRow {
  UpsertUserRow(id: Uuid)
}

/// Creates the user row for a JWT-authenticated user on first sight, so
/// handlers can write rows with user_id foreign keys.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn upsert_user(
  db: pog.Connection,
  arg_1: Uuid,
) -> Result(pog.Returned(UpsertUserRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    decode.success(UpsertUserRow(id:))
  }

  "-- Creates the user row for a JWT-authenticated user on first sight, so
-- handlers can write rows with user_id foreign keys.
INSERT INTO \"user\" (id)
VALUES ($1) ON CONFLICT (id) DO NOTHING
RETURNING id
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

// --- Enums -------------------------------------------------------------------

/// Corresponds to the Postgres `target_group` enum.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type TargetGroup {
  Rover
  Utmanare
  Aventyrare
  Upptackare
  Sparare
}

fn target_group_decoder() -> decode.Decoder(TargetGroup) {
  use target_group <- decode.then(decode.string)
  case target_group {
    "rover" -> decode.success(Rover)
    "utmanare" -> decode.success(Utmanare)
    "aventyrare" -> decode.success(Aventyrare)
    "upptackare" -> decode.success(Upptackare)
    "sparare" -> decode.success(Sparare)
    _ -> decode.failure(Rover, "TargetGroup")
  }
}

fn target_group_encoder(target_group) -> pog.Value {
  case target_group {
    Rover -> "rover"
    Utmanare -> "utmanare"
    Aventyrare -> "aventyrare"
    Upptackare -> "upptackare"
    Sparare -> "sparare"
  }
  |> pog.text
}

// --- Encoding/decoding utils -------------------------------------------------

/// A decoder to decode `Uuid`s coming from a Postgres query.
///
fn uuid_decoder() {
  use bit_array <- decode.then(decode.bit_array)
  case uuid.from_bit_array(bit_array) {
    Ok(uuid) -> decode.success(uuid)
    Error(_) -> decode.failure(uuid.v7(), "Uuid")
  }
}

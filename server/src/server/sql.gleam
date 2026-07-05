//// This module contains the code to run the sql queries defined in
//// `./src/server/sql`.
//// > 🐿️ This module was generated automatically using v4.6.0 of
//// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
////

import gleam/dynamic/decode
import gleam/json.{type Json}
import gleam/option.{type Option}
import gleam/time/timestamp.{type Timestamp}
import pog
import youid/uuid.{type Uuid}

/// A row you get from running the `count_favourites_by_activity` query
/// defined in `./src/server/sql/count_favourites_by_activity.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type CountFavouritesByActivityRow {
  CountFavouritesByActivityRow(favourite_count: Int)
}

/// Runs the `count_favourites_by_activity` query
/// defined in `./src/server/sql/count_favourites_by_activity.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn count_favourites_by_activity(
  db: pog.Connection,
  arg_1: Uuid,
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
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `create_activity_with_max_attendees` query
/// defined in `./src/server/sql/create_activity_with_max_attendees.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type CreateActivityWithMaxAttendeesRow {
  CreateActivityWithMaxAttendeesRow(
    id: Uuid,
    title: String,
    description: String,
    max_attendees: Option(Int),
    start_time: Timestamp,
    end_time: Timestamp,
    location_id: Option(Uuid),
  )
}

/// Runs the `create_activity_with_max_attendees` query
/// defined in `./src/server/sql/create_activity_with_max_attendees.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn create_activity_with_max_attendees(
  db: pog.Connection,
  arg_1: Uuid,
  arg_2: String,
  arg_3: String,
  arg_4: Int,
  arg_5: Timestamp,
  arg_6: Timestamp,
) -> Result(pog.Returned(CreateActivityWithMaxAttendeesRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use title <- decode.field(1, decode.string)
    use description <- decode.field(2, decode.string)
    use max_attendees <- decode.field(3, decode.optional(decode.int))
    use start_time <- decode.field(4, pog.timestamp_decoder())
    use end_time <- decode.field(5, pog.timestamp_decoder())
    use location_id <- decode.field(6, decode.optional(uuid_decoder()))
    decode.success(CreateActivityWithMaxAttendeesRow(
      id:,
      title:,
      description:,
      max_attendees:,
      start_time:,
      end_time:,
      location_id:,
    ))
  }

  "INSERT INTO activity (
        id,
        title,
        description,
        max_attendees,
        start_time,
        end_time
    )
VALUES ($1, $2, $3, $4, $5, $6)
RETURNING id,
    title,
    description,
    max_attendees,
    start_time,
    end_time,
    location_id"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.parameter(pog.text(arg_2))
  |> pog.parameter(pog.text(arg_3))
  |> pog.parameter(pog.int(arg_4))
  |> pog.parameter(pog.timestamp(arg_5))
  |> pog.parameter(pog.timestamp(arg_6))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `create_activity_without_max_attendees` query
/// defined in `./src/server/sql/create_activity_without_max_attendees.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type CreateActivityWithoutMaxAttendeesRow {
  CreateActivityWithoutMaxAttendeesRow(
    id: Uuid,
    title: String,
    description: String,
    start_time: Timestamp,
    end_time: Timestamp,
    location_id: Option(Uuid),
  )
}

/// Runs the `create_activity_without_max_attendees` query
/// defined in `./src/server/sql/create_activity_without_max_attendees.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn create_activity_without_max_attendees(
  db: pog.Connection,
  arg_1: Uuid,
  arg_2: String,
  arg_3: String,
  arg_4: Timestamp,
  arg_5: Timestamp,
) -> Result(pog.Returned(CreateActivityWithoutMaxAttendeesRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use title <- decode.field(1, decode.string)
    use description <- decode.field(2, decode.string)
    use start_time <- decode.field(3, pog.timestamp_decoder())
    use end_time <- decode.field(4, pog.timestamp_decoder())
    use location_id <- decode.field(5, decode.optional(uuid_decoder()))
    decode.success(CreateActivityWithoutMaxAttendeesRow(
      id:,
      title:,
      description:,
      start_time:,
      end_time:,
      location_id:,
    ))
  }

  "INSERT INTO activity (
        id,
        title,
        description,
        max_attendees,
        start_time,
        end_time
    )
VALUES ($1, $2, $3, NULL, $4, $5)
RETURNING id,
    title,
    description,
    start_time,
    end_time,
    location_id"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.parameter(pog.text(arg_2))
  |> pog.parameter(pog.text(arg_3))
  |> pog.parameter(pog.timestamp(arg_4))
  |> pog.parameter(pog.timestamp(arg_5))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `create_booking` query
/// defined in `./src/server/sql/create_booking.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type CreateBookingRow {
  CreateBookingRow(
    id: Uuid,
    user_id: Uuid,
    activity_id: Uuid,
    booker_group_id: Int,
    booker_group_name: String,
    group_free_text: String,
    responsible_name: String,
    phone_number: String,
    participant_count: Int,
  )
}

/// Runs the `create_booking` query
/// defined in `./src/server/sql/create_booking.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn create_booking(
  db: pog.Connection,
  arg_1: Uuid,
  arg_2: Uuid,
  arg_3: Uuid,
  arg_4: Int,
  arg_5: String,
  arg_6: String,
  arg_7: String,
  arg_8: String,
  arg_9: Int,
) -> Result(pog.Returned(CreateBookingRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use user_id <- decode.field(1, uuid_decoder())
    use activity_id <- decode.field(2, uuid_decoder())
    use booker_group_id <- decode.field(3, decode.int)
    use booker_group_name <- decode.field(4, decode.string)
    use group_free_text <- decode.field(5, decode.string)
    use responsible_name <- decode.field(6, decode.string)
    use phone_number <- decode.field(7, decode.string)
    use participant_count <- decode.field(8, decode.int)
    decode.success(CreateBookingRow(
      id:,
      user_id:,
      activity_id:,
      booker_group_id:,
      booker_group_name:,
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
        booker_group_id,
        booker_group_name,
        group_free_text,
        responsible_name,
        phone_number,
        participant_count
    )
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
RETURNING id,
    user_id,
    activity_id,
    booker_group_id,
    booker_group_name,
    group_free_text,
    responsible_name,
    phone_number,
    participant_count
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.parameter(pog.text(uuid.to_string(arg_2)))
  |> pog.parameter(pog.text(uuid.to_string(arg_3)))
  |> pog.parameter(pog.int(arg_4))
  |> pog.parameter(pog.text(arg_5))
  |> pog.parameter(pog.text(arg_6))
  |> pog.parameter(pog.text(arg_7))
  |> pog.parameter(pog.text(arg_8))
  |> pog.parameter(pog.int(arg_9))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `create_favourite` query
/// defined in `./src/server/sql/create_favourite.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type CreateFavouriteRow {
  CreateFavouriteRow(id: Uuid, user_id: Uuid, activity_id: Uuid)
}

/// Runs the `create_favourite` query
/// defined in `./src/server/sql/create_favourite.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
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

/// A row you get from running the `create_location` query
/// defined in `./src/server/sql/create_location.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type CreateLocationRow {
  CreateLocationRow(
    id: Uuid,
    name: String,
    name_en: String,
    description: String,
    description_en: String,
    icon_name: String,
    icon_variant: String,
    color: String,
    latitude: Float,
    longitude: Float,
    opening_hours: String,
  )
}

/// Creates a location and returns it. opening_hours is sent as JSON text; the
/// parameter type is inferred as jsonb from the target column.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn create_location(
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
) -> Result(pog.Returned(CreateLocationRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use name <- decode.field(1, decode.string)
    use name_en <- decode.field(2, decode.string)
    use description <- decode.field(3, decode.string)
    use description_en <- decode.field(4, decode.string)
    use icon_name <- decode.field(5, decode.string)
    use icon_variant <- decode.field(6, decode.string)
    use color <- decode.field(7, decode.string)
    use latitude <- decode.field(8, decode.float)
    use longitude <- decode.field(9, decode.float)
    use opening_hours <- decode.field(10, decode.string)
    decode.success(CreateLocationRow(
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

  "-- Creates a location and returns it. opening_hours is sent as JSON text; the
-- parameter type is inferred as jsonb from the target column.
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

/// A row you get from running the `create_location_tag` query
/// defined in `./src/server/sql/create_location_tag.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
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
/// > 🐿️ This function was generated automatically using v4.6.0 of
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

/// A row you get from running the `delete_activity` query
/// defined in `./src/server/sql/delete_activity.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type DeleteActivityRow {
  DeleteActivityRow(id: Uuid)
}

/// Runs the `delete_activity` query
/// defined in `./src/server/sql/delete_activity.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn delete_activity(
  db: pog.Connection,
  arg_1: Uuid,
) -> Result(pog.Returned(DeleteActivityRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    decode.success(DeleteActivityRow(id:))
  }

  "DELETE FROM activity
WHERE id = $1
RETURNING id"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `delete_booking` query
/// defined in `./src/server/sql/delete_booking.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type DeleteBookingRow {
  DeleteBookingRow(id: Uuid)
}

/// Runs the `delete_booking` query
/// defined in `./src/server/sql/delete_booking.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn delete_booking(
  db: pog.Connection,
  arg_1: Uuid,
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
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `delete_favourite` query
/// defined in `./src/server/sql/delete_favourite.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type DeleteFavouriteRow {
  DeleteFavouriteRow(id: Uuid)
}

/// Runs the `delete_favourite` query
/// defined in `./src/server/sql/delete_favourite.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn delete_favourite(
  db: pog.Connection,
  arg_1: Uuid,
  arg_2: Uuid,
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
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.parameter(pog.text(uuid.to_string(arg_2)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `delete_location` query
/// defined in `./src/server/sql/delete_location.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type DeleteLocationRow {
  DeleteLocationRow(id: Uuid)
}

/// Deletes a location, returning its id if it existed.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn delete_location(
  db: pog.Connection,
  arg_1: Uuid,
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
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// Removes all location links for a tag (used before deleting the tag).
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
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
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type DeleteLocationTagRow {
  DeleteLocationTagRow(id: Uuid)
}

/// Deletes a location tag, returning its id if it existed.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn delete_location_tag(
  db: pog.Connection,
  arg_1: Uuid,
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
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// Removes all tag links for a location (used when re-syncing or deleting).
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
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
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
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
  )
}

/// Runs the `get_activities_by_start_time` query
/// defined in `./src/server/sql/get_activities_by_start_time.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
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
    decode.success(GetActivitiesByStartTimeRow(
      id:,
      title:,
      description:,
      max_attendees:,
      start_time:,
      end_time:,
      recurring_activity_kind:,
      location_id:,
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
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
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
  )
}

/// Runs the `get_activities_by_title` query
/// defined in `./src/server/sql/get_activities_by_title.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
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
    decode.success(GetActivitiesByTitleRow(
      id:,
      title:,
      description:,
      max_attendees:,
      start_time:,
      end_time:,
      recurring_activity_kind:,
      location_id:,
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
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
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
  )
}

/// Runs the `get_activity` query
/// defined in `./src/server/sql/get_activity.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
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
    decode.success(GetActivityRow(
      id:,
      title:,
      description:,
      max_attendees:,
      start_time:,
      end_time:,
      recurring_activity_kind:,
      location_id:,
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
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type GetActivitySpotsRow {
  GetActivitySpotsRow(spots_booked: Int)
}

/// Booked spot count for a single activity. The aggregate has no GROUP BY, so
/// it always returns exactly one row (0 when the activity has no bookings).
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn get_activity_spots(
  db: pog.Connection,
  arg_1: Uuid,
) -> Result(pog.Returned(GetActivitySpotsRow), pog.QueryError) {
  let decoder = {
    use spots_booked <- decode.field(0, decode.int)
    decode.success(GetActivitySpotsRow(spots_booked:))
  }

  "-- Booked spot count for a single activity. The aggregate has no GROUP BY, so
-- it always returns exactly one row (0 when the activity has no bookings).
SELECT COALESCE(SUM(participant_count), 0) AS spots_booked
FROM booking
WHERE activity_id = $1
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `get_booking` query
/// defined in `./src/server/sql/get_booking.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type GetBookingRow {
  GetBookingRow(
    id: Uuid,
    user_id: Uuid,
    activity_id: Uuid,
    booker_group_id: Int,
    booker_group_name: String,
    group_free_text: String,
    responsible_name: String,
    phone_number: String,
    participant_count: Int,
  )
}

/// Runs the `get_booking` query
/// defined in `./src/server/sql/get_booking.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn get_booking(
  db: pog.Connection,
  arg_1: Uuid,
) -> Result(pog.Returned(GetBookingRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use user_id <- decode.field(1, uuid_decoder())
    use activity_id <- decode.field(2, uuid_decoder())
    use booker_group_id <- decode.field(3, decode.int)
    use booker_group_name <- decode.field(4, decode.string)
    use group_free_text <- decode.field(5, decode.string)
    use responsible_name <- decode.field(6, decode.string)
    use phone_number <- decode.field(7, decode.string)
    use participant_count <- decode.field(8, decode.int)
    decode.success(GetBookingRow(
      id:,
      user_id:,
      activity_id:,
      booker_group_id:,
      booker_group_name:,
      group_free_text:,
      responsible_name:,
      phone_number:,
      participant_count:,
    ))
  }

  "SELECT id,
    user_id,
    activity_id,
    booker_group_id,
    booker_group_name,
    group_free_text,
    responsible_name,
    phone_number,
    participant_count
FROM booking
WHERE id = $1
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `get_booking_by_user_and_activity` query
/// defined in `./src/server/sql/get_booking_by_user_and_activity.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type GetBookingByUserAndActivityRow {
  GetBookingByUserAndActivityRow(id: Uuid)
}

/// Runs the `get_booking_by_user_and_activity` query
/// defined in `./src/server/sql/get_booking_by_user_and_activity.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn get_booking_by_user_and_activity(
  db: pog.Connection,
  arg_1: Uuid,
  arg_2: Uuid,
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
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.parameter(pog.text(uuid.to_string(arg_2)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `get_bookings_by_activity` query
/// defined in `./src/server/sql/get_bookings_by_activity.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type GetBookingsByActivityRow {
  GetBookingsByActivityRow(
    id: Uuid,
    user_id: Uuid,
    activity_id: Uuid,
    booker_group_id: Int,
    booker_group_name: String,
    group_free_text: String,
    responsible_name: String,
    phone_number: String,
    participant_count: Int,
  )
}

/// Runs the `get_bookings_by_activity` query
/// defined in `./src/server/sql/get_bookings_by_activity.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn get_bookings_by_activity(
  db: pog.Connection,
  arg_1: Uuid,
  arg_2: Int,
  arg_3: Int,
) -> Result(pog.Returned(GetBookingsByActivityRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use user_id <- decode.field(1, uuid_decoder())
    use activity_id <- decode.field(2, uuid_decoder())
    use booker_group_id <- decode.field(3, decode.int)
    use booker_group_name <- decode.field(4, decode.string)
    use group_free_text <- decode.field(5, decode.string)
    use responsible_name <- decode.field(6, decode.string)
    use phone_number <- decode.field(7, decode.string)
    use participant_count <- decode.field(8, decode.int)
    decode.success(GetBookingsByActivityRow(
      id:,
      user_id:,
      activity_id:,
      booker_group_id:,
      booker_group_name:,
      group_free_text:,
      responsible_name:,
      phone_number:,
      participant_count:,
    ))
  }

  "SELECT id,
    user_id,
    activity_id,
    booker_group_id,
    booker_group_name,
    group_free_text,
    responsible_name,
    phone_number,
    participant_count
FROM booking
WHERE activity_id = $1
ORDER BY responsible_name ASC
LIMIT $2
OFFSET $3
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.parameter(pog.int(arg_2))
  |> pog.parameter(pog.int(arg_3))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `get_bookings_by_user` query
/// defined in `./src/server/sql/get_bookings_by_user.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type GetBookingsByUserRow {
  GetBookingsByUserRow(
    id: Uuid,
    user_id: Uuid,
    activity_id: Uuid,
    booker_group_id: Int,
    booker_group_name: String,
    group_free_text: String,
    responsible_name: String,
    phone_number: String,
    participant_count: Int,
  )
}

/// Runs the `get_bookings_by_user` query
/// defined in `./src/server/sql/get_bookings_by_user.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn get_bookings_by_user(
  db: pog.Connection,
  arg_1: Uuid,
) -> Result(pog.Returned(GetBookingsByUserRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use user_id <- decode.field(1, uuid_decoder())
    use activity_id <- decode.field(2, uuid_decoder())
    use booker_group_id <- decode.field(3, decode.int)
    use booker_group_name <- decode.field(4, decode.string)
    use group_free_text <- decode.field(5, decode.string)
    use responsible_name <- decode.field(6, decode.string)
    use phone_number <- decode.field(7, decode.string)
    use participant_count <- decode.field(8, decode.int)
    decode.success(GetBookingsByUserRow(
      id:,
      user_id:,
      activity_id:,
      booker_group_id:,
      booker_group_name:,
      group_free_text:,
      responsible_name:,
      phone_number:,
      participant_count:,
    ))
  }

  "SELECT id,
    user_id,
    activity_id,
    booker_group_id,
    booker_group_name,
    group_free_text,
    responsible_name,
    phone_number,
    participant_count
FROM booking
WHERE user_id = $1
ORDER BY id;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `get_favourites_by_user` query
/// defined in `./src/server/sql/get_favourites_by_user.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type GetFavouritesByUserRow {
  GetFavouritesByUserRow(id: Uuid, user_id: Uuid, activity_id: Uuid)
}

/// Runs the `get_favourites_by_user` query
/// defined in `./src/server/sql/get_favourites_by_user.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn get_favourites_by_user(
  db: pog.Connection,
  arg_1: Uuid,
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
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `get_location` query
/// defined in `./src/server/sql/get_location.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
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
    latitude: Float,
    longitude: Float,
    opening_hours: String,
  )
}

/// Gets a single location by id.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
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
    use latitude <- decode.field(8, decode.float)
    use longitude <- decode.field(9, decode.float)
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
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
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
/// > 🐿️ This function was generated automatically using v4.6.0 of
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
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type GetLocationTagIdsRow {
  GetLocationTagIdsRow(location_tag_id: Uuid)
}

/// Lists the tag ids linked to a location.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
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

/// Links a location to the given tag ids in one statement. An empty array
/// inserts no rows.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
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
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
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
  )
}

/// Runs the `list_activities_by_start_time` query
/// defined in `./src/server/sql/list_activities_by_start_time.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn list_activities_by_start_time(
  db: pog.Connection,
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
    decode.success(ListActivitiesByStartTimeRow(
      id:,
      title:,
      description:,
      max_attendees:,
      start_time:,
      end_time:,
      recurring_activity_kind:,
      location_id:,
    ))
  }

  "SELECT *
FROM activity
WHERE recurring_activity_kind IS NULL
ORDER BY start_time ASC;
"
  |> pog.query
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `list_activities_by_title` query
/// defined in `./src/server/sql/list_activities_by_title.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
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
  )
}

/// Runs the `list_activities_by_title` query
/// defined in `./src/server/sql/list_activities_by_title.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn list_activities_by_title(
  db: pog.Connection,
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
    decode.success(ListActivitiesByTitleRow(
      id:,
      title:,
      description:,
      max_attendees:,
      start_time:,
      end_time:,
      recurring_activity_kind:,
      location_id:,
    ))
  }

  "SELECT *
FROM activity
WHERE recurring_activity_kind IS NULL
ORDER BY title ASC;
"
  |> pog.query
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `list_activity_spots` query
/// defined in `./src/server/sql/list_activity_spots.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type ListActivitySpotsRow {
  ListActivitySpotsRow(activity_id: Uuid, spots_booked: Int)
}

/// Booked spot count per activity. LEFT JOIN so activities with no bookings
/// return 0 (not absent) — the client distinguishes known-zero from unknown.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
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
SELECT activity.id AS activity_id,
    COALESCE(SUM(booking.participant_count), 0) AS spots_booked
FROM activity
    LEFT JOIN booking ON booking.activity_id = activity.id
GROUP BY activity.id
"
  |> pog.query
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `list_climbing_wall_activities` query
/// defined in `./src/server/sql/list_climbing_wall_activities.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
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
  )
}

/// Runs the `list_climbing_wall_activities` query
/// defined in `./src/server/sql/list_climbing_wall_activities.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn list_climbing_wall_activities(
  db: pog.Connection,
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
    decode.success(ListClimbingWallActivitiesRow(
      id:,
      title:,
      description:,
      max_attendees:,
      start_time:,
      end_time:,
      recurring_activity_kind:,
      location_id:,
    ))
  }

  "SELECT *
FROM activity
WHERE recurring_activity_kind = 'climbing-wall'
ORDER BY start_time ASC;
"
  |> pog.query
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `list_favourited_activities` query
/// defined in `./src/server/sql/list_favourited_activities.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
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
  )
}

/// Runs the `list_favourited_activities` query
/// defined in `./src/server/sql/list_favourited_activities.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
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
    decode.success(ListFavouritedActivitiesRow(
      id:,
      title:,
      description:,
      max_attendees:,
      start_time:,
      end_time:,
      recurring_activity_kind:,
      location_id:,
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
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type ListLocationTagLinksRow {
  ListLocationTagLinksRow(location_id: Uuid, location_tag_id: Uuid)
}

/// Lists every location-to-tag link. Joined to locations in the handler to embed
/// each location's tag ids without an array aggregation.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
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
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
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
/// > 🐿️ This function was generated automatically using v4.6.0 of
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
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
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
    latitude: Float,
    longitude: Float,
    opening_hours: String,
  )
}

/// Lists all locations ordered by name. `opening_hours` (jsonb) comes back as
/// its JSON text, which Squirrel maps to a String for the model layer to parse.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
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
    use latitude <- decode.field(8, decode.float)
    use longitude <- decode.field(9, decode.float)
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

/// A row you get from running the `list_swim_bus_activities` query
/// defined in `./src/server/sql/list_swim_bus_activities.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type ListSwimBusActivitiesRow {
  ListSwimBusActivitiesRow(
    id: Uuid,
    title: String,
    description: String,
    max_attendees: Option(Int),
    start_time: Timestamp,
    end_time: Timestamp,
    recurring_activity_kind: Option(String),
    location_id: Option(Uuid),
  )
}

/// Runs the `list_swim_bus_activities` query
/// defined in `./src/server/sql/list_swim_bus_activities.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn list_swim_bus_activities(
  db: pog.Connection,
) -> Result(pog.Returned(ListSwimBusActivitiesRow), pog.QueryError) {
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
    decode.success(ListSwimBusActivitiesRow(
      id:,
      title:,
      description:,
      max_attendees:,
      start_time:,
      end_time:,
      recurring_activity_kind:,
      location_id:,
    ))
  }

  "SELECT *
FROM activity
WHERE recurring_activity_kind = 'swim-bus'
ORDER BY start_time ASC;
"
  |> pog.query
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `search_activities` query
/// defined in `./src/server/sql/search_activities.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
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
  )
}

/// Search for activity titles
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
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
    decode.success(SearchActivitiesRow(
      id:,
      title:,
      description:,
      max_attendees:,
      start_time:,
      end_time:,
      recurring_activity_kind:,
      location_id:,
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

/// A row you get from running the `update_activity_with_max_attendees` query
/// defined in `./src/server/sql/update_activity_with_max_attendees.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type UpdateActivityWithMaxAttendeesRow {
  UpdateActivityWithMaxAttendeesRow(
    id: Uuid,
    title: String,
    description: String,
    max_attendees: Option(Int),
    start_time: Timestamp,
    end_time: Timestamp,
    location_id: Option(Uuid),
  )
}

/// Runs the `update_activity_with_max_attendees` query
/// defined in `./src/server/sql/update_activity_with_max_attendees.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn update_activity_with_max_attendees(
  db: pog.Connection,
  arg_1: Uuid,
  arg_2: String,
  arg_3: String,
  arg_4: Int,
  arg_5: Timestamp,
  arg_6: Timestamp,
) -> Result(pog.Returned(UpdateActivityWithMaxAttendeesRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use title <- decode.field(1, decode.string)
    use description <- decode.field(2, decode.string)
    use max_attendees <- decode.field(3, decode.optional(decode.int))
    use start_time <- decode.field(4, pog.timestamp_decoder())
    use end_time <- decode.field(5, pog.timestamp_decoder())
    use location_id <- decode.field(6, decode.optional(uuid_decoder()))
    decode.success(UpdateActivityWithMaxAttendeesRow(
      id:,
      title:,
      description:,
      max_attendees:,
      start_time:,
      end_time:,
      location_id:,
    ))
  }

  "UPDATE activity
SET title = $2,
    description = $3,
    max_attendees = $4,
    start_time = $5,
    end_time = $6
WHERE id = $1
RETURNING id,
    title,
    description,
    max_attendees,
    start_time,
    end_time,
    location_id"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.parameter(pog.text(arg_2))
  |> pog.parameter(pog.text(arg_3))
  |> pog.parameter(pog.int(arg_4))
  |> pog.parameter(pog.timestamp(arg_5))
  |> pog.parameter(pog.timestamp(arg_6))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `update_activity_without_max_attendees` query
/// defined in `./src/server/sql/update_activity_without_max_attendees.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type UpdateActivityWithoutMaxAttendeesRow {
  UpdateActivityWithoutMaxAttendeesRow(
    id: Uuid,
    title: String,
    description: String,
    start_time: Timestamp,
    end_time: Timestamp,
    location_id: Option(Uuid),
  )
}

/// Runs the `update_activity_without_max_attendees` query
/// defined in `./src/server/sql/update_activity_without_max_attendees.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn update_activity_without_max_attendees(
  db: pog.Connection,
  arg_1: Uuid,
  arg_2: String,
  arg_3: String,
  arg_4: Timestamp,
  arg_5: Timestamp,
) -> Result(pog.Returned(UpdateActivityWithoutMaxAttendeesRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use title <- decode.field(1, decode.string)
    use description <- decode.field(2, decode.string)
    use start_time <- decode.field(3, pog.timestamp_decoder())
    use end_time <- decode.field(4, pog.timestamp_decoder())
    use location_id <- decode.field(5, decode.optional(uuid_decoder()))
    decode.success(UpdateActivityWithoutMaxAttendeesRow(
      id:,
      title:,
      description:,
      start_time:,
      end_time:,
      location_id:,
    ))
  }

  "UPDATE activity
SET title = $2,
    description = $3,
    max_attendees = NULL,
    start_time = $4,
    end_time = $5
WHERE id = $1
RETURNING id,
    title,
    description,
    start_time,
    end_time,
    location_id"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.parameter(pog.text(arg_2))
  |> pog.parameter(pog.text(arg_3))
  |> pog.parameter(pog.timestamp(arg_4))
  |> pog.parameter(pog.timestamp(arg_5))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `update_booking` query
/// defined in `./src/server/sql/update_booking.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type UpdateBookingRow {
  UpdateBookingRow(
    id: Uuid,
    user_id: Uuid,
    activity_id: Uuid,
    booker_group_id: Int,
    booker_group_name: String,
    group_free_text: String,
    responsible_name: String,
    phone_number: String,
    participant_count: Int,
  )
}

/// Runs the `update_booking` query
/// defined in `./src/server/sql/update_booking.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn update_booking(
  db: pog.Connection,
  arg_1: Uuid,
  arg_2: String,
  arg_3: String,
  arg_4: String,
  arg_5: Int,
) -> Result(pog.Returned(UpdateBookingRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use user_id <- decode.field(1, uuid_decoder())
    use activity_id <- decode.field(2, uuid_decoder())
    use booker_group_id <- decode.field(3, decode.int)
    use booker_group_name <- decode.field(4, decode.string)
    use group_free_text <- decode.field(5, decode.string)
    use responsible_name <- decode.field(6, decode.string)
    use phone_number <- decode.field(7, decode.string)
    use participant_count <- decode.field(8, decode.int)
    decode.success(UpdateBookingRow(
      id:,
      user_id:,
      activity_id:,
      booker_group_id:,
      booker_group_name:,
      group_free_text:,
      responsible_name:,
      phone_number:,
      participant_count:,
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
    booker_group_id,
    booker_group_name,
    group_free_text,
    responsible_name,
    phone_number,
    participant_count
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.parameter(pog.text(arg_2))
  |> pog.parameter(pog.text(arg_3))
  |> pog.parameter(pog.text(arg_4))
  |> pog.parameter(pog.int(arg_5))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `update_location` query
/// defined in `./src/server/sql/update_location.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type UpdateLocationRow {
  UpdateLocationRow(
    id: Uuid,
    name: String,
    name_en: String,
    description: String,
    description_en: String,
    icon_name: String,
    icon_variant: String,
    color: String,
    latitude: Float,
    longitude: Float,
    opening_hours: String,
  )
}

/// Updates a location and returns it. opening_hours is sent as JSON text; the
/// parameter type is inferred as jsonb from the target column.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn update_location(
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
) -> Result(pog.Returned(UpdateLocationRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use name <- decode.field(1, decode.string)
    use name_en <- decode.field(2, decode.string)
    use description <- decode.field(3, decode.string)
    use description_en <- decode.field(4, decode.string)
    use icon_name <- decode.field(5, decode.string)
    use icon_variant <- decode.field(6, decode.string)
    use color <- decode.field(7, decode.string)
    use latitude <- decode.field(8, decode.float)
    use longitude <- decode.field(9, decode.float)
    use opening_hours <- decode.field(10, decode.string)
    decode.success(UpdateLocationRow(
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

  "-- Updates a location and returns it. opening_hours is sent as JSON text; the
-- parameter type is inferred as jsonb from the target column.
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

/// A row you get from running the `update_location_tag` query
/// defined in `./src/server/sql/update_location_tag.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
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
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn update_location_tag(
  db: pog.Connection,
  arg_1: Uuid,
  arg_2: String,
  arg_3: String,
  arg_4: String,
  arg_5: String,
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
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.parameter(pog.text(arg_2))
  |> pog.parameter(pog.text(arg_3))
  |> pog.parameter(pog.text(arg_4))
  |> pog.parameter(pog.text(arg_5))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `upsert_user` query
/// defined in `./src/server/sql/upsert_user.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type UpsertUserRow {
  UpsertUserRow(id: Uuid)
}

/// Creates the user row for a JWT-authenticated user on first sight, so
/// handlers can write rows with user_id foreign keys.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
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

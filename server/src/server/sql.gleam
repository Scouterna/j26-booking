//// This module contains the code to run the sql queries defined in
//// `./src/server/sql`.
//// > 🐿️ This module was generated automatically using v4.6.0 of
//// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
////

import gleam/dynamic/decode
import gleam/option.{type Option}
import gleam/time/timestamp.{type Timestamp}
import pog
import youid/uuid.{type Uuid}

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
    decode.success(CreateActivityWithMaxAttendeesRow(
      id:,
      title:,
      description:,
      max_attendees:,
      start_time:,
      end_time:,
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
    end_time"
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
    decode.success(CreateActivityWithoutMaxAttendeesRow(
      id:,
      title:,
      description:,
      start_time:,
      end_time:,
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
    end_time"
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
    decode.success(GetActivitiesByStartTimeRow(
      id:,
      title:,
      description:,
      max_attendees:,
      start_time:,
      end_time:,
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
    decode.success(GetActivitiesByTitleRow(
      id:,
      title:,
      description:,
      max_attendees:,
      start_time:,
      end_time:,
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
    decode.success(GetActivityRow(
      id:,
      title:,
      description:,
      max_attendees:,
      start_time:,
      end_time:,
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
    decode.success(SearchActivitiesRow(
      id:,
      title:,
      description:,
      max_attendees:,
      start_time:,
      end_time:,
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
    decode.success(UpdateActivityWithMaxAttendeesRow(
      id:,
      title:,
      description:,
      max_attendees:,
      start_time:,
      end_time:,
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
    end_time"
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
    decode.success(UpdateActivityWithoutMaxAttendeesRow(
      id:,
      title:,
      description:,
      start_time:,
      end_time:,
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
    end_time"
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

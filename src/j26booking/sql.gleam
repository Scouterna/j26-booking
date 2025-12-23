//// This module contains the code to run the sql queries defined in
//// `./src/j26booking/sql`.
//// > 🐿️ This module was generated automatically using v4.6.0 of
//// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
////

import gleam/dynamic/decode
import gleam/option.{type Option}
import gleam/time/timestamp.{type Timestamp}
import pog
import youid/uuid.{type Uuid}

/// A row you get from running the `create_activity_with_max_attendees` query
/// defined in `./src/j26booking/sql/create_activity_with_max_attendees.sql`.
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
/// defined in `./src/j26booking/sql/create_activity_with_max_attendees.sql`.
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

  "INSERT INTO activity (id, title, description, max_attendees, start_time, end_time)
VALUES ($1, $2, $3, $4, $5, $6)
RETURNING id, title, description, max_attendees, start_time, end_time
"
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
/// defined in `./src/j26booking/sql/create_activity_without_max_attendees.sql`.
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
/// defined in `./src/j26booking/sql/create_activity_without_max_attendees.sql`.
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

  "INSERT INTO activity (id, title, description, max_attendees, start_time, end_time)
VALUES ($1, $2, $3, NULL, $4, $5)
RETURNING id, title, description, start_time, end_time
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.parameter(pog.text(arg_2))
  |> pog.parameter(pog.text(arg_3))
  |> pog.parameter(pog.timestamp(arg_4))
  |> pog.parameter(pog.timestamp(arg_5))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `get_activities_by_start_time` query
/// defined in `./src/j26booking/sql/get_activities_by_start_time.sql`.
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
/// defined in `./src/j26booking/sql/get_activities_by_start_time.sql`.
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
LIMIT $1
OFFSET $2;
"
  |> pog.query
  |> pog.parameter(pog.int(arg_1))
  |> pog.parameter(pog.int(arg_2))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `get_activities_by_title` query
/// defined in `./src/j26booking/sql/get_activities_by_title.sql`.
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
/// defined in `./src/j26booking/sql/get_activities_by_title.sql`.
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
LIMIT $1
OFFSET $2;"
  |> pog.query
  |> pog.parameter(pog.int(arg_1))
  |> pog.parameter(pog.int(arg_2))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `get_activity` query
/// defined in `./src/j26booking/sql/get_activity.sql`.
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
/// defined in `./src/j26booking/sql/get_activity.sql`.
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

/// A row you get from running the `search_activities` query
/// defined in `./src/j26booking/sql/search_activities.sql`.
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
ORDER BY title;
"
  |> pog.query
  |> pog.parameter(pog.text(arg_1))
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

import gleam/dynamic/decode
import gleam/float
import gleam/option.{type Option, None}
import gleam/time/timestamp.{type Timestamp}
import youid/uuid.{type Uuid}

pub type Activity {
  Activity(
    id: Uuid,
    title: String,
    description: String,
    max_attendees: Option(Int),
    start_time: Timestamp,
    end_time: Timestamp,
  )
}

/// Decode an Activity from API JSON.
/// Expects id as string (UUID), timestamps as int (unix seconds).
pub fn activity_decoder() -> decode.Decoder(Activity) {
  use id_str <- decode.field("id", decode.string)
  use title <- decode.field("title", decode.string)
  use description <- decode.field("description", decode.string)
  use max_attendees <- decode.optional_field(
    "max_attendees",
    None,
    decode.optional(decode.int),
  )
  use start_time_secs <- decode.field(
    "start_time",
    decode.one_of(decode.int, [decode.float |> decode.map(float.round)]),
  )
  use end_time_secs <- decode.field(
    "end_time",
    decode.one_of(decode.int, [decode.float |> decode.map(float.round)]),
  )
  case uuid.from_string(id_str) {
    Ok(id) ->
      decode.success(Activity(
        id:,
        title:,
        description:,
        max_attendees:,
        start_time: timestamp.from_unix_seconds(start_time_secs),
        end_time: timestamp.from_unix_seconds(end_time_secs),
      ))
    Error(_) ->
      decode.failure(
        Activity(
          id: uuid.v7(),
          title:,
          description:,
          max_attendees:,
          start_time: timestamp.from_unix_seconds(start_time_secs),
          end_time: timestamp.from_unix_seconds(end_time_secs),
        ),
        "valid UUID string",
      )
  }
}

/// Decode a list of activities from the API response `{"activities": [...]}`.
pub fn activities_decoder() -> decode.Decoder(List(Activity)) {
  use activities <- decode.field("activities", decode.list(activity_decoder()))
  decode.success(activities)
}

pub type Booking {
  Booking(
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

/// Decode a Booking from API JSON.
/// Expects id, user_id, activity_id as string (UUID).
pub fn booking_decoder() -> decode.Decoder(Booking) {
  use id_str <- decode.field("id", decode.string)
  use user_id_str <- decode.field("user_id", decode.string)
  use activity_id_str <- decode.field("activity_id", decode.string)
  use booker_group_id <- decode.field("booker_group_id", decode.int)
  use booker_group_name <- decode.field("booker_group_name", decode.string)
  use group_free_text <- decode.field("group_free_text", decode.string)
  use responsible_name <- decode.field("responsible_name", decode.string)
  use phone_number <- decode.field("phone_number", decode.string)
  use participant_count <- decode.field("participant_count", decode.int)
  case
    uuid.from_string(id_str),
    uuid.from_string(user_id_str),
    uuid.from_string(activity_id_str)
  {
    Ok(id), Ok(user_id), Ok(activity_id) ->
      decode.success(Booking(
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
    _, _, _ -> {
      let dummy =
        Booking(
          id: uuid.v7(),
          user_id: uuid.v7(),
          activity_id: uuid.v7(),
          booker_group_id:,
          booker_group_name:,
          group_free_text:,
          responsible_name:,
          phone_number:,
          participant_count:,
        )
      decode.failure(dummy, "valid UUID strings for id, user_id, activity_id")
    }
  }
}

/// Decode a list of bookings from the API response `{"bookings": [...]}`.
pub fn bookings_decoder() -> decode.Decoder(List(Booking)) {
  use bookings <- decode.field("bookings", decode.list(booking_decoder()))
  decode.success(bookings)
}

pub type Favourite {
  Favourite(id: Uuid, user_id: Uuid, activity_id: Uuid)
}

/// Decode a Favourite from API JSON.
/// Expects id, user_id, activity_id as string (UUID).
pub fn favourite_decoder() -> decode.Decoder(Favourite) {
  use id_str <- decode.field("id", decode.string)
  use user_id_str <- decode.field("user_id", decode.string)
  use activity_id_str <- decode.field("activity_id", decode.string)
  case
    uuid.from_string(id_str),
    uuid.from_string(user_id_str),
    uuid.from_string(activity_id_str)
  {
    Ok(id), Ok(user_id), Ok(activity_id) ->
      decode.success(Favourite(id:, user_id:, activity_id:))
    _, _, _ ->
      decode.failure(
        Favourite(id: uuid.v7(), user_id: uuid.v7(), activity_id: uuid.v7()),
        "valid UUID strings for id, user_id, activity_id",
      )
  }
}

/// Decode a list of favourites from the API response `{"favourites": [...]}`.
pub fn favourites_decoder() -> decode.Decoder(List(Favourite)) {
  use favourites <- decode.field(
    "favourites",
    decode.list(favourite_decoder()),
  )
  decode.success(favourites)
}

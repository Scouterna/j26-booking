import gleam/dynamic/decode
import gleam/float
import gleam/json.{type Json}
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

/// Slim activity for list views — omits `description` to keep the payload
/// small when the whole catalogue is fetched at once.
pub type ActivitySummary {
  ActivitySummary(
    id: Uuid,
    title: String,
    max_attendees: Option(Int),
    start_time: Timestamp,
    end_time: Timestamp,
  )
}

/// Decode an ActivitySummary from API JSON.
/// Expects id as string (UUID), timestamps as int (unix seconds).
pub fn activity_summary_decoder() -> decode.Decoder(ActivitySummary) {
  use id_str <- decode.field("id", decode.string)
  use title <- decode.field("title", decode.string)
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
      decode.success(ActivitySummary(
        id:,
        title:,
        max_attendees:,
        start_time: timestamp.from_unix_seconds(start_time_secs),
        end_time: timestamp.from_unix_seconds(end_time_secs),
      ))
    Error(_) ->
      decode.failure(
        ActivitySummary(
          id: uuid.v7(),
          title:,
          max_attendees:,
          start_time: timestamp.from_unix_seconds(start_time_secs),
          end_time: timestamp.from_unix_seconds(end_time_secs),
        ),
        "valid UUID string",
      )
  }
}

/// Decode a list of activity summaries from the API response
/// `{"activities": [...]}`.
pub fn activity_summaries_decoder() -> decode.Decoder(List(ActivitySummary)) {
  use activities <- decode.field(
    "activities",
    decode.list(activity_summary_decoder()),
  )
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
  use favourites <- decode.field("favourites", decode.list(favourite_decoder()))
  decode.success(favourites)
}

/// The current user's relationship to a single activity. The combined status
/// endpoint only ever reports the present states (`Booked`/`Favourited`);
/// `NotInterested` is the neutral fallback used client-side when an activity
/// is absent from the status set. `Booked` dominates `Favourited`.
pub type ActivityStatus {
  Booked(booking: Booking)
  Favourited
  NotInterested
}

/// One entry of the sparse `/api/statuses/me` response, pairing an activity id
/// with the user's status for it.
pub type ActivityStatusEntry {
  ActivityStatusEntry(activity_id: Uuid, status: ActivityStatus)
}

/// Decode a single status entry. `status` is `"booked"` (with an embedded
/// `booking`) or `"favourited"`.
pub fn activity_status_entry_decoder() -> decode.Decoder(ActivityStatusEntry) {
  use activity_id_str <- decode.field("activity_id", decode.string)
  use kind <- decode.field("status", decode.string)
  use booking <- decode.optional_field(
    "booking",
    None,
    decode.optional(booking_decoder()),
  )
  case uuid.from_string(activity_id_str), kind, booking {
    Ok(activity_id), "booked", option.Some(b) ->
      decode.success(ActivityStatusEntry(activity_id, Booked(b)))
    Ok(activity_id), "favourited", _ ->
      decode.success(ActivityStatusEntry(activity_id, Favourited))
    _, _, _ ->
      decode.failure(
        ActivityStatusEntry(uuid.v7(), Favourited),
        "valid status entry with status 'booked' (+ booking) or 'favourited'",
      )
  }
}

/// Decode a list of status entries from the API response
/// `{"statuses": [...]}`.
pub fn activity_statuses_decoder() -> decode.Decoder(List(ActivityStatusEntry)) {
  use statuses <- decode.field(
    "statuses",
    decode.list(activity_status_entry_decoder()),
  )
  decode.success(statuses)
}

pub type Location {
  Location(
    id: Uuid,
    name: String,
    name_en: String,
    description: String,
    description_en: String,
    icon_name: String,
    /// Icon style variant, e.g. `outline` or `filled`.
    icon_variant: String,
    color: String,
    latitude: Float,
    longitude: Float,
    /// Opening hours as stored, keyed by ISO date
    /// (`{"YYYY-MM-DD": [{"from": "09:00", "to": "12:00"}]}`). Carried as an
    /// opaque `Json` value and passed through untouched rather than modelled.
    opening_hours: Json,
    /// Ids of the tags applied to this location; resolve to full tags via
    /// `/api/location-tags`.
    tags: List(Uuid),
  )
}

pub type LocationTag {
  LocationTag(
    id: Uuid,
    name: String,
    name_en: String,
    icon_name: String,
    /// Icon style variant, e.g. `outline` or `filled`.
    icon_variant: String,
  )
}

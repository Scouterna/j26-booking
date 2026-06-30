import gleam/dict.{type Dict}
import gleam/dynamic/decode
import gleam/float
import gleam/int
import gleam/option.{type Option, None}
import gleam/time/timestamp.{type Timestamp}
import youid/uuid.{type Uuid}

/// Decode a UUID from a JSON string, failing the decoder on a malformed value.
/// The placeholder passed to `decode.failure` is never surfaced — it only fixes
/// the decoder's type — so a fresh v7 UUID is a fine sentinel.
fn uuid_from_string_decoder() -> decode.Decoder(Uuid) {
  use raw <- decode.then(decode.string)
  case uuid.from_string(raw) {
    Ok(id) -> decode.success(id)
    Error(_) -> decode.failure(uuid.v7(), "valid UUID string")
  }
}

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

/// A single open interval within a day, e.g. `09:00`–`12:00`. Times are kept as
/// `HH:MM` strings since they are only ever displayed, never computed with.
pub type TimeRange {
  TimeRange(from: String, to: String)
}

/// A location's opening hours, keyed by ISO date (`YYYY-MM-DD`). Each date maps
/// to the intervals the location is open that day; a missing date means closed.
pub type OpeningHours =
  Dict(String, List(TimeRange))

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
    opening_hours: OpeningHours,
    /// Ids of the tags applied to this location; resolve to full tags via
    /// `/api/location-tags`.
    tags: List(Uuid),
  )
}

fn time_range_decoder() -> decode.Decoder(TimeRange) {
  use from <- decode.field("from", decode.string)
  use to <- decode.field("to", decode.string)
  decode.success(TimeRange(from:, to:))
}

/// Decode opening hours from the API/DB JSON object
/// `{"YYYY-MM-DD": [{"from": "09:00", "to": "12:00"}]}`.
pub fn opening_hours_decoder() -> decode.Decoder(OpeningHours) {
  decode.dict(decode.string, decode.list(time_range_decoder()))
}

/// Coordinates serialise as JSON numbers; accept both float and int forms.
fn coordinate_decoder() -> decode.Decoder(Float) {
  decode.one_of(decode.float, [decode.int |> decode.map(int.to_float)])
}

/// Decode a Location from API JSON. Expects id and tag ids as UUID strings,
/// coordinates as numbers, and opening_hours as a date-keyed object.
pub fn location_decoder() -> decode.Decoder(Location) {
  use id <- decode.field("id", uuid_from_string_decoder())
  use name <- decode.field("name", decode.string)
  use name_en <- decode.field("name_en", decode.string)
  use description <- decode.field("description", decode.string)
  use description_en <- decode.field("description_en", decode.string)
  use icon_name <- decode.field("icon_name", decode.string)
  use icon_variant <- decode.field("icon_variant", decode.string)
  use color <- decode.field("color", decode.string)
  use latitude <- decode.field("latitude", coordinate_decoder())
  use longitude <- decode.field("longitude", coordinate_decoder())
  use opening_hours <- decode.field("opening_hours", opening_hours_decoder())
  use tags <- decode.field("tags", decode.list(uuid_from_string_decoder()))
  decode.success(Location(
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
    tags:,
  ))
}

/// Decode a list of locations from the API response `{"locations": [...]}`.
pub fn locations_decoder() -> decode.Decoder(List(Location)) {
  use locations <- decode.field("locations", decode.list(location_decoder()))
  decode.success(locations)
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

/// Decode a LocationTag from API JSON. Expects id as a UUID string.
pub fn location_tag_decoder() -> decode.Decoder(LocationTag) {
  use id <- decode.field("id", uuid_from_string_decoder())
  use name <- decode.field("name", decode.string)
  use name_en <- decode.field("name_en", decode.string)
  use icon_name <- decode.field("icon_name", decode.string)
  use icon_variant <- decode.field("icon_variant", decode.string)
  decode.success(LocationTag(id:, name:, name_en:, icon_name:, icon_variant:))
}

/// Decode a list of location tags from the API response
/// `{"location_tags": [...]}`.
pub fn location_tags_decoder() -> decode.Decoder(List(LocationTag)) {
  use location_tags <- decode.field(
    "location_tags",
    decode.list(location_tag_decoder()),
  )
  decode.success(location_tags)
}

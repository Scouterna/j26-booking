import gleam/dynamic/decode
import gleam/float
import gleam/int
import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}
import gleam/time/timestamp.{type Timestamp}
import shared/utils
import youid/uuid.{type Uuid}

pub type Activity {
  Activity(
    id: Uuid,
    title: BilingualString,
    description: BilingualString,
    max_attendees: Option(Int),
    start_time: Timestamp,
    end_time: Timestamp,
    /// The full location this activity happens at. `None` when the activity has no location.
    location: Option(Location),
    /// Ids of the activity tags applied to this activity; resolve to full tags
    /// via `/api/activity-tags`.
    tags: List(Uuid),
    /// The scout age sections this activity targets.
    target_groups: List(TargetGroup),
    /// The call-off reason when this activity has been cancelled, else `None`.
    /// `Some(reason)` means the activity is called off ("inställd").
    cancellation: Option(String),
  )
}

/// Decode an Activity from API JSON.
/// Expects id as string (UUID), timestamps as int (unix seconds).
pub fn activity_decoder() -> decode.Decoder(Activity) {
  use id_str <- decode.field("id", decode.string)
  use title <- decode.field("title", bilingual_string_decoder())
  use description <- decode.field("description", bilingual_string_decoder())
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
  use location <- decode.optional_field(
    "location",
    None,
    decode.optional(location_decoder()),
  )
  use tags <- decode.optional_field(
    "tags",
    [],
    utils.decode_partial_list(of: uuid_decoder()),
  )
  use target_groups <- decode.optional_field(
    "target_groups",
    [],
    utils.decode_partial_list(of: target_group_decoder()),
  )
  use cancellation <- decode.optional_field(
    "cancellation",
    None,
    decode.optional(decode.string),
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
        location:,
        tags:,
        target_groups:,
        cancellation:,
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
          location:,
          tags:,
          target_groups:,
          cancellation:,
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

/// A string carried in both Swedish and English so the client can pick a
/// variant by active language. Serialised as `{"sv": ..., "en": ...}`.
pub type BilingualString {
  BilingualString(sv: String, en: String)
}

/// Decode a `BilingualString` from `{"sv": ..., "en": ...}`.
pub fn bilingual_string_decoder() -> decode.Decoder(BilingualString) {
  use sv <- decode.field("sv", decode.string)
  use en <- decode.field("en", decode.string)
  decode.success(BilingualString(sv:, en:))
}

/// Encode a `BilingualString` as `{"sv": ..., "en": ...}`.
pub fn bilingual_string_to_json(value: BilingualString) -> Json {
  json.object([#("sv", json.string(value.sv)), #("en", json.string(value.en))])
}

/// The scout age sections an activity can target ("målgrupp"). A fixed, closed
/// set — the server persists it as a Postgres enum and Squirrel generates its
/// own matching type; this shared type is the identity used across the API and
/// client. Bilingual display labels live in the client's translations.
pub type TargetGroup {
  Sparare
  Upptackare
  Aventyrare
  Utmanare
  Rover
}

/// Every target group in age order — drives client filter chips and gives a
/// stable display order the database cannot guarantee.
pub fn target_groups_all() -> List(TargetGroup) {
  [Sparare, Upptackare, Aventyrare, Utmanare, Rover]
}

/// The wire/DB string for a target group (matches the Postgres enum values).
pub fn target_group_to_string(target_group: TargetGroup) -> String {
  case target_group {
    Sparare -> "sparare"
    Upptackare -> "upptackare"
    Aventyrare -> "aventyrare"
    Utmanare -> "utmanare"
    Rover -> "rover"
  }
}

/// Parse a target group from its wire/DB string.
pub fn target_group_from_string(raw: String) -> Result(TargetGroup, Nil) {
  case raw {
    "sparare" -> Ok(Sparare)
    "upptackare" -> Ok(Upptackare)
    "aventyrare" -> Ok(Aventyrare)
    "utmanare" -> Ok(Utmanare)
    "rover" -> Ok(Rover)
    _ -> Error(Nil)
  }
}

/// Decode a target group from its wire string, failing on an unknown value.
pub fn target_group_decoder() -> decode.Decoder(TargetGroup) {
  use raw <- decode.then(decode.string)
  case target_group_from_string(raw) {
    Ok(target_group) -> decode.success(target_group)
    Error(_) -> decode.failure(Sparare, "valid target group")
  }
}

/// Encode a target group as its wire string.
pub fn target_group_to_json(target_group: TargetGroup) -> Json {
  target_group |> target_group_to_string |> json.string
}

/// A tag that can be applied to activities. Unlike `LocationTag`, activity tags
/// carry no icon — they render as plain text chips.
pub type ActivityTag {
  ActivityTag(id: Uuid, name: BilingualString)
}

/// Decode an `ActivityTag` from API JSON (matches the server's
/// `activity.activity_tag_to_json`).
pub fn activity_tag_decoder() -> decode.Decoder(ActivityTag) {
  use id <- decode.field("id", uuid_decoder())
  use name <- decode.field("name", bilingual_string_decoder())
  decode.success(ActivityTag(id:, name:))
}

/// Decode the list response `{"activity_tags": [...]}`.
pub fn activity_tags_decoder() -> decode.Decoder(List(ActivityTag)) {
  use tags <- decode.field("activity_tags", decode.list(activity_tag_decoder()))
  decode.success(tags)
}

/// Slim activity for list views — omits `description` to keep the payload
/// small when the whole catalogue is fetched at once.
pub type ActivitySummary {
  ActivitySummary(
    id: Uuid,
    title: BilingualString,
    max_attendees: Option(Int),
    start_time: Timestamp,
    end_time: Timestamp,
    /// The location's name in both languages, embedded so list cards need no
    /// follow-up request. `None` when the activity has no location.
    location_name: Option(BilingualString),
    /// Ids of the activity tags applied to this activity. Carried on the summary
    /// so the list view can filter without fetching each activity's detail.
    tags: List(Uuid),
    /// The scout age sections this activity targets.
    target_groups: List(TargetGroup),
    /// The call-off reason when this activity has been cancelled, else `None`.
    /// `Some(reason)` means the activity is called off ("inställd").
    cancellation: Option(String),
  )
}

/// Decode an ActivitySummary from API JSON.
/// Expects id as string (UUID), timestamps as int (unix seconds).
pub fn activity_summary_decoder() -> decode.Decoder(ActivitySummary) {
  use id_str <- decode.field("id", decode.string)
  use title <- decode.field("title", bilingual_string_decoder())
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
  use location_name <- decode.optional_field(
    "location_name",
    None,
    decode.optional(bilingual_string_decoder()),
  )
  use tags <- decode.optional_field(
    "tags",
    [],
    utils.decode_partial_list(of: uuid_decoder()),
  )
  use target_groups <- decode.optional_field(
    "target_groups",
    [],
    utils.decode_partial_list(of: target_group_decoder()),
  )
  use cancellation <- decode.optional_field(
    "cancellation",
    None,
    decode.optional(decode.string),
  )
  case uuid.from_string(id_str) {
    Ok(id) ->
      decode.success(ActivitySummary(
        id:,
        title:,
        max_attendees:,
        start_time: timestamp.from_unix_seconds(start_time_secs),
        end_time: timestamp.from_unix_seconds(end_time_secs),
        location_name:,
        tags:,
        target_groups:,
        cancellation:,
      ))
    Error(_) ->
      decode.failure(
        ActivitySummary(
          id: uuid.v7(),
          title:,
          max_attendees:,
          start_time: timestamp.from_unix_seconds(start_time_secs),
          end_time: timestamp.from_unix_seconds(end_time_secs),
          location_name:,
          tags:,
          target_groups:,
          cancellation:,
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

/// The number of booked spots (summed `participant_count`) for one activity.
/// Served by `/api/activity-spots` separately from the activity itself because
/// the count is volatile and fetched more often than the activity metadata.
pub type ActivitySpots {
  ActivitySpots(activity_id: Uuid, spots_booked: Int)
}

/// Decode an ActivitySpots entry. Expects `activity_id` as a UUID string.
pub fn activity_spots_decoder() -> decode.Decoder(ActivitySpots) {
  use activity_id_str <- decode.field("activity_id", decode.string)
  use spots_booked <- decode.field("spots_booked", decode.int)
  case uuid.from_string(activity_id_str) {
    Ok(activity_id) ->
      decode.success(ActivitySpots(activity_id:, spots_booked:))
    Error(_) ->
      decode.failure(
        ActivitySpots(uuid.v7(), spots_booked),
        "valid UUID string for activity_id",
      )
  }
}

/// Decode a list of spot counts from the API response `{"spots": [...]}`.
pub fn activity_spots_list_decoder() -> decode.Decoder(List(ActivitySpots)) {
  use spots <- decode.field("spots", decode.list(activity_spots_decoder()))
  decode.success(spots)
}

/// Decode the single-activity spots response `{"spots_booked": <int>}`.
pub fn spots_booked_decoder() -> decode.Decoder(Int) {
  use spots_booked <- decode.field("spots_booked", decode.int)
  decode.success(spots_booked)
}

/// Spots left for display, with `Unknown` as a first-class state so a card
/// with cached metadata but no fetched count renders "unknown" rather than
/// falsely claiming full availability.
pub type SpotsRemaining {
  /// `max_attendees` is `None` — no cap.
  Unlimited
  /// Known cap and known count; the seats left, clamped at 0.
  Remaining(Int)
  /// Capped, but the booked count is not in hand (not fetched / offline).
  UnknownSpots
}

/// Derive the display state. `spots_booked` is `None` when the count is unknown.
pub fn spots_remaining(
  max_attendees: Option(Int),
  spots_booked: Option(Int),
) -> SpotsRemaining {
  case max_attendees, spots_booked {
    None, _ -> Unlimited
    Some(_), None -> UnknownSpots
    Some(max), Some(booked) -> Remaining(int.max(0, max - booked))
  }
}

pub type Booking {
  Booking(
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
  )
}

/// Decode a Booking from API JSON.
/// Expects id, user_id, activity_id as string (UUID).
pub fn booking_decoder() -> decode.Decoder(Booking) {
  use id_str <- decode.field("id", decode.string)
  use user_id_str <- decode.field("user_id", decode.string)
  use activity_id_str <- decode.field("activity_id", decode.string)
  use booker_name <- decode.field("booker_name", decode.string)
  use booker_group_id <- decode.optional_field(
    "booker_group_id",
    None,
    decode.optional(decode.int),
  )
  use booker_group_name <- decode.optional_field(
    "booker_group_name",
    None,
    decode.optional(decode.string),
  )
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
        booker_name:,
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
          booker_name:,
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

/// One scout corps' (kår) participant tally within a recurring-activity slot,
/// for the Badbuss / Klättervägg booking overview. `group_id` is the kår-ID
/// (from the booker's token) and `group_name` the kår name; both are `None`
/// for bookings made without a kår, which the server buckets under a single
/// unknown-group entry.
pub type GroupCount {
  GroupCount(group_id: Option(Int), group_name: Option(String), count: Int)
}

/// Decode a `GroupCount` from `{"group_id": ..., "group_name": ..., "count": ...}`.
pub fn group_count_decoder() -> decode.Decoder(GroupCount) {
  use group_id <- decode.optional_field(
    "group_id",
    None,
    decode.optional(decode.int),
  )
  use group_name <- decode.optional_field(
    "group_name",
    None,
    decode.optional(decode.string),
  )
  use count <- decode.field("count", decode.int)
  decode.success(GroupCount(group_id:, group_name:, count:))
}

/// One time slot in a recurring-activity booking overview: a single activity's
/// schedule and capacity, its total booked participants, and the per-kår
/// breakdown. Powers the Badbuss / Klättervägg overview pages, which list every
/// slot of a `recurring_activity_kind` and let the user drill into one slot's
/// full bookings.
pub type BookingSlot {
  BookingSlot(
    activity_id: Uuid,
    start_time: Timestamp,
    end_time: Timestamp,
    max_attendees: Option(Int),
    total_booked: Int,
    groups: List(GroupCount),
  )
}

/// Decode a `BookingSlot` from API JSON. Timestamps are unix seconds (matching
/// the activity summary encoding); `activity_id` is a UUID string.
pub fn booking_slot_decoder() -> decode.Decoder(BookingSlot) {
  use activity_id_str <- decode.field("activity_id", decode.string)
  use start_time_secs <- decode.field(
    "start_time",
    decode.one_of(decode.int, [decode.float |> decode.map(float.round)]),
  )
  use end_time_secs <- decode.field(
    "end_time",
    decode.one_of(decode.int, [decode.float |> decode.map(float.round)]),
  )
  use max_attendees <- decode.optional_field(
    "max_attendees",
    None,
    decode.optional(decode.int),
  )
  use total_booked <- decode.field("total_booked", decode.int)
  use groups <- decode.field("groups", decode.list(group_count_decoder()))
  case uuid.from_string(activity_id_str) {
    Ok(activity_id) ->
      decode.success(BookingSlot(
        activity_id:,
        start_time: timestamp.from_unix_seconds(start_time_secs),
        end_time: timestamp.from_unix_seconds(end_time_secs),
        max_attendees:,
        total_booked:,
        groups:,
      ))
    Error(_) ->
      decode.failure(
        BookingSlot(
          activity_id: uuid.v7(),
          start_time: timestamp.from_unix_seconds(start_time_secs),
          end_time: timestamp.from_unix_seconds(end_time_secs),
          max_attendees:,
          total_booked:,
          groups:,
        ),
        "valid UUID string for activity_id",
      )
  }
}

/// Decode the overview response `{"slots": [...]}`.
pub fn booking_slots_decoder() -> decode.Decoder(List(BookingSlot)) {
  use slots <- decode.field("slots", decode.list(booking_slot_decoder()))
  decode.success(slots)
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
    name: BilingualString,
    description: BilingualString,
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
    name: BilingualString,
    icon_name: String,
    /// Icon style variant, e.g. `outline` or `filled`.
    icon_variant: String,
  )
}

/// Decodes a UUID string, failing the field on an unparseable value.
fn uuid_decoder() -> decode.Decoder(Uuid) {
  use str <- decode.then(decode.string)
  case uuid.from_string(str) {
    Ok(id) -> decode.success(id)
    Error(_) -> decode.failure(uuid.v7(), "valid UUID string")
  }
}

/// Decode a Location from API JSON (matches the server's `location.to_json`).
/// `opening_hours` is carried through as an opaque `Json` value.
pub fn location_decoder() -> decode.Decoder(Location) {
  let float_field =
    decode.one_of(decode.float, [decode.int |> decode.map(int.to_float)])
  use id <- decode.field("id", uuid_decoder())
  use name <- decode.field("name", bilingual_string_decoder())
  use description <- decode.field("description", bilingual_string_decoder())
  use icon_name <- decode.field("icon_name", decode.string)
  use icon_variant <- decode.field("icon_variant", decode.string)
  use color <- decode.field("color", decode.string)
  use latitude <- decode.field("latitude", float_field)
  use longitude <- decode.field("longitude", float_field)
  use opening_hours <- decode.optional_field(
    "opening_hours",
    json.object([]),
    utils.json_passthrough_decoder(),
  )
  use tags <- decode.field(
    "tags",
    utils.decode_partial_list(of: uuid_decoder()),
  )
  decode.success(Location(
    id:,
    name:,
    description:,
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

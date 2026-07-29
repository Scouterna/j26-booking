import gleam/json
import gleam/option.{None, Some}
import shared/model

/// A full location JSON body as the server serializes it, with the
/// coordinate fields swapped in.
fn location_json(coordinate_fields: String) -> String {
  "{
    \"id\": \"0190f3a1-1c2d-7e3f-9a4b-5c6d7e8f9a0b\",
    \"name\": {\"sv\": \"Infotält\", \"en\": \"Info tent\"},
    \"description\": {\"sv\": \"\", \"en\": \"\"},
    \"icon_name\": \"tabler-badge-wc\",
    \"icon_variant\": \"filled\",
    \"color\": \"#2563eb\",
    " <> coordinate_fields <> "
    \"opening_hours\": {},
    \"tags\": []
  }"
}

pub fn location_with_coordinates_decodes_test() {
  let assert Ok(location) =
    json.parse(
      location_json("\"latitude\": 55.9798, \"longitude\": 14.1344,"),
      model.location_decoder(),
    )
  assert location.coordinates
    == Some(model.Coordinates(latitude: 55.9798, longitude: 14.1344))
}

pub fn location_with_null_coordinates_decodes_to_none_test() {
  let assert Ok(location) =
    json.parse(
      location_json("\"latitude\": null, \"longitude\": null,"),
      model.location_decoder(),
    )
  assert location.coordinates == None
}

pub fn location_with_absent_coordinates_decodes_to_none_test() {
  let assert Ok(location) =
    json.parse(location_json(""), model.location_decoder())
  assert location.coordinates == None
}

// Coordinates are all-or-nothing: one field without the other is invalid
// input, not a coordinate-less location.

pub fn location_with_only_latitude_fails_test() {
  let assert Error(_) =
    json.parse(
      location_json("\"latitude\": 55.9798,"),
      model.location_decoder(),
    )
}

pub fn location_with_only_longitude_fails_test() {
  let assert Error(_) =
    json.parse(
      location_json("\"longitude\": 14.1344, \"latitude\": null,"),
      model.location_decoder(),
    )
}

/// Integer coordinates (JSON numbers without a decimal point) still decode.
pub fn location_with_integer_coordinates_decodes_test() {
  let assert Ok(location) =
    json.parse(
      location_json("\"latitude\": 56, \"longitude\": 14,"),
      model.location_decoder(),
    )
  assert location.coordinates
    == Some(model.Coordinates(latitude: 56.0, longitude: 14.0))
}

// --- Recurring kind ---------------------------------------------------------

/// The wire strings are the `activity.recurring_activity_kind` column values,
/// so the round trip has to be exact in both directions.
pub fn recurring_kind_round_trips_test() {
  assert model.recurring_kind_to_string(model.BeachBus) == "beach-bus"
  assert model.recurring_kind_to_string(model.ClimbingWall) == "climbing-wall"
  assert model.recurring_kind_from_string("beach-bus") == Ok(model.BeachBus)
  assert model.recurring_kind_from_string("climbing-wall")
    == Ok(model.ClimbingWall)
}

pub fn unknown_recurring_kind_is_rejected_test() {
  let assert Error(_) = model.recurring_kind_from_string("bouncy-castle")
  let assert Error(_) = model.recurring_kind_from_string("")
}

// --- Activity.recurring_kind ------------------------------------------------

/// A minimal activity body as the server serializes it, with `recurring_kind`
/// swapped in (or left out entirely).
fn activity_json(recurring_kind_field: String) -> String {
  "{
    \"id\": \"6f5e1d46-5f58-4e23-9a9d-8c2bfc2d22a0\",
    \"title\": {\"sv\": \"Badbuss\", \"en\": \"Beach bus\"},
    \"description\": {\"sv\": \"\", \"en\": \"\"},
    \"max_attendees\": 50,
    \"start_time\": 1752350400,
    \"end_time\": 1752357600,
    \"location\": null,
    \"tags\": [],
    \"target_groups\": [],
    \"cancellation\": null,
    " <> recurring_kind_field <> "
    \"booking_opens_at\": null
  }"
}

pub fn activity_recurring_kind_decodes_test() {
  let assert Ok(activity) =
    json.parse(
      activity_json("\"recurring_kind\": \"beach-bus\","),
      model.activity_decoder(),
    )
  assert activity.recurring_kind == Some(model.BeachBus)
}

pub fn activity_null_recurring_kind_decodes_to_none_test() {
  let assert Ok(activity) =
    json.parse(
      activity_json("\"recurring_kind\": null,"),
      model.activity_decoder(),
    )
  assert activity.recurring_kind == None
}

/// An older payload without the field decodes as an ordinary activity rather
/// than failing.
pub fn activity_absent_recurring_kind_decodes_to_none_test() {
  let assert Ok(activity) =
    json.parse(activity_json(""), model.activity_decoder())
  assert activity.recurring_kind == None
}

// --- Booking departure check-offs -------------------------------------------

/// A booking body as the server serializes it, with the departure fields
/// swapped in (or left out entirely).
fn booking_json(departure_fields: String) -> String {
  "{
    \"id\": \"dd000001-0000-4000-8000-000000000001\",
    \"user_id\": \"a1b2c3d4-e5f6-4a90-abcd-ef1234567890\",
    \"activity_id\": \"6f5e1d46-5f58-4e23-9a9d-8c2bfc2d22a0\",
    \"booker_name\": \"Anna Svensson\",
    \"booker_group_id\": 101,
    \"booker_group_name\": \"Sjöscoutkåren Dansen\",
    \"group_free_text\": \"\",
    \"responsible_name\": \"Anna Svensson\",
    \"phone_number\": \"+46701234567\",
    \"participant_count\": 12,
    \"booked_for_other\": false,
    " <> departure_fields <> "
    \"cancellation\": null
  }"
}

pub fn booking_departure_flags_decode_test() {
  let assert Ok(booking) =
    json.parse(
      booking_json("\"left_campsite\": true, \"left_beach\": false,"),
      model.booking_decoder(),
    )
  assert booking.left_campsite
  assert !booking.left_beach
}

/// The two stages are independent, so only the beach one being set decodes
/// just as happily.
pub fn booking_left_beach_alone_decodes_test() {
  let assert Ok(booking) =
    json.parse(
      booking_json("\"left_campsite\": false, \"left_beach\": true,"),
      model.booking_decoder(),
    )
  assert !booking.left_campsite
  assert booking.left_beach
}

/// A payload predating the columns decodes with both boxes unticked rather than
/// failing — the same tolerance `booked_for_other` has.
pub fn booking_absent_departure_flags_default_to_false_test() {
  let assert Ok(booking) = json.parse(booking_json(""), model.booking_decoder())
  assert !booking.left_campsite
  assert !booking.left_beach
}

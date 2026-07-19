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

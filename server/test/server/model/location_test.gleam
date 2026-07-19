import gleam/json
import gleam/option.{type Option, None, Some}
import server/model/location
import shared/model
import youid/uuid

/// The server serialization and the shared decoder are two halves of the same
/// contract, so a `Location` must round-trip through them — in particular the
/// flat nullable `latitude`/`longitude` fields must rebuild the same optional
/// `Coordinates` pair (issue #26).
fn round_trips(coordinates: Option(model.Coordinates)) -> Bool {
  let assert Ok(id) = uuid.from_string("0190f3a1-1c2d-7e3f-9a4b-5c6d7e8f9a0b")
  let original =
    model.Location(
      id:,
      name: model.BilingualString(sv: "Infotält", en: "Info tent"),
      description: model.BilingualString(sv: "", en: ""),
      icon_name: "tabler-badge-wc",
      icon_variant: "filled",
      color: "#2563eb",
      coordinates:,
      opening_hours: json.object([]),
      tags: [],
    )
  let assert Ok(decoded) =
    original
    |> location.to_json
    |> json.to_string
    |> json.parse(model.location_decoder())
  decoded == original
}

pub fn location_with_coordinates_round_trips_test() {
  assert round_trips(
    Some(model.Coordinates(latitude: 55.9798, longitude: 14.1344)),
  )
}

pub fn location_without_coordinates_round_trips_test() {
  assert round_trips(None)
}

import gleam/dict
import gleam/json.{type Json}
import gleam/list
import server/sql
import shared/model.{
  type Location, type LocationTag, type OpeningHours, type TimeRange, Location,
  LocationTag,
}
import youid/uuid.{type Uuid}

/// Build a `Location` from its DB row plus the tag ids resolved by the handler
/// from the join table. `opening_hours` arrives as a JSON string (the jsonb
/// column cast to text) and is parsed here, falling back to no hours if the
/// stored value is somehow malformed.
pub fn from_list_locations_row(
  row: sql.ListLocationsRow,
  tags: List(Uuid),
) -> Location {
  Location(
    id: row.id,
    name: row.name,
    name_en: row.name_en,
    description: row.description,
    description_en: row.description_en,
    icon_name: row.icon_name,
    icon_variant: row.icon_variant,
    color: row.color,
    latitude: row.latitude,
    longitude: row.longitude,
    opening_hours: parse_opening_hours(row.opening_hours),
    tags:,
  )
}

fn parse_opening_hours(raw: String) -> OpeningHours {
  case json.parse(from: raw, using: model.opening_hours_decoder()) {
    Ok(opening_hours) -> opening_hours
    Error(_) -> dict.new()
  }
}

pub fn from_list_location_tags_row(
  row: sql.ListLocationTagsRow,
) -> LocationTag {
  LocationTag(
    id: row.id,
    name: row.name,
    name_en: row.name_en,
    icon_name: row.icon_name,
    icon_variant: row.icon_variant,
  )
}

pub fn to_json(location: Location) -> Json {
  let Location(
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
  ) = location
  json.object([
    #("id", id |> uuid.to_string |> json.string),
    #("name", json.string(name)),
    #("name_en", json.string(name_en)),
    #("description", json.string(description)),
    #("description_en", json.string(description_en)),
    #("icon_name", json.string(icon_name)),
    #("icon_variant", json.string(icon_variant)),
    #("color", json.string(color)),
    #("latitude", json.float(latitude)),
    #("longitude", json.float(longitude)),
    #("opening_hours", opening_hours_to_json(opening_hours)),
    #("tags", json.array(tags, uuid_to_json)),
  ])
}

pub fn tag_to_json(tag: LocationTag) -> Json {
  let LocationTag(id:, name:, name_en:, icon_name:, icon_variant:) = tag
  json.object([
    #("id", id |> uuid.to_string |> json.string),
    #("name", json.string(name)),
    #("name_en", json.string(name_en)),
    #("icon_name", json.string(icon_name)),
    #("icon_variant", json.string(icon_variant)),
  ])
}

fn opening_hours_to_json(opening_hours: OpeningHours) -> Json {
  opening_hours
  |> dict.to_list
  |> list.map(fn(entry) {
    let #(date, ranges) = entry
    #(date, json.array(ranges, time_range_to_json))
  })
  |> json.object
}

fn time_range_to_json(range: TimeRange) -> Json {
  json.object([
    #("from", json.string(range.from)),
    #("to", json.string(range.to)),
  ])
}

fn uuid_to_json(id: Uuid) -> Json {
  id |> uuid.to_string |> json.string
}

import gleam/dict.{type Dict}
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import pog
import server/sql
import shared/model.{type Location, type LocationTag, Location, LocationTag}
import shared/utils
import youid/uuid.{type Uuid}

/// Build a `Location` from its DB row plus the tag ids resolved by the handler
/// from the join table. `opening_hours` arrives as a JSON string (the jsonb
/// column) and is passed straight through as an opaque `Json` value — we never
/// model its shape — falling back to an empty object if it is somehow not valid
/// JSON.
pub fn from_list_locations_row(
  row: sql.ListLocationsRow,
  tags: List(Uuid),
) -> Location {
  Location(
    id: row.id,
    name: model.BilingualString(sv: row.name, en: row.name_en),
    description: model.BilingualString(
      sv: row.description,
      en: row.description_en,
    ),
    icon_name: row.icon_name,
    icon_variant: row.icon_variant,
    color: row.color,
    coordinates: coordinates_from_columns(row.latitude, row.longitude),
    opening_hours: parse_opening_hours(row.opening_hours),
    tags:,
  )
}

pub fn from_create_location_with_coordinates_row(
  row: sql.CreateLocationWithCoordinatesRow,
  tags: List(Uuid),
) -> Location {
  Location(
    id: row.id,
    name: model.BilingualString(sv: row.name, en: row.name_en),
    description: model.BilingualString(
      sv: row.description,
      en: row.description_en,
    ),
    icon_name: row.icon_name,
    icon_variant: row.icon_variant,
    color: row.color,
    coordinates: coordinates_from_columns(row.latitude, row.longitude),
    opening_hours: parse_opening_hours(row.opening_hours),
    tags:,
  )
}

pub fn from_create_location_without_coordinates_row(
  row: sql.CreateLocationWithoutCoordinatesRow,
  tags: List(Uuid),
) -> Location {
  Location(
    id: row.id,
    name: model.BilingualString(sv: row.name, en: row.name_en),
    description: model.BilingualString(
      sv: row.description,
      en: row.description_en,
    ),
    icon_name: row.icon_name,
    icon_variant: row.icon_variant,
    color: row.color,
    coordinates: coordinates_from_columns(row.latitude, row.longitude),
    opening_hours: parse_opening_hours(row.opening_hours),
    tags:,
  )
}

pub fn from_get_location_row(
  row: sql.GetLocationRow,
  tags: List(Uuid),
) -> Location {
  Location(
    id: row.id,
    name: model.BilingualString(sv: row.name, en: row.name_en),
    description: model.BilingualString(
      sv: row.description,
      en: row.description_en,
    ),
    icon_name: row.icon_name,
    icon_variant: row.icon_variant,
    color: row.color,
    coordinates: coordinates_from_columns(row.latitude, row.longitude),
    opening_hours: parse_opening_hours(row.opening_hours),
    tags:,
  )
}

pub fn from_update_location_with_coordinates_row(
  row: sql.UpdateLocationWithCoordinatesRow,
  tags: List(Uuid),
) -> Location {
  Location(
    id: row.id,
    name: model.BilingualString(sv: row.name, en: row.name_en),
    description: model.BilingualString(
      sv: row.description,
      en: row.description_en,
    ),
    icon_name: row.icon_name,
    icon_variant: row.icon_variant,
    color: row.color,
    coordinates: coordinates_from_columns(row.latitude, row.longitude),
    opening_hours: parse_opening_hours(row.opening_hours),
    tags:,
  )
}

pub fn from_update_location_without_coordinates_row(
  row: sql.UpdateLocationWithoutCoordinatesRow,
  tags: List(Uuid),
) -> Location {
  Location(
    id: row.id,
    name: model.BilingualString(sv: row.name, en: row.name_en),
    description: model.BilingualString(
      sv: row.description,
      en: row.description_en,
    ),
    icon_name: row.icon_name,
    icon_variant: row.icon_variant,
    color: row.color,
    coordinates: coordinates_from_columns(row.latitude, row.longitude),
    opening_hours: parse_opening_hours(row.opening_hours),
    tags:,
  )
}

/// Pair the two nullable coordinate columns into an optional `Coordinates`.
/// The `location_coordinates_paired` CHECK constraint guarantees the columns
/// are either both set or both null, so the mixed cases cannot occur; they
/// collapse to `None` rather than crashing if the constraint were ever lost.
fn coordinates_from_columns(
  latitude: Option(Float),
  longitude: Option(Float),
) -> Option(model.Coordinates) {
  case latitude, longitude {
    Some(latitude), Some(longitude) ->
      Some(model.Coordinates(latitude:, longitude:))
    _, _ -> None
  }
}

fn parse_opening_hours(raw: String) -> Json {
  case json.parse(from: raw, using: utils.json_passthrough_decoder()) {
    Ok(opening_hours) -> opening_hours
    Error(_) -> json.object([])
  }
}

/// Groups tag-location links into the tag ids applied to each location.
pub fn group_tags_by_location(
  links: List(sql.ListLocationTagLinksRow),
) -> Dict(Uuid, List(Uuid)) {
  list.fold(links, dict.new(), fn(acc, link) {
    use existing <- dict.upsert(acc, link.location_id)
    case existing {
      Some(tag_ids) -> [link.location_tag_id, ..tag_ids]
      None -> [link.location_tag_id]
    }
  })
}

/// Fetch every location with its tag ids stitched in, ordered by name.
pub fn fetch_all(db: pog.Connection) -> Result(List(Location), pog.QueryError) {
  use pog.Returned(_, location_rows) <- result.try(sql.list_locations(db))
  use pog.Returned(_, link_rows) <- result.try(sql.list_location_tag_links(db))
  let tags_by_location = group_tags_by_location(link_rows)
  location_rows
  |> list.map(fn(row) {
    let tags = dict.get(tags_by_location, row.id) |> result.unwrap([])
    from_list_locations_row(row, tags)
  })
  |> Ok
}

/// Fetch every location keyed by id — used to embed locations into activities
/// without a per-activity query.
pub fn fetch_all_dict(
  db: pog.Connection,
) -> Result(Dict(Uuid, Location), pog.QueryError) {
  use locations <- result.map(fetch_all(db))
  list.fold(locations, dict.new(), fn(acc, location) {
    dict.insert(acc, location.id, location)
  })
}

pub fn from_list_location_tags_row(
  row: sql.ListLocationTagsRow,
) -> LocationTag {
  LocationTag(
    id: row.id,
    name: model.BilingualString(sv: row.name, en: row.name_en),
    icon_name: row.icon_name,
    icon_variant: row.icon_variant,
  )
}

pub fn from_create_location_tag_row(
  row: sql.CreateLocationTagRow,
) -> LocationTag {
  LocationTag(
    id: row.id,
    name: model.BilingualString(sv: row.name, en: row.name_en),
    icon_name: row.icon_name,
    icon_variant: row.icon_variant,
  )
}

pub fn from_get_location_tag_row(row: sql.GetLocationTagRow) -> LocationTag {
  LocationTag(
    id: row.id,
    name: model.BilingualString(sv: row.name, en: row.name_en),
    icon_name: row.icon_name,
    icon_variant: row.icon_variant,
  )
}

pub fn from_update_location_tag_row(
  row: sql.UpdateLocationTagRow,
) -> LocationTag {
  LocationTag(
    id: row.id,
    name: model.BilingualString(sv: row.name, en: row.name_en),
    icon_name: row.icon_name,
    icon_variant: row.icon_variant,
  )
}

pub fn to_json(location: Location) -> Json {
  let Location(
    id:,
    name:,
    description:,
    icon_name:,
    icon_variant:,
    color:,
    coordinates:,
    opening_hours:,
    tags:,
  ) = location
  json.object([
    #("id", id |> uuid.to_string |> json.string),
    #("name", model.bilingual_string_to_json(name)),
    #("description", model.bilingual_string_to_json(description)),
    #("icon_name", json.string(icon_name)),
    #("icon_variant", json.string(icon_variant)),
    #("color", json.string(color)),
    #(
      "latitude",
      json.nullable(
        option.map(coordinates, fn(c: model.Coordinates) { c.latitude }),
        json.float,
      ),
    ),
    #(
      "longitude",
      json.nullable(
        option.map(coordinates, fn(c: model.Coordinates) { c.longitude }),
        json.float,
      ),
    ),
    #("opening_hours", opening_hours),
    #("tags", json.array(tags, uuid_to_json)),
  ])
}

pub fn tag_to_json(tag: LocationTag) -> Json {
  let LocationTag(id:, name:, icon_name:, icon_variant:) = tag
  json.object([
    #("id", id |> uuid.to_string |> json.string),
    #("name", model.bilingual_string_to_json(name)),
    #("icon_name", json.string(icon_name)),
    #("icon_variant", json.string(icon_variant)),
  ])
}

fn uuid_to_json(id: Uuid) -> Json {
  id |> uuid.to_string |> json.string
}

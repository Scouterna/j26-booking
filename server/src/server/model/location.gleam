import gleam/dict.{type Dict}
import gleam/json.{type Json}
import gleam/list
import gleam/option.{None, Some}
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
    latitude: row.latitude,
    longitude: row.longitude,
    opening_hours: parse_opening_hours(row.opening_hours),
    tags:,
  )
}

pub fn from_create_location_row(
  row: sql.CreateLocationRow,
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
    latitude: row.latitude,
    longitude: row.longitude,
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
    latitude: row.latitude,
    longitude: row.longitude,
    opening_hours: parse_opening_hours(row.opening_hours),
    tags:,
  )
}

pub fn from_update_location_row(
  row: sql.UpdateLocationRow,
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
    latitude: row.latitude,
    longitude: row.longitude,
    opening_hours: parse_opening_hours(row.opening_hours),
    tags:,
  )
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
    latitude:,
    longitude:,
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
    #("latitude", json.float(latitude)),
    #("longitude", json.float(longitude)),
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

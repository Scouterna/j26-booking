import gleam/dict.{type Dict}
import gleam/float
import gleam/json.{type Json}
import gleam/option.{type Option, None}
import gleam/time/timestamp
import server/model/location
import server/sql
import shared/model.{type Activity, type Location, Activity}
import youid/uuid.{type Uuid}

/// Resolve an activity's `location_id` to the full location fetched by the
/// handler. `None` when the activity has no location or the id is unknown.
fn resolve_location(
  location_id: Option(Uuid),
  locations: Dict(Uuid, Location),
) -> Option(Location) {
  case location_id {
    None -> None
    option.Some(id) -> dict.get(locations, id) |> option.from_result
  }
}

pub fn from_create_activity_with_max_attendees_row(
  row: sql.CreateActivityWithMaxAttendeesRow,
  locations: Dict(Uuid, Location),
) -> Activity {
  Activity(
    id: row.id,
    title: model.BilingualString(sv: row.title, en: row.title_en),
    description: model.BilingualString(
      sv: row.description,
      en: row.description_en,
    ),
    max_attendees: row.max_attendees,
    start_time: row.start_time,
    end_time: row.end_time,
    location: resolve_location(row.location_id, locations),
  )
}

pub fn from_create_activity_without_max_attendees_row(
  row: sql.CreateActivityWithoutMaxAttendeesRow,
  locations: Dict(Uuid, Location),
) -> Activity {
  Activity(
    id: row.id,
    title: model.BilingualString(sv: row.title, en: row.title_en),
    description: model.BilingualString(
      sv: row.description,
      en: row.description_en,
    ),
    max_attendees: None,
    start_time: row.start_time,
    end_time: row.end_time,
    location: resolve_location(row.location_id, locations),
  )
}

pub fn from_search_activity_row(
  row: sql.SearchActivitiesRow,
  locations: Dict(Uuid, Location),
) -> Activity {
  Activity(
    id: row.id,
    title: model.BilingualString(sv: row.title, en: row.title_en),
    description: model.BilingualString(
      sv: row.description,
      en: row.description_en,
    ),
    max_attendees: row.max_attendees,
    start_time: row.start_time,
    end_time: row.end_time,
    location: resolve_location(row.location_id, locations),
  )
}

pub fn from_get_activity_row(
  row: sql.GetActivityRow,
  locations: Dict(Uuid, Location),
) -> Activity {
  Activity(
    id: row.id,
    title: model.BilingualString(sv: row.title, en: row.title_en),
    description: model.BilingualString(
      sv: row.description,
      en: row.description_en,
    ),
    max_attendees: row.max_attendees,
    start_time: row.start_time,
    end_time: row.end_time,
    location: resolve_location(row.location_id, locations),
  )
}

pub fn from_get_activities_by_title_row(
  row: sql.GetActivitiesByTitleRow,
  locations: Dict(Uuid, Location),
) -> Activity {
  Activity(
    id: row.id,
    title: model.BilingualString(sv: row.title, en: row.title_en),
    description: model.BilingualString(
      sv: row.description,
      en: row.description_en,
    ),
    max_attendees: row.max_attendees,
    start_time: row.start_time,
    end_time: row.end_time,
    location: resolve_location(row.location_id, locations),
  )
}

pub fn from_get_activities_by_start_time_row(
  row: sql.GetActivitiesByStartTimeRow,
  locations: Dict(Uuid, Location),
) -> Activity {
  Activity(
    id: row.id,
    title: model.BilingualString(sv: row.title, en: row.title_en),
    description: model.BilingualString(
      sv: row.description,
      en: row.description_en,
    ),
    max_attendees: row.max_attendees,
    start_time: row.start_time,
    end_time: row.end_time,
    location: resolve_location(row.location_id, locations),
  )
}

pub fn from_list_activities_by_title_row(
  row: sql.ListActivitiesByTitleRow,
  locations: Dict(Uuid, Location),
) -> Activity {
  Activity(
    id: row.id,
    title: model.BilingualString(sv: row.title, en: row.title_en),
    description: model.BilingualString(
      sv: row.description,
      en: row.description_en,
    ),
    max_attendees: row.max_attendees,
    start_time: row.start_time,
    end_time: row.end_time,
    location: resolve_location(row.location_id, locations),
  )
}

pub fn from_list_activities_by_start_time_row(
  row: sql.ListActivitiesByStartTimeRow,
  locations: Dict(Uuid, Location),
) -> Activity {
  Activity(
    id: row.id,
    title: model.BilingualString(sv: row.title, en: row.title_en),
    description: model.BilingualString(
      sv: row.description,
      en: row.description_en,
    ),
    max_attendees: row.max_attendees,
    start_time: row.start_time,
    end_time: row.end_time,
    location: resolve_location(row.location_id, locations),
  )
}

pub fn from_list_swim_bus_activities_row(
  row: sql.ListSwimBusActivitiesRow,
  locations: Dict(Uuid, Location),
) -> Activity {
  Activity(
    id: row.id,
    title: model.BilingualString(sv: row.title, en: row.title_en),
    description: model.BilingualString(
      sv: row.description,
      en: row.description_en,
    ),
    max_attendees: row.max_attendees,
    start_time: row.start_time,
    end_time: row.end_time,
    location: resolve_location(row.location_id, locations),
  )
}

pub fn from_list_climbing_wall_activities_row(
  row: sql.ListClimbingWallActivitiesRow,
  locations: Dict(Uuid, Location),
) -> Activity {
  Activity(
    id: row.id,
    title: model.BilingualString(sv: row.title, en: row.title_en),
    description: model.BilingualString(
      sv: row.description,
      en: row.description_en,
    ),
    max_attendees: row.max_attendees,
    start_time: row.start_time,
    end_time: row.end_time,
    location: resolve_location(row.location_id, locations),
  )
}

pub fn from_list_favourited_activities_row(
  row: sql.ListFavouritedActivitiesRow,
  locations: Dict(Uuid, Location),
) -> Activity {
  Activity(
    id: row.id,
    title: model.BilingualString(sv: row.title, en: row.title_en),
    description: model.BilingualString(
      sv: row.description,
      en: row.description_en,
    ),
    max_attendees: row.max_attendees,
    start_time: row.start_time,
    end_time: row.end_time,
    location: resolve_location(row.location_id, locations),
  )
}

pub fn from_update_activity_with_max_attendees_row(
  row: sql.UpdateActivityWithMaxAttendeesRow,
  locations: Dict(Uuid, Location),
) -> Activity {
  Activity(
    id: row.id,
    title: model.BilingualString(sv: row.title, en: row.title_en),
    description: model.BilingualString(
      sv: row.description,
      en: row.description_en,
    ),
    max_attendees: row.max_attendees,
    start_time: row.start_time,
    end_time: row.end_time,
    location: resolve_location(row.location_id, locations),
  )
}

pub fn from_update_activity_without_max_attendees_row(
  row: sql.UpdateActivityWithoutMaxAttendeesRow,
  locations: Dict(Uuid, Location),
) -> Activity {
  Activity(
    id: row.id,
    title: model.BilingualString(sv: row.title, en: row.title_en),
    description: model.BilingualString(
      sv: row.description,
      en: row.description_en,
    ),
    max_attendees: None,
    start_time: row.start_time,
    end_time: row.end_time,
    location: resolve_location(row.location_id, locations),
  )
}

pub fn to_json(activity: Activity) -> Json {
  let Activity(
    id:,
    title:,
    description:,
    max_attendees:,
    start_time:,
    end_time:,
    location:,
  ) = activity
  json.object([
    #("id", id |> uuid.to_string |> json.string),
    #("title", model.bilingual_string_to_json(title)),
    #("description", model.bilingual_string_to_json(description)),
    #("max_attendees", json.nullable(max_attendees, json.int)),
    #(
      "start_time",
      json.int(timestamp.to_unix_seconds(start_time) |> float.round),
    ),
    #("end_time", json.int(timestamp.to_unix_seconds(end_time) |> float.round)),
    #("location", json.nullable(location, location.to_json)),
  ])
}

/// Slim JSON for list views — omits `description` and embeds only the
/// location's `name` (via `location_name`) rather than the full location.
pub fn summary_to_json(activity: Activity) -> Json {
  let Activity(
    id:,
    title:,
    description: _,
    max_attendees:,
    start_time:,
    end_time:,
    location:,
  ) = activity
  json.object([
    #("id", id |> uuid.to_string |> json.string),
    #("title", model.bilingual_string_to_json(title)),
    #("max_attendees", json.nullable(max_attendees, json.int)),
    #(
      "start_time",
      json.int(timestamp.to_unix_seconds(start_time) |> float.round),
    ),
    #("end_time", json.int(timestamp.to_unix_seconds(end_time) |> float.round)),
    #(
      "location_name",
      json.nullable(
        location |> option.map(fn(l) { l.name }),
        model.bilingual_string_to_json,
      ),
    ),
  ])
}

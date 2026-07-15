import gleam/dict.{type Dict}
import gleam/float
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/time/timestamp
import server/model/location
import server/sql
import shared/model.{
  type Activity, type ActivityTag, type Location, type TargetGroup, Activity,
  ActivityTag,
}
import youid/uuid.{type Uuid}

/// Everything the activity handlers fetch once and stitch into activities so
/// each activity's location, tag ids and target groups can be embedded without
/// a per-activity query.
pub type Embeds {
  Embeds(
    locations: Dict(Uuid, Location),
    tags_by_activity: Dict(Uuid, List(Uuid)),
    target_groups_by_activity: Dict(Uuid, List(TargetGroup)),
    /// Call-off reason keyed by activity id. An entry means the activity is
    /// called off; its value is the reason shown to booked/favourited users.
    call_offs: Dict(Uuid, String),
  )
}

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

fn embed_tags(embeds: Embeds, id: Uuid) -> List(Uuid) {
  dict.get(embeds.tags_by_activity, id) |> result.unwrap([])
}

fn embed_target_groups(embeds: Embeds, id: Uuid) -> List(TargetGroup) {
  dict.get(embeds.target_groups_by_activity, id) |> result.unwrap([])
}

/// The activity's call-off reason, or `None` when it is not called off.
fn embed_cancellation(embeds: Embeds, id: Uuid) -> Option(String) {
  dict.get(embeds.call_offs, id) |> option.from_result
}

/// Groups call-off rows into a reason-by-activity map for embedding.
pub fn group_call_offs_by_activity(
  rows: List(sql.ListCallOffsRow),
) -> Dict(Uuid, String) {
  list.fold(rows, dict.new(), fn(acc, row) {
    dict.insert(acc, row.activity_id, row.reason)
  })
}

// --- sql <-> model target group mapping ------------------------------------

/// Map the Squirrel-generated `sql.TargetGroup` to the shared `TargetGroup`.
/// Total and exhaustive: if a value is added to the Postgres enum, Squirrel
/// regenerates `sql.TargetGroup` and this stops compiling until updated.
pub fn sql_target_group_to_model(target_group: sql.TargetGroup) -> TargetGroup {
  case target_group {
    sql.Sparare -> model.Sparare
    sql.Upptackare -> model.Upptackare
    sql.Aventyrare -> model.Aventyrare
    sql.Utmanare -> model.Utmanare
    sql.Rover -> model.Rover
  }
}

/// Map the shared `TargetGroup` to the Squirrel-generated `sql.TargetGroup` for
/// use as a query parameter.
pub fn model_target_group_to_sql(target_group: TargetGroup) -> sql.TargetGroup {
  case target_group {
    model.Sparare -> sql.Sparare
    model.Upptackare -> sql.Upptackare
    model.Aventyrare -> sql.Aventyrare
    model.Utmanare -> sql.Utmanare
    model.Rover -> sql.Rover
  }
}

// --- link grouping ---------------------------------------------------------

/// Groups tag links into the tag ids applied to each activity.
pub fn group_tags_by_activity(
  links: List(sql.ListActivityTagLinksRow),
) -> Dict(Uuid, List(Uuid)) {
  list.fold(links, dict.new(), fn(acc, link) {
    use existing <- dict.upsert(acc, link.activity_id)
    case existing {
      Some(tag_ids) -> [link.activity_tag_id, ..tag_ids]
      None -> [link.activity_tag_id]
    }
  })
}

/// Groups target-group links into the target groups applied to each activity,
/// mapping each row's `sql.TargetGroup` to the shared type.
pub fn group_target_groups_by_activity(
  links: List(sql.ListActivityTargetGroupsRow),
) -> Dict(Uuid, List(TargetGroup)) {
  list.fold(links, dict.new(), fn(acc, link) {
    let target_group = sql_target_group_to_model(link.target_group)
    use existing <- dict.upsert(acc, link.activity_id)
    case existing {
      Some(target_groups) -> [target_group, ..target_groups]
      None -> [target_group]
    }
  })
}

// --- activity row -> Activity ----------------------------------------------

pub fn from_create_activity_with_max_attendees_row(
  row: sql.CreateActivityWithMaxAttendeesRow,
  embeds: Embeds,
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
    location: resolve_location(row.location_id, embeds.locations),
    tags: embed_tags(embeds, row.id),
    target_groups: embed_target_groups(embeds, row.id),
    cancellation: embed_cancellation(embeds, row.id),
  )
}

pub fn from_create_activity_without_max_attendees_row(
  row: sql.CreateActivityWithoutMaxAttendeesRow,
  embeds: Embeds,
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
    location: resolve_location(row.location_id, embeds.locations),
    tags: embed_tags(embeds, row.id),
    target_groups: embed_target_groups(embeds, row.id),
    cancellation: embed_cancellation(embeds, row.id),
  )
}

pub fn from_search_activity_row(
  row: sql.SearchActivitiesRow,
  embeds: Embeds,
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
    location: resolve_location(row.location_id, embeds.locations),
    tags: embed_tags(embeds, row.id),
    target_groups: embed_target_groups(embeds, row.id),
    cancellation: embed_cancellation(embeds, row.id),
  )
}

pub fn from_get_activity_row(
  row: sql.GetActivityRow,
  embeds: Embeds,
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
    location: resolve_location(row.location_id, embeds.locations),
    tags: embed_tags(embeds, row.id),
    target_groups: embed_target_groups(embeds, row.id),
    cancellation: embed_cancellation(embeds, row.id),
  )
}

pub fn from_get_activities_by_title_row(
  row: sql.GetActivitiesByTitleRow,
  embeds: Embeds,
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
    location: resolve_location(row.location_id, embeds.locations),
    tags: embed_tags(embeds, row.id),
    target_groups: embed_target_groups(embeds, row.id),
    cancellation: embed_cancellation(embeds, row.id),
  )
}

pub fn from_get_activities_by_start_time_row(
  row: sql.GetActivitiesByStartTimeRow,
  embeds: Embeds,
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
    location: resolve_location(row.location_id, embeds.locations),
    tags: embed_tags(embeds, row.id),
    target_groups: embed_target_groups(embeds, row.id),
    cancellation: embed_cancellation(embeds, row.id),
  )
}

pub fn from_list_activities_by_title_row(
  row: sql.ListActivitiesByTitleRow,
  embeds: Embeds,
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
    location: resolve_location(row.location_id, embeds.locations),
    tags: embed_tags(embeds, row.id),
    target_groups: embed_target_groups(embeds, row.id),
    cancellation: embed_cancellation(embeds, row.id),
  )
}

pub fn from_list_activities_by_start_time_row(
  row: sql.ListActivitiesByStartTimeRow,
  embeds: Embeds,
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
    location: resolve_location(row.location_id, embeds.locations),
    tags: embed_tags(embeds, row.id),
    target_groups: embed_target_groups(embeds, row.id),
    cancellation: embed_cancellation(embeds, row.id),
  )
}

pub fn from_list_beach_bus_activities_row(
  row: sql.ListBeachBusActivitiesRow,
  embeds: Embeds,
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
    location: resolve_location(row.location_id, embeds.locations),
    tags: embed_tags(embeds, row.id),
    target_groups: embed_target_groups(embeds, row.id),
    cancellation: embed_cancellation(embeds, row.id),
  )
}

pub fn from_list_climbing_wall_activities_row(
  row: sql.ListClimbingWallActivitiesRow,
  embeds: Embeds,
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
    location: resolve_location(row.location_id, embeds.locations),
    tags: embed_tags(embeds, row.id),
    target_groups: embed_target_groups(embeds, row.id),
    cancellation: embed_cancellation(embeds, row.id),
  )
}

pub fn from_list_favourited_activities_row(
  row: sql.ListFavouritedActivitiesRow,
  embeds: Embeds,
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
    location: resolve_location(row.location_id, embeds.locations),
    tags: embed_tags(embeds, row.id),
    target_groups: embed_target_groups(embeds, row.id),
    cancellation: embed_cancellation(embeds, row.id),
  )
}

pub fn from_update_activity_with_max_attendees_row(
  row: sql.UpdateActivityWithMaxAttendeesRow,
  embeds: Embeds,
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
    location: resolve_location(row.location_id, embeds.locations),
    tags: embed_tags(embeds, row.id),
    target_groups: embed_target_groups(embeds, row.id),
    cancellation: embed_cancellation(embeds, row.id),
  )
}

pub fn from_update_activity_without_max_attendees_row(
  row: sql.UpdateActivityWithoutMaxAttendeesRow,
  embeds: Embeds,
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
    location: resolve_location(row.location_id, embeds.locations),
    tags: embed_tags(embeds, row.id),
    target_groups: embed_target_groups(embeds, row.id),
    cancellation: embed_cancellation(embeds, row.id),
  )
}

// --- activity tag row -> ActivityTag ---------------------------------------

pub fn from_list_activity_tags_row(
  row: sql.ListActivityTagsRow,
) -> ActivityTag {
  ActivityTag(
    id: row.id,
    name: model.BilingualString(sv: row.name, en: row.name_en),
  )
}

pub fn from_create_activity_tag_row(
  row: sql.CreateActivityTagRow,
) -> ActivityTag {
  ActivityTag(
    id: row.id,
    name: model.BilingualString(sv: row.name, en: row.name_en),
  )
}

pub fn from_get_activity_tag_row(row: sql.GetActivityTagRow) -> ActivityTag {
  ActivityTag(
    id: row.id,
    name: model.BilingualString(sv: row.name, en: row.name_en),
  )
}

pub fn from_update_activity_tag_row(
  row: sql.UpdateActivityTagRow,
) -> ActivityTag {
  ActivityTag(
    id: row.id,
    name: model.BilingualString(sv: row.name, en: row.name_en),
  )
}

// --- JSON ------------------------------------------------------------------

pub fn to_json(activity: Activity) -> Json {
  let Activity(
    id:,
    title:,
    description:,
    max_attendees:,
    start_time:,
    end_time:,
    location:,
    tags:,
    target_groups:,
    cancellation:,
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
    #("tags", json.array(tags, uuid_to_json)),
    #("target_groups", json.array(target_groups, model.target_group_to_json)),
    #("cancellation", json.nullable(cancellation, json.string)),
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
    tags:,
    target_groups:,
    cancellation:,
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
    #("tags", json.array(tags, uuid_to_json)),
    #("target_groups", json.array(target_groups, model.target_group_to_json)),
    #("cancellation", json.nullable(cancellation, json.string)),
  ])
}

pub fn activity_tag_to_json(tag: ActivityTag) -> Json {
  let ActivityTag(id:, name:) = tag
  json.object([
    #("id", id |> uuid.to_string |> json.string),
    #("name", model.bilingual_string_to_json(name)),
  ])
}

fn uuid_to_json(id: Uuid) -> Json {
  id |> uuid.to_string |> json.string
}

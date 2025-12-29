import gleam/json.{type Json}
import gleam/option.{type Option, None}
import gleam/time/timestamp.{type Timestamp}
import j26booking/sql
import youid/uuid.{type Uuid}

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

// --- CONVERTERS

pub fn from_create_activity_with_max_attendees_row(
  row: sql.CreateActivityWithMaxAttendeesRow,
) -> Activity {
  Activity(
    id: row.id,
    title: row.title,
    description: row.description,
    max_attendees: row.max_attendees,
    start_time: row.start_time,
    end_time: row.end_time,
  )
}

pub fn from_create_activity_without_max_attendees_row(
  row: sql.CreateActivityWithoutMaxAttendeesRow,
) -> Activity {
  Activity(
    id: row.id,
    title: row.title,
    description: row.description,
    max_attendees: None,
    start_time: row.start_time,
    end_time: row.end_time,
  )
}

pub fn from_search_activity_row(row: sql.SearchActivitiesRow) -> Activity {
  Activity(
    id: row.id,
    title: row.title,
    description: row.description,
    max_attendees: row.max_attendees,
    start_time: row.start_time,
    end_time: row.end_time,
  )
}

pub fn from_get_activity_row(row: sql.GetActivityRow) -> Activity {
  Activity(
    id: row.id,
    title: row.title,
    description: row.description,
    max_attendees: row.max_attendees,
    start_time: row.start_time,
    end_time: row.end_time,
  )
}

pub fn from_get_activities_by_title_row(
  row: sql.GetActivitiesByTitleRow,
) -> Activity {
  Activity(
    id: row.id,
    title: row.title,
    description: row.description,
    max_attendees: row.max_attendees,
    start_time: row.start_time,
    end_time: row.end_time,
  )
}

pub fn from_get_activities_by_start_time_row(
  row: sql.GetActivitiesByStartTimeRow,
) -> Activity {
  Activity(
    id: row.id,
    title: row.title,
    description: row.description,
    max_attendees: row.max_attendees,
    start_time: row.start_time,
    end_time: row.end_time,
  )
}

pub fn to_json(activity: Activity) -> Json {
  json.object([
    #("id", activity.id |> uuid.to_string |> json.string),
    #("title", json.string(activity.title)),
    #("description", json.string(activity.description)),
    #("max_attendees", json.nullable(activity.max_attendees, json.int)),
    #("start_time", json.float(timestamp.to_unix_seconds(activity.start_time))),
    #("end_time", json.float(timestamp.to_unix_seconds(activity.end_time))),
  ])
}

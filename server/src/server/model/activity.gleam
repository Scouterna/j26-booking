import gleam/float
import gleam/json.{type Json}
import gleam/option.{None}
import gleam/time/timestamp
import server/sql
import shared/model.{type Activity, Activity}
import youid/uuid

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

pub fn from_update_activity_with_max_attendees_row(
  row: sql.UpdateActivityWithMaxAttendeesRow,
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

pub fn from_update_activity_without_max_attendees_row(
  row: sql.UpdateActivityWithoutMaxAttendeesRow,
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

pub fn to_json(activity: Activity) -> Json {
  let Activity(
    id:,
    title:,
    description:,
    max_attendees:,
    start_time:,
    end_time:,
  ) = activity
  json.object([
    #("id", id |> uuid.to_string |> json.string),
    #("title", json.string(title)),
    #("description", json.string(description)),
    #("max_attendees", json.nullable(max_attendees, json.int)),
    #(
      "start_time",
      json.int(timestamp.to_unix_seconds(start_time) |> float.round),
    ),
    #("end_time", json.int(timestamp.to_unix_seconds(end_time) |> float.round)),
  ])
}

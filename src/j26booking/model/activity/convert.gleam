import gleam/option.{None}
import j26booking/model/activity.{type Activity, Activity}
import j26booking/sql

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

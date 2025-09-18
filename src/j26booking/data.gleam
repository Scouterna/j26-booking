import j26booking/sql

pub fn get_title(activity: sql.GetActivitiesRow) -> String {
  activity.title
}

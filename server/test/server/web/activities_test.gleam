import gleam/time/calendar
import gleam/time/duration
import gleam/time/timestamp
import server/web/activities

fn unix_seconds(ts: timestamp.Timestamp) -> Int {
  let #(secs, _) = timestamp.to_unix_seconds_and_nanoseconds(ts)
  secs
}

/// Stockholm is UTC+2 in late July (CEST), so local midnight on 25/7 is
/// 22:00 UTC on 24/7, and the window is exactly 24h wide.
pub fn day_bounds_stockholm_midnight_test() {
  let #(day_start, day_end) =
    activities.day_bounds(calendar.Date(2026, calendar.July, 25))

  // 2026-07-24 22:00:00 UTC
  assert unix_seconds(day_start) == 1_784_930_400
  // 2026-07-25 22:00:00 UTC
  assert unix_seconds(day_end) == 1_785_016_800
  assert unix_seconds(day_end) - unix_seconds(day_start) == 86_400
}

/// An activity at 23:30 Stockholm local on 25/7 (21:30 UTC) must fall inside
/// the 25/7 window — not the next day's — so late-evening activities bucket to
/// the correct local day.
pub fn day_bounds_late_evening_stays_in_day_test() {
  let #(day_start, day_end) =
    activities.day_bounds(calendar.Date(2026, calendar.July, 25))
  let late_evening =
    timestamp.from_calendar(
      calendar.Date(2026, calendar.July, 25),
      calendar.TimeOfDay(23, 30, 0, 0),
      offset: duration.hours(2),
    )
  let at = unix_seconds(late_evening)
  assert at >= unix_seconds(day_start)
  assert at < unix_seconds(day_end)
}

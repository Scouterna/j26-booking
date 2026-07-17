import gleam/list
import gleam/time/calendar.{Date}
import shared/event

pub fn event_days_are_the_eight_dates_in_order_test() {
  let days = event.event_days()
  assert list.length(days) == 8
  assert list.first(days) == Ok(event.event_first_day)
  assert list.last(days) == Ok(event.event_last_day)
  assert event.event_first_day == Date(2026, calendar.July, 25)
  assert event.event_last_day == Date(2026, calendar.August, 1)
}

pub fn clamp_snaps_dates_outside_the_range_test() {
  // Before the event -> first day.
  assert event.clamp_to_event(Date(2026, calendar.July, 1))
    == event.event_first_day
  // After the event -> last day.
  assert event.clamp_to_event(Date(2026, calendar.August, 15))
    == event.event_last_day
  // Within the range -> unchanged.
  assert event.clamp_to_event(Date(2026, calendar.July, 28))
    == Date(2026, calendar.July, 28)
  // Endpoints are inclusive.
  assert event.clamp_to_event(event.event_first_day) == event.event_first_day
  assert event.clamp_to_event(event.event_last_day) == event.event_last_day
}

pub fn iso_round_trips_test() {
  assert event.date_to_iso(Date(2026, calendar.July, 25)) == "2026-07-25"
  assert event.date_to_iso(Date(2026, calendar.August, 1)) == "2026-08-01"
  assert event.date_from_iso("2026-07-26") == Ok(Date(2026, calendar.July, 26))
}

pub fn iso_rejects_malformed_and_out_of_range_test() {
  assert event.date_from_iso("bogus") == Error(Nil)
  assert event.date_from_iso("2026-07") == Error(Nil)
  // A syntactically valid but impossible date is rejected.
  assert event.date_from_iso("2026-13-40") == Error(Nil)
}

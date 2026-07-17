//// Fixed calendar of Jamboree 2026 — the single source of truth for the event
//// date range shared by the client (day dropdown, default day, clamping) and
//// the server (day-window param validation). The dates are hard-coded, not
//// derived from data: the Jamboree runs 25 Jul – 1 Aug 2026 (Fri 25/7 …
//// Fri 1/8), 8 days.

import gleam/int
import gleam/order
import gleam/result
import gleam/string
import gleam/time/calendar.{type Date, Date}

/// First day of the event (25 Jul 2026).
pub const event_first_day = Date(2026, calendar.July, 25)

/// Last day of the event (1 Aug 2026).
pub const event_last_day = Date(2026, calendar.August, 1)

/// The 8 event dates in order, 25/7 … 1/8. Hard-coded (crosses a month
/// boundary) so both targets agree without date arithmetic.
pub fn event_days() -> List(Date) {
  [
    Date(2026, calendar.July, 25),
    Date(2026, calendar.July, 26),
    Date(2026, calendar.July, 27),
    Date(2026, calendar.July, 28),
    Date(2026, calendar.July, 29),
    Date(2026, calendar.July, 30),
    Date(2026, calendar.July, 31),
    Date(2026, calendar.August, 1),
  ]
}

/// Clamp any date into `[event_first_day, event_last_day]`: dates before the
/// event snap to the first day, dates after snap to the last, dates within pass
/// through. Used to pick a sensible default day from "today".
pub fn clamp_to_event(date: Date) -> Date {
  case calendar.naive_date_compare(date, event_first_day) {
    order.Lt -> event_first_day
    _ ->
      case calendar.naive_date_compare(date, event_last_day) {
        order.Gt -> event_last_day
        _ -> date
      }
  }
}

/// Format a date as an ISO `YYYY-MM-DD` string — the `?day=` query param and
/// dropdown value format shared by client and server.
pub fn date_to_iso(date: Date) -> String {
  pad(date.year, 4)
  <> "-"
  <> pad(calendar.month_to_int(date.month), 2)
  <> "-"
  <> pad(date.day, 2)
}

/// Parse an ISO `YYYY-MM-DD` string into a valid calendar date. Returns `Error`
/// on a malformed or out-of-range value (e.g. `2026-13-40`).
pub fn date_from_iso(raw: String) -> Result(Date, Nil) {
  case string.split(raw, "-") {
    [year_str, month_str, day_str] -> {
      use year <- result.try(int.parse(year_str))
      use month_int <- result.try(int.parse(month_str))
      use day <- result.try(int.parse(day_str))
      use month <- result.try(calendar.month_from_int(month_int))
      let date = Date(year, month, day)
      case calendar.is_valid_date(date) {
        True -> Ok(date)
        False -> Error(Nil)
      }
    }
    _ -> Error(Nil)
  }
}

fn pad(value: Int, width: Int) -> String {
  int.to_string(value) |> string.pad_start(to: width, with: "0")
}

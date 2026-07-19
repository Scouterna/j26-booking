import gleam/option.{None, Some}
import gleam/time/timestamp.{type Timestamp}
import shared/model

fn at(unix_seconds: Int) -> Timestamp {
  timestamp.from_unix_seconds(unix_seconds)
}

// The booking window under test (issues #35 + #36): opens at 1000, activity
// runs 2000–3000. Both bounds are inclusive.

/// Before the opens-at the window is closed and reports when it opens.
pub fn booking_window_before_opens_at_test() {
  assert model.booking_window(
      now: at(999),
      opens_at: Some(at(1000)),
      start_time: at(2000),
      end_time: Some(at(3000)),
    )
    == model.BookingNotYetOpen(at(1000))
}

/// Exactly at the opens-at, booking is open (inclusive bound).
pub fn booking_window_exactly_at_opens_at_test() {
  assert model.booking_window(
      now: at(1000),
      opens_at: Some(at(1000)),
      start_time: at(2000),
      end_time: Some(at(3000)),
    )
    == model.BookingOpen
}

/// Between opens-at and the end the window is open — including while the
/// activity is running (issue #35: bookable until its end time).
pub fn booking_window_open_during_activity_test() {
  assert model.booking_window(
      now: at(2500),
      opens_at: Some(at(1000)),
      start_time: at(2000),
      end_time: Some(at(3000)),
    )
    == model.BookingOpen
}

/// Exactly at the end time booking is still allowed (inclusive bound).
pub fn booking_window_exactly_at_end_test() {
  assert model.booking_window(
      now: at(3000),
      opens_at: Some(at(1000)),
      start_time: at(2000),
      end_time: Some(at(3000)),
    )
    == model.BookingOpen
}

/// After the end time the activity has passed.
pub fn booking_window_after_end_test() {
  assert model.booking_window(
      now: at(3001),
      opens_at: Some(at(1000)),
      start_time: at(2000),
      end_time: Some(at(3000)),
    )
    == model.BookingClosed
}

/// Without an end time (issue #39, once end times become optional) the start
/// time is the cutoff.
pub fn booking_window_no_end_time_cutoff_is_start_test() {
  assert model.booking_window(
      now: at(2001),
      opens_at: None,
      start_time: at(2000),
      end_time: None,
    )
    == model.BookingClosed
  assert model.booking_window(
      now: at(2000),
      opens_at: None,
      start_time: at(2000),
      end_time: None,
    )
    == model.BookingOpen
}

/// No opens-at (no override and no global default) means booking is open
/// immediately — today's behaviour.
pub fn booking_window_no_opens_at_is_open_test() {
  assert model.booking_window(
      now: at(0),
      opens_at: None,
      start_time: at(2000),
      end_time: Some(at(3000)),
    )
    == model.BookingOpen
}

/// A misconfigured opens-at after the activity's end: the not-yet-open check
/// runs first, so that is what is reported. Either way the activity is
/// unbookable, which is what matters.
pub fn booking_window_opens_at_after_end_test() {
  assert model.booking_window(
      now: at(3500),
      opens_at: Some(at(4000)),
      start_time: at(2000),
      end_time: Some(at(3000)),
    )
    == model.BookingNotYetOpen(at(4000))
}

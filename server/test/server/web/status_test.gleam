import gleam/dict
import gleam/option.{None}
import server/web/status
import shared/model
import youid/uuid.{type Uuid}

fn parse_uuid(s: String) -> Uuid {
  let assert Ok(id) = uuid.from_string(s)
  id
}

fn activity_a() -> Uuid {
  parse_uuid("00000000-0000-4000-8000-00000000000a")
}

fn activity_b() -> Uuid {
  parse_uuid("00000000-0000-4000-8000-00000000000b")
}

fn a_booking(id: String, activity_id: Uuid) -> model.Booking {
  model.Booking(
    id: parse_uuid(id),
    user_id: parse_uuid("00000000-0000-4000-8000-000000000001"),
    activity_id:,
    booker_name: "Test",
    booker_group_id: None,
    booker_group_name: None,
    group_free_text: "",
    responsible_name: "Test",
    phone_number: "0700000000",
    participant_count: 1,
    booked_for_other: False,
    cancellation: None,
  )
}

/// Two bookings on one activity collapse into a single bucket, keeping their
/// row order, while a booking on another activity gets its own bucket — so
/// `/api/statuses/me` emits exactly one `booked` entry per activity.
pub fn groups_bookings_per_activity_test() {
  let first = a_booking("00000000-0000-4000-8000-000000000011", activity_a())
  let second = a_booking("00000000-0000-4000-8000-000000000012", activity_a())
  let elsewhere =
    a_booking("00000000-0000-4000-8000-000000000013", activity_b())

  let grouped = status.group_by_activity([first, second, elsewhere])

  assert dict.size(grouped) == 2
  assert dict.get(grouped, activity_a()) == Ok([first, second])
  assert dict.get(grouped, activity_b()) == Ok([elsewhere])
}

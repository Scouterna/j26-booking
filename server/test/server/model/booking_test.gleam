import gleam/option.{None, Some}
import gleam/time/timestamp
import server/model/booking
import server/sql
import shared/model
import youid/uuid

fn parse_uuid(s: String) -> uuid.Uuid {
  let assert Ok(id) = uuid.from_string(s)
  id
}

fn row(
  activity_id: uuid.Uuid,
  group_id: option.Option(Int),
  group_name: option.Option(String),
  group_count: Int,
  booking_count: Int,
) -> sql.ListRecurringBookingsOverviewRow {
  sql.ListRecurringBookingsOverviewRow(
    activity_id:,
    start_time: timestamp.from_unix_seconds(1000),
    end_time: timestamp.from_unix_seconds(2000),
    max_attendees: Some(45),
    booker_group_id: group_id,
    booker_group_name: group_name,
    group_count:,
    booking_count:,
  )
}

/// Rows for one activity collapse into a single slot; `total_booked` sums the
/// per-group counts and the groups carry through in row order.
pub fn groups_a_slot_and_sums_total_test() {
  let id = parse_uuid("6f5e1d46-5f58-4e23-9a9d-8c2bfc2d22a0")
  let slots =
    booking.from_recurring_overview_rows([
      row(id, Some(1), Some("Abbekås"), 3, 1),
      row(id, Some(3), Some("Ölagets Scoutkår"), 40, 2),
    ])

  assert slots
    == [
      model.BookingSlot(
        activity_id: id,
        start_time: timestamp.from_unix_seconds(1000),
        end_time: timestamp.from_unix_seconds(2000),
        max_attendees: Some(45),
        total_booked: 43,
        groups: [
          model.GroupCount(Some(1), Some("Abbekås"), 3),
          model.GroupCount(Some(3), Some("Ölagets Scoutkår"), 40),
        ],
      ),
    ]
}

/// A LEFT JOIN placeholder row (booking_count == 0) yields a slot with no
/// bookings — empty groups and a zero total — rather than a bogus group entry.
pub fn empty_slot_has_no_groups_test() {
  let id = parse_uuid("00000000-0000-4000-8000-000000000001")
  let slots = booking.from_recurring_overview_rows([row(id, None, None, 0, 0)])

  assert slots
    == [
      model.BookingSlot(
        activity_id: id,
        start_time: timestamp.from_unix_seconds(1000),
        end_time: timestamp.from_unix_seconds(2000),
        max_attendees: Some(45),
        total_booked: 0,
        groups: [],
      ),
    ]
}

/// A booking made without a kår (null group columns, but booking_count > 0) is
/// kept as an unknown-group entry, not dropped.
pub fn unknown_group_booking_is_kept_test() {
  let id = parse_uuid("00000000-0000-4000-8000-000000000002")
  let slots = booking.from_recurring_overview_rows([row(id, None, None, 5, 1)])

  let assert [model.BookingSlot(groups: groups, total_booked: total, ..)] =
    slots
  assert total == 5
  assert groups == [model.GroupCount(None, None, 5)]
}

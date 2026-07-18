import gleam/option.{None, Some}
import server/web
import server/web/booking
import shared/model
import youid/uuid.{type Uuid}

fn parse_uuid(s: String) -> Uuid {
  let assert Ok(id) = uuid.from_string(s)
  id
}

fn owner_id() -> Uuid {
  parse_uuid("00000000-0000-4000-8000-00000000000a")
}

fn other_id() -> Uuid {
  parse_uuid("00000000-0000-4000-8000-00000000000b")
}

fn a_user(id: Uuid, roles: List(web.Role)) -> web.User {
  web.User(id:, name: "Test", roles:, group_id: None)
}

fn a_booking(user_id: Uuid, booked_for_other: Bool) -> model.Booking {
  model.Booking(
    id: parse_uuid("00000000-0000-4000-8000-000000000001"),
    user_id:,
    activity_id: parse_uuid("00000000-0000-4000-8000-000000000002"),
    booker_name: "Test",
    booker_group_id: Some(1102),
    booker_group_name: Some("Adolf Fredriks Scoutkår"),
    group_free_text: "",
    responsible_name: "Test",
    phone_number: "0700000000",
    participant_count: 1,
    booked_for_other:,
  )
}

/// A self-booking is managed by its owner only.
pub fn self_booking_managed_by_owner_test() {
  let booking = a_booking(owner_id(), False)
  assert booking.may_manage(a_user(owner_id(), []), booking)
  assert !booking.may_manage(a_user(other_id(), []), booking)
}

/// bookings:others:create does NOT grant managing other users' self-bookings.
pub fn self_booking_not_managed_by_role_holder_test() {
  let booking = a_booking(owner_id(), False)
  assert !booking.may_manage(
    a_user(other_id(), [web.BookingsOthersCreate]),
    booking,
  )
}

/// On-behalf bookings are team-managed: any bookings:others:create holder may
/// manage them — including ones created by someone else — but a user without
/// the role may not manage even their own.
pub fn for_other_booking_managed_by_any_role_holder_test() {
  let booking = a_booking(owner_id(), True)
  assert booking.may_manage(
    a_user(other_id(), [web.BookingsOthersCreate]),
    booking,
  )
  assert !booking.may_manage(a_user(owner_id(), []), booking)
}

/// Admin overrides both rules.
pub fn admin_manages_everything_test() {
  assert booking.may_manage(
    a_user(other_id(), [web.Admin]),
    a_booking(owner_id(), False),
  )
  assert booking.may_manage(
    a_user(other_id(), [web.Admin]),
    a_booking(owner_id(), True),
  )
}

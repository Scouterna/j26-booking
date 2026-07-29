import gleam/erlang/process
import gleam/http
import gleam/json
import gleam/option.{None, Some}
import pog
import server/web
import server/web/booking
import shared/model
import wisp
import wisp/simulate
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
    cancellation: None,
    left_campsite: False,
    left_beach: False,
  )
}

/// A self-booking is managed by its owner only.
pub fn self_booking_managed_by_owner_test() {
  let booking = a_booking(owner_id(), False)
  assert booking.may_manage(a_user(owner_id(), []), booking)
  assert !booking.may_manage(a_user(other_id(), []), booking)
}

/// bookings:others:create grants managing other users' self-bookings too;
/// a role-less non-owner still may not.
pub fn self_booking_managed_by_role_holder_test() {
  let booking = a_booking(owner_id(), False)
  assert booking.may_manage(
    a_user(other_id(), [web.BookingsOthersCreate]),
    booking,
  )
  assert !booking.may_manage(a_user(other_id(), []), booking)
}

/// On-behalf bookings are managed by any bookings:others:create holder —
/// including ones created by someone else — and by their owner even without
/// the role (they created it while holding it; ownership is enough).
pub fn for_other_booking_managed_by_any_role_holder_test() {
  let booking = a_booking(owner_id(), True)
  assert booking.may_manage(
    a_user(other_id(), [web.BookingsOthersCreate]),
    booking,
  )
  assert booking.may_manage(a_user(owner_id(), []), booking)
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

// --- Badbuss departure check-offs ------------------------------------------
//
// The guards these exercise (auth, role, id format, body shape) all
// short-circuit before any query, so the unusable connection below is never
// touched. The badbuss-only 409 and the write itself need a live database and
// are verified against the running app instead.

/// The db connection is a value-level requirement of `Context` only — see the
/// note above.
fn context_with_auth(auth: web.AuthenticationResult) -> web.Context {
  web.Context(
    static_directory: "",
    db_connection: pog.named_connection(process.new_name("unused_db")),
    jwt_verify_keys: web.JWTVerifyKeys("", []),
    authentication_result: auth,
    dev_fallback_user: None,
    booking_opens_at: None,
  )
}

fn a_tick() -> wisp.Request {
  simulate.request(http.Put, "/")
  |> simulate.json_body(json.object([#("checked", json.bool(True))]))
}

const a_booking_id = "dd000001-0000-4000-8000-000000000001"

pub fn departure_check_requires_authentication_test() {
  let response =
    booking.set_left_campsite(
      a_tick(),
      a_booking_id,
      context_with_auth(web.NotAuthenticated),
    )
  assert response.status == 401
}

/// A plain booker — `bookings:self:create` only — cannot tick anyone off: the
/// check-offs belong to whoever runs the bus, and a booker cannot even read
/// the slot's list.
pub fn departure_check_forbidden_for_plain_booker_test() {
  let response =
    booking.set_left_campsite(
      a_tick(),
      a_booking_id,
      context_with_auth(
        web.Authenticated(a_user(owner_id(), [web.BookingsSelfCreate])),
      ),
    )
  assert response.status == 403
  let beach =
    booking.set_left_beach(
      a_tick(),
      a_booking_id,
      context_with_auth(
        web.Authenticated(a_user(owner_id(), [web.BookingsSelfCreate])),
      ),
    )
  assert beach.status == 403
}

/// Read access to the badbuss lists is what grants the write, so a
/// `bookings:read` holder gets past the role guard (and is stopped by the next
/// guard, not by 403).
pub fn departure_check_allows_bookings_read_test() {
  let response =
    booking.set_left_campsite(
      a_tick(),
      "not-a-uuid",
      context_with_auth(
        web.Authenticated(a_user(owner_id(), [web.BookingsRead])),
      ),
    )
  assert response.status == 400
}

pub fn departure_check_rejects_malformed_booking_id_test() {
  let response =
    booking.set_left_beach(
      a_tick(),
      "not-a-uuid",
      context_with_auth(
        web.Authenticated(a_user(owner_id(), [web.ActivitiesManage])),
      ),
    )
  assert response.status == 400
}

/// A body without the `checked` flag is a bad request — the endpoint never
/// guesses which way to set the box.
pub fn departure_check_rejects_body_without_checked_test() {
  let request =
    simulate.request(http.Put, "/") |> simulate.json_body(json.object([]))
  let response =
    booking.set_left_campsite(
      request,
      a_booking_id,
      context_with_auth(
        web.Authenticated(a_user(owner_id(), [web.BookingsRead])),
      ),
    )
  assert response.status == 400
}

/// Only PUT ticks a check-off.
pub fn departure_check_rejects_other_methods_test() {
  let response =
    booking.set_left_campsite(
      simulate.request(http.Post, "/"),
      a_booking_id,
      context_with_auth(
        web.Authenticated(a_user(owner_id(), [web.BookingsRead])),
      ),
    )
  assert response.status == 405
}

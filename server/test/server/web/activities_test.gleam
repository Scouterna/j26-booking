import gleam/erlang/process
import gleam/http
import gleam/option.{None}
import pog
import server/web
import server/web/activities
import wisp/simulate
import youid/uuid

const test_user_id = "3ae85c94-5d76-4d43-ab18-a3521d9ed479"

/// The db connection is a value-level requirement of `Context` only; the
/// `include_call_offs` guard short-circuits before any query runs, which is
/// exactly what these tests exercise. The anonymous default-view 200 (issue
/// #20) needs a live database and is verified live instead.
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

fn user_with_roles(roles: List(web.Role)) -> web.User {
  let assert Ok(id) = uuid.from_string(test_user_id)
  web.User(id:, name: "Test User", roles:, group_id: None)
}

// The browse lists are anonymous-accessible, but the manager-only
// `include_call_offs=true` view still authenticates: 401 without a token,
// 403 without the `activities:manage` role.

pub fn call_offs_view_requires_authentication_test() {
  let request = simulate.request(http.Get, "/?include_call_offs=true")
  let response =
    activities.get_page(request, context_with_auth(web.NotAuthenticated))
  assert response.status == 401
}

pub fn call_offs_view_forbidden_for_non_manager_test() {
  let request = simulate.request(http.Get, "/?include_call_offs=true")
  let response =
    activities.get_page(
      request,
      context_with_auth(
        web.Authenticated(user_with_roles([web.BookingsSelfCreate])),
      ),
    )
  assert response.status == 403
}

pub fn beach_bus_call_offs_view_requires_authentication_test() {
  let request = simulate.request(http.Get, "/?include_call_offs=true")
  let response =
    activities.get_beach_bus(request, context_with_auth(web.NotAuthenticated))
  assert response.status == 401
}

pub fn beach_bus_call_offs_view_forbidden_for_non_manager_test() {
  let request = simulate.request(http.Get, "/?include_call_offs=true")
  let response =
    activities.get_beach_bus(
      request,
      context_with_auth(
        web.Authenticated(user_with_roles([web.BookingsSelfCreate])),
      ),
    )
  assert response.status == 403
}

pub fn climbing_wall_call_offs_view_requires_authentication_test() {
  let request = simulate.request(http.Get, "/?include_call_offs=true")
  let response =
    activities.get_climbing_wall(
      request,
      context_with_auth(web.NotAuthenticated),
    )
  assert response.status == 401
}

pub fn climbing_wall_call_offs_view_forbidden_for_non_manager_test() {
  let request = simulate.request(http.Get, "/?include_call_offs=true")
  let response =
    activities.get_climbing_wall(
      request,
      context_with_auth(
        web.Authenticated(user_with_roles([web.BookingsSelfCreate])),
      ),
    )
  assert response.status == 403
}

pub fn malformed_call_offs_param_is_rejected_before_auth_test() {
  // A malformed value is a 400 regardless of authentication, so anonymous
  // callers get parameter feedback rather than a misleading 401.
  let request = simulate.request(http.Get, "/?include_call_offs=yes")
  let response =
    activities.get_page(request, context_with_auth(web.NotAuthenticated))
  assert response.status == 400
}

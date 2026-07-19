import gleam/erlang/process
import gleam/option.{None}
import gleam/string
import pog
import server/router
import server/web
import wisp/simulate
import youid/uuid

const test_user_id = "3ae85c94-5d76-4d43-ab18-a3521d9ed479"

/// The db connection is a value-level requirement of `Context` only; the
/// documentation handlers read the authentication result and never query it.
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

// The API documentation is internal detail (issue #46): the page and the
// spec it renders are both admin-only.

pub fn api_documentation_requires_authentication_test() {
  let response =
    router.api_documentation(context_with_auth(web.NotAuthenticated))
  assert response.status == 401
}

pub fn api_documentation_forbidden_for_non_admin_test() {
  let response =
    router.api_documentation(
      context_with_auth(
        web.Authenticated(user_with_roles([web.BookingsSelfCreate])),
      ),
    )
  assert response.status == 403
}

pub fn api_documentation_served_to_admin_test() {
  let response =
    router.api_documentation(
      context_with_auth(web.Authenticated(user_with_roles([web.Admin]))),
    )
  assert response.status == 200
  assert string.contains(simulate.read_body(response), "Scalar")
}

pub fn api_documentation_spec_requires_authentication_test() {
  let response =
    router.api_documentation_spec(context_with_auth(web.NotAuthenticated))
  assert response.status == 401
}

pub fn api_documentation_spec_forbidden_for_non_admin_test() {
  let response =
    router.api_documentation_spec(
      context_with_auth(
        web.Authenticated(user_with_roles([web.BookingsSelfCreate])),
      ),
    )
  assert response.status == 403
}

pub fn api_documentation_spec_served_to_admin_test() {
  let response =
    router.api_documentation_spec(
      context_with_auth(web.Authenticated(user_with_roles([web.Admin]))),
    )
  assert response.status == 200
  assert string.contains(simulate.read_body(response), "openapi:")
}

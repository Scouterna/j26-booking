import gleam/erlang/process
import gleam/option.{None}
import gleam/string
import pog
import server/web
import server/web/app_config
import wisp/simulate
import youid/uuid

const test_user_id = "3ae85c94-5d76-4d43-ab18-a3521d9ed479"

/// The db connection is a value-level requirement of `Context` only;
/// `navigation` reads the authentication result and never queries the db.
fn context_with_auth(auth: web.AuthenticationResult) -> web.Context {
  web.Context(
    static_directory: "",
    db_connection: pog.named_connection(process.new_name("unused_db")),
    jwt_verify_keys: web.JWTVerifyKeys("", []),
    authentication_result: auth,
    dev_fallback_user: None,
  )
}

fn user_with_roles(roles: List(web.Role)) -> web.User {
  let assert Ok(id) = uuid.from_string(test_user_id)
  web.User(id:, name: "Test User", roles:, group_id: None)
}

fn navigation_body(auth: web.AuthenticationResult) -> String {
  app_config.navigation(context_with_auth(auth)) |> simulate.read_body
}

pub fn navigation_includes_manage_item_for_manager_test() {
  let body =
    navigation_body(web.Authenticated(user_with_roles([web.ActivitiesManage])))
  assert string.contains(body, "page_activities")
  assert string.contains(body, "page_manage_activities")
}

pub fn navigation_includes_manage_item_for_admin_test() {
  // Admin implies every role, so the manage item shows for admins too.
  let body = navigation_body(web.Authenticated(user_with_roles([web.Admin])))
  assert string.contains(body, "page_manage_activities")
}

pub fn navigation_omits_manage_item_for_non_manager_test() {
  let body =
    navigation_body(
      web.Authenticated(user_with_roles([web.BookingsSelfCreate])),
    )
  assert string.contains(body, "page_activities")
  assert !string.contains(body, "page_manage_activities")
}

pub fn navigation_omits_manage_item_for_anonymous_test() {
  let body = navigation_body(web.NotAuthenticated)
  assert string.contains(body, "page_activities")
  assert !string.contains(body, "page_manage_activities")
}

pub fn navigation_includes_overview_items_for_bookings_reader_test() {
  // `bookings:read` gates the Badbuss / Klättervägg overviews, and is separate
  // from managing activities: a reader sees the overviews but not the manage
  // item.
  let body =
    navigation_body(web.Authenticated(user_with_roles([web.BookingsRead])))
  assert string.contains(body, "page_beach_bus_bookings")
  assert string.contains(body, "page_climbing_wall_bookings")
  assert !string.contains(body, "page_manage_activities")
}

pub fn navigation_includes_overview_items_for_manager_test() {
  // `activities:manage` also grants the overviews, so a manager sees both the
  // manage item and the overviews.
  let body =
    navigation_body(web.Authenticated(user_with_roles([web.ActivitiesManage])))
  assert string.contains(body, "page_manage_activities")
  assert string.contains(body, "page_beach_bus_bookings")
  assert string.contains(body, "page_climbing_wall_bookings")
}

pub fn navigation_includes_overview_items_for_admin_test() {
  // Admin implies every role, so the overviews show for admins too.
  let body = navigation_body(web.Authenticated(user_with_roles([web.Admin])))
  assert string.contains(body, "page_beach_bus_bookings")
  assert string.contains(body, "page_climbing_wall_bookings")
}

pub fn navigation_omits_overview_items_for_non_reader_test() {
  let body =
    navigation_body(
      web.Authenticated(user_with_roles([web.BookingsSelfCreate])),
    )
  assert string.contains(body, "page_activities")
  assert !string.contains(body, "page_beach_bus_bookings")
  assert !string.contains(body, "page_climbing_wall_bookings")
}

pub fn navigation_omits_overview_items_for_anonymous_test() {
  let body = navigation_body(web.NotAuthenticated)
  assert !string.contains(body, "page_beach_bus_bookings")
  assert !string.contains(body, "page_climbing_wall_bookings")
}

import gleam/http.{Delete, Get, Post, Put}
import lustre/element
import server/web.{type Context}
import server/web/account
import server/web/activities
import server/web/app_config
import server/web/booking
import server/web/favourite
import server/web/location
import server/web/spots
import server/web/status
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  use req, ctx <- web.middleware(req, ctx)
  case wisp.path_segments(req) {
    ["_services", "booking", "api", ..rest] ->
      handle_api_request(req, ctx, rest)
    _ -> spa_shell()
  }
}

fn handle_api_request(
  req: Request,
  ctx: Context,
  path_segments: List(String),
) -> Response {
  case req.method, path_segments {
    Get, ["activities"] -> activities.get_page(req, ctx)
    Post, ["activities"] -> activities.create(req, ctx)
    _, ["activities"] -> wisp.method_not_allowed([Get, Post])
    Get, ["beach-bus-activities"] -> activities.get_beach_bus(req, ctx)
    _, ["beach-bus-activities"] -> wisp.method_not_allowed([Get])
    Get, ["climbing-wall-activities"] -> activities.get_climbing_wall(req, ctx)
    _, ["climbing-wall-activities"] -> wisp.method_not_allowed([Get])
    Get, ["beach-bus-bookings"] -> booking.get_beach_bus_overview(req, ctx)
    _, ["beach-bus-bookings"] -> wisp.method_not_allowed([Get])
    Get, ["climbing-wall-bookings"] ->
      booking.get_climbing_wall_overview(req, ctx)
    _, ["climbing-wall-bookings"] -> wisp.method_not_allowed([Get])
    Get, ["favourited-activities"] -> activities.get_favourited(req, ctx)
    _, ["favourited-activities"] -> wisp.method_not_allowed([Get])
    Get, ["activity-spots"] -> spots.get_all(req, ctx)
    _, ["activity-spots"] -> wisp.method_not_allowed([Get])
    Get, ["activities", activity_id, "spots"] ->
      spots.get_one(req, activity_id, ctx)
    _, ["activities", _, "spots"] -> wisp.method_not_allowed([Get])
    Get, ["activities", activity_id, "bookings"] ->
      booking.get_by_activity(req, activity_id, ctx)
    Post, ["activities", activity_id, "bookings"] ->
      booking.create(req, activity_id, ctx)
    _, ["activities", _, "bookings"] -> wisp.method_not_allowed([Get, Post])
    Put, ["activities", activity_id, "favourite"] ->
      favourite.put(req, activity_id, ctx)
    Delete, ["activities", activity_id, "favourite"] ->
      favourite.delete(req, activity_id, ctx)
    _, ["activities", _, "favourite"] -> wisp.method_not_allowed([Put, Delete])
    Post, ["activities", activity_id, "cancel"] ->
      activities.cancel(req, activity_id, ctx)
    _, ["activities", _, "cancel"] -> wisp.method_not_allowed([Post])
    Get, ["activity-tags"] -> activities.get_tags(req, ctx)
    Post, ["activity-tags"] -> activities.create_tag(req, ctx)
    _, ["activity-tags"] -> wisp.method_not_allowed([Get, Post])
    Get, ["activity-tags", id] -> activities.get_tag(req, id, ctx)
    Put, ["activity-tags", id] -> activities.update_tag(req, id, ctx)
    Delete, ["activity-tags", id] -> activities.delete_tag(req, id, ctx)
    _, ["activity-tags", _] -> wisp.method_not_allowed([Get, Put, Delete])
    Get, ["activities", id] -> activities.get_one(req, id, ctx)
    Put, ["activities", id] -> activities.update(req, id, ctx)
    Delete, ["activities", id] -> activities.delete(req, id, ctx)
    _, ["activities", _] -> wisp.method_not_allowed([Get, Put, Delete])
    Get, ["me"] -> account.get_me(req, ctx)
    _, ["me"] -> wisp.method_not_allowed([Get])
    Get, ["statuses", "me"] -> status.get_mine(req, ctx)
    _, ["statuses", "me"] -> wisp.method_not_allowed([Get])
    Get, ["bookings", id] -> booking.get_one(req, id, ctx)
    Put, ["bookings", id] -> booking.update(req, id, ctx)
    Delete, ["bookings", id] -> booking.delete(req, id, ctx)
    _, ["bookings", _] -> wisp.method_not_allowed([Get, Put, Delete])
    Get, ["locations"] -> location.get_all(req, ctx)
    Post, ["locations"] -> location.create(req, ctx)
    _, ["locations"] -> wisp.method_not_allowed([Get, Post])
    Get, ["locations", id] -> location.get_one(req, id, ctx)
    Put, ["locations", id] -> location.update(req, id, ctx)
    Delete, ["locations", id] -> location.delete(req, id, ctx)
    _, ["locations", _] -> wisp.method_not_allowed([Get, Put, Delete])
    Get, ["location-tags"] -> location.get_tags(req, ctx)
    Post, ["location-tags"] -> location.create_tag(req, ctx)
    _, ["location-tags"] -> wisp.method_not_allowed([Get, Post])
    Get, ["location-tags", id] -> location.get_tag(req, id, ctx)
    Put, ["location-tags", id] -> location.update_tag(req, id, ctx)
    Delete, ["location-tags", id] -> location.delete_tag(req, id, ctx)
    _, ["location-tags", _] -> wisp.method_not_allowed([Get, Put, Delete])
    Get, ["app-config"] -> app_config.navigation(ctx)
    _, ["app-config"] -> wisp.method_not_allowed([Get])
    Get, ["docs"] -> api_documentation()
    _, ["docs"] -> wisp.method_not_allowed([Get])
    _, _ -> wisp.not_found()
  }
}

fn spa_shell() -> Response {
  web.spa_shell_page()
  |> element.to_string
  |> wisp.html_response(200)
}

fn api_documentation() -> Response {
  web.api_documentation_page()
  |> element.to_string
  |> wisp.html_response(200)
}

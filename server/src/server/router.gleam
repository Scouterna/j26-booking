import gleam/http.{Delete, Get, Post, Put}
import lustre/element
import server/web.{type Context}
import server/web/activities
import server/web/app_config
import server/web/booking
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
    Get, ["activities", activity_id, "bookings"] ->
      booking.get_by_activity(req, activity_id, ctx)
    Post, ["activities", activity_id, "bookings"] ->
      booking.create(req, activity_id, ctx)
    _, ["activities", _, "bookings"] -> wisp.method_not_allowed([Get, Post])
    Get, ["activities", id] -> activities.get_one(req, id, ctx)
    Put, ["activities", id] -> activities.update(req, id, ctx)
    Delete, ["activities", id] -> activities.delete(req, id, ctx)
    _, ["activities", _] -> wisp.method_not_allowed([Get, Put, Delete])
    Get, ["bookings", id] -> booking.get_one(req, id, ctx)
    Put, ["bookings", id] -> booking.update(req, id, ctx)
    Delete, ["bookings", id] -> booking.delete(req, id, ctx)
    _, ["bookings", _] -> wisp.method_not_allowed([Get, Put, Delete])
    Get, ["app-config"] -> app_config.navigation()
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

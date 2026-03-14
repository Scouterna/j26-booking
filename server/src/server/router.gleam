import gleam/http.{Delete, Get, Post, Put}
import lustre/element
import server/components
import server/web.{type Context}
import server/web/activities
import server/web/app_config
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
  case path_segments {
    ["activities"] ->
      case req.method {
        Get -> activities.get_page(req, ctx)
        Post -> activities.create(req, ctx)
        _ -> wisp.method_not_allowed([Get, Post])
      }
    ["activities", id] ->
      case req.method {
        Get -> activities.get_one(req, id, ctx)
        Put -> activities.update(req, id, ctx)
        Delete -> activities.delete(req, id, ctx)
        _ -> wisp.method_not_allowed([Get, Put, Delete])
      }
    ["app-config"] ->
      case req.method {
        Get -> app_config.navigation()
        _ -> wisp.method_not_allowed([Get])
      }
    ["docs"] ->
      case req.method {
        Get -> api_documentation()
        _ -> wisp.method_not_allowed([Get])
      }
    _ -> wisp.not_found()
  }
}

fn spa_shell() -> Response {
  components.spa_shell_page()
  |> element.to_string
  |> wisp.html_response(200)
}

fn api_documentation() -> Response {
  components.api_documentation_page()
  |> element.to_string
  |> wisp.html_response(200)
}

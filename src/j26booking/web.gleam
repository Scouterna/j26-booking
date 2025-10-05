import gleam/http/request
import pog
import wisp

pub type Context {
  Context(static_directory: String, db_connection: pog.Connection)
}

pub fn middleware(
  req: wisp.Request,
  ctx: Context,
  handle_request: fn(wisp.Request) -> wisp.Response,
) -> wisp.Response {
  let req = wisp.method_override(req)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.serve_static(req, under: "/", from: ctx.static_directory)
  handle_request(req)
}

pub fn is_htmx_request(req: wisp.Request) -> Bool {
  case request.get_header(req, "HX-Request") {
    Ok(_) -> True
    Error(_) -> False
  }
}

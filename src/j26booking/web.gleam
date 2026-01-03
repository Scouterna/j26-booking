import gleam/http/request
import pog
import wisp.{type Request, type Response}

pub type Context {
  Context(
    static_directory: String,
    db_connection: pog.Connection,
    base_path: String,
  )
}

pub fn middleware(
  req: Request,
  ctx: Context,
  handle_request: fn(Request) -> Response,
) -> Response {
  let req = wisp.method_override(req)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.serve_static(req, under: "/", from: ctx.static_directory)
  handle_request(req)
}

pub fn is_htmx_request(req: Request) -> Bool {
  case request.get_header(req, "HX-Request") {
    Ok(_) -> True
    Error(_) -> False
  }
}

pub fn get_base_path(req: Request) -> Result(String, Nil) {
  req |> request.get_header("X-Forwarded-Prefix")
}

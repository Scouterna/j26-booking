import given
import gleam/http/request
import gleam/list
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
  use req <- wisp.csrf_known_header_protection(req)
  use <- wisp.serve_static(req, under: "/static", from: ctx.static_directory)
  handle_request(req)
}

pub fn is_htmx_request(req: Request) -> Bool {
  case request.get_header(req, "HX-Request") {
    Ok(_) -> True
    Error(_) -> False
  }
}

pub fn ensure_valid_query_param(
  in request_query: List(#(String, String)),
  with_name parameter_name: String,
  if_missing_return default_value: a,
  using parse: fn(String) -> Result(a, e),
  else_respond_with error_detail: String,
  then next: fn(a) -> Response,
) -> Response {
  use value <- given.ok(
    in: case list.key_find(request_query, parameter_name) {
      Error(_) -> Ok(default_value)
      Ok(raw) -> parse(raw)
    },
    else_return: fn(_) { wisp.bad_request(error_detail) },
  )
  next(value)
}

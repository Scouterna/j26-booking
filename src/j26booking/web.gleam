import gleam/http/request
import gleam/http/response
import gleam/regexp
import gleam/result
import pog
import wisp.{type Request, type Response}

pub type Context {
  Context(static_directory: String, db_connection: pog.Connection)
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
  use <- add_base_to_response(req)
  use <- wisp.serve_static(req, under: "/", from: ctx.static_directory)
  handle_request(req)
}

pub fn is_htmx_request(req: Request) -> Bool {
  case request.get_header(req, "HX-Request") {
    Ok(_) -> True
    Error(_) -> False
  }
}

pub fn relative_path(req: Request, path: String) -> String {
  result.unwrap(get_base_path(req), "") <> path
}

fn get_base_path(req: Request) -> Result(String, Nil) {
  req |> request.get_header("X-Forwarded-Prefix")
}

fn add_base_to_response(
  req: Request,
  next handler: fn() -> Response,
) -> wisp.Response {
  let res = handler()
  case get_base_path(req) {
    Ok(base_path) -> {
      case res.body {
        wisp.Text(s) -> {
          let assert Ok(regex) = regexp.from_string("</head>")
          res
          |> response.set_body(
            wisp.Text(regexp.replace(
              each: regex,
              in: s,
              with: "<base href=\"" <> base_path <> "/\"/></head>",
            )),
          )
        }
        _ -> res
      }
    }
    Error(_) -> res
  }
}

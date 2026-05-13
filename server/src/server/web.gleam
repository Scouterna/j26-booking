import given
import gleam/list
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import pog
import wisp.{type Request, type Response}
import youid/uuid.{type Uuid}
import ywt/verify_key.{type VerifyKey}

pub const base_path = "/_services/booking"

const scouterna_ui_webc_version = "4.3.4"

pub type Permissions {
  CreateActivity
  DeleteActivity
}

pub type User {
  User(user_id: String, user_name: String, roles: Permissions)
}

/// TODO: This is a draft of a authentication result which should be the result of validating and parsing a JWT.
pub type AuthenticationResult {
  NotAuthenticated
  InvalidToken
  Authenticated(user: User)
}

pub type JWTVerifyKeys {
  JWTVerifyKeys(issuer: String, keys: List(VerifyKey))
}

pub type Context {
  Context(
    static_directory: String,
    db_connection: pog.Connection,
    jwt_verify_keys: JWTVerifyKeys,
    authentication_result: AuthenticationResult,
  )
}

pub fn middleware(
  req: Request,
  ctx: Context,
  handle_request: fn(Request, Context) -> Response,
) -> Response {
  let req = wisp.method_override(req)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use req <- wisp.csrf_known_header_protection(req)
  use <- wisp.serve_static(
    req,
    under: base_path <> "/static",
    from: ctx.static_directory,
  )
  let ctx = authenticate(req, ctx)
  handle_request(req, ctx)
}

/// TODO: Should use the JWT verify keys to authenticate the request and populate the context with the authentication result.
/// Currently hardcoded to a seeded user so the client can exercise bookings end-to-end before JWT auth is wired.
fn authenticate(_req: Request, ctx: Context) -> Context {
  Context(
    ..ctx,
    authentication_result: Authenticated(User(
      user_id: "a1b2c3d4-e5f6-4a90-abcd-ef1234567890",
      user_name: "Anna Svensson",
      roles: CreateActivity,
    )),
  )
}

/// Resolve the authenticated user's UUID from the request context.
///
/// Calls `next` with the parsed `Uuid` when the request carries a valid
/// authentication result, otherwise short-circuits with a 401 response.
pub fn with_authenticated_user(
  ctx: Context,
  next: fn(Uuid) -> Response,
) -> Response {
  case ctx.authentication_result {
    Authenticated(user) ->
      case uuid.from_string(user.user_id) {
        Ok(user_id) -> next(user_id)
        Error(_) -> wisp.internal_server_error()
      }
    NotAuthenticated | InvalidToken -> wisp.response(401)
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

pub fn spa_shell_page() -> Element(a) {
  html.html([attribute.attribute("lang", "sv")], [
    html.head([], [
      html.meta([attribute.charset("UTF-8")]),
      html.meta([
        attribute.content("width=device-width, initial-scale=1"),
        attribute.name("viewport"),
      ]),
      html.title([], "Jamboree 2026 Booking"),
      html.script(
        [
          attribute.src(
            "https://cdn.jsdelivr.net/npm/@scouterna/ui-webc@"
            <> scouterna_ui_webc_version
            <> "/dist/esm/ui-webc.js",
          ),
          attribute.type_("module"),
        ],
        "",
      ),
      html.script(
        [
          attribute.type_("module"),
          attribute.src(base_path <> "/static/client.js"),
        ],
        "",
      ),
      html.link([
        attribute.rel("stylesheet"),
        attribute.href(
          "https://cdn.jsdelivr.net/npm/@scouterna/ui-webc@"
          <> scouterna_ui_webc_version
          <> "/dist/ui-webc/ui-webc.css",
        ),
      ]),
      html.link([
        attribute.rel("stylesheet"),
        attribute.href(base_path <> "/static/client.css"),
      ]),
      html.link([
        attribute.rel("preconnect"),
        attribute.href("https://fonts.googleapis.com"),
      ]),
      html.link([
        attribute.rel("preconnect"),
        attribute.href("https://fonts.gstatic.com"),
        attribute.attribute("crossorigin", ""),
      ]),
      html.link([
        attribute.rel("stylesheet"),
        attribute.href(
          "https://fonts.googleapis.com/css2?family=Source+Sans+3:ital,wght@0,200..900;1,200..900&display=swap",
        ),
      ]),
    ]),
    html.body(
      [
        attribute.styles([
          #("margin", "0"),
          #("font-family", "Source Sans 3, sans-serif"),
        ]),
      ],
      [html.div([attribute.id("app")], [])],
    ),
  ])
}

pub fn api_documentation_page() -> Element(a) {
  html.html([], [
    html.head([], [
      html.title([], "J26 Booking API Documentation"),
      html.meta([attribute.charset("utf-8")]),
      html.meta([
        attribute.content("width=device-width, initial-scale=1"),
        attribute.name("viewport"),
      ]),
    ]),
    html.body([], [
      html.div([attribute.id("app")], []),
      html.script(
        [attribute.src("https://cdn.jsdelivr.net/npm/@scalar/api-reference")],
        "",
      ),
      html.script(
        [],
        "Scalar.createApiReference('#app', {url: '"
          <> base_path
          <> "/static/openapi.yaml'})",
      ),
    ]),
  ])
}

import given
import gleam/bit_array
import gleam/crypto
import gleam/dynamic/decode
import gleam/http/request
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option}
import gleam/result
import gleam/string
import gleam/time/duration
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import pog
import server/sql
import shared/utils as shared_utils
import wisp.{type Request, type Response}
import youid/uuid.{type Uuid}
import ywt
import ywt/claim
import ywt/verify_key.{type VerifyKey}

pub const base_path = "/_services/booking"

pub const scouterna_ui_webc_version = "4.5.0"

/// Roles defined on the `j26-booking` Keycloak client, carried in the
/// `resource_access.j26-booking.roles` claim of the access token.
pub type Role {
  ActivitiesManage
  BookingsOthersCreate
  BookingsRead
  BookingsSelfCreate
  Admin
}

pub fn string_to_role(value: String) -> Result(Role, Nil) {
  case value {
    "activities:manage" -> Ok(ActivitiesManage)
    "bookings:others:create" -> Ok(BookingsOthersCreate)
    "bookings:read" -> Ok(BookingsRead)
    "bookings:self:create" -> Ok(BookingsSelfCreate)
    "admin" -> Ok(Admin)
    _ -> Error(Nil)
  }
}

pub fn role_to_string(role: Role) -> String {
  case role {
    ActivitiesManage -> "activities:manage"
    BookingsOthersCreate -> "bookings:others:create"
    BookingsRead -> "bookings:read"
    BookingsSelfCreate -> "bookings:self:create"
    Admin -> "admin"
  }
}

pub type User {
  User(
    id: Uuid,
    name: String,
    roles: List(Role),
    /// Numeric ScoutID group id from the first `groups` claim entry matching
    /// `/j26-scoutid-sync/groups/<id>`. `None` when the token carries no such
    /// group (e.g. a user outside any scout group).
    group_id: Option(Int),
  )
}

/// TODO(group-name): Resolving a ScoutID group id to its display name is not
/// solved yet — there is no group-directory integration. Replace this
/// placeholder with a real lookup when one exists.
pub fn group_id_to_name(group_id: Int) -> String {
  "Grupp " <> int.to_string(group_id)
}

pub type AuthenticationResult {
  /// The request carried no access token.
  NotAuthenticated
  /// The request carried an access token that failed verification.
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
    /// User that requests without an access token authenticate as. Only ever
    /// `Some` in local development (`DEV_AUTH_ROLES`), where the app runs
    /// without the j26-app shell that normally provides the token cookie.
    dev_fallback_user: Option(User),
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
  ensure_user_row(ctx)
  handle_request(req, ctx)
}

/// Creates the authenticated user's `"user"` row on first sight (the table
/// only has seeded rows otherwise), so handlers can write rows with user_id
/// foreign keys. Runs in the middleware rather than in individual handlers so
/// future user-referencing endpoints cannot forget it; the upsert is a
/// single primary-key `ON CONFLICT DO NOTHING`, negligible at this app's
/// request volume.
///
/// Failure is logged but does not fail the request: read-only handlers still
/// work, and writes that need the row surface the database problem themselves.
fn ensure_user_row(ctx: Context) -> Nil {
  case ctx.authentication_result {
    Authenticated(user) ->
      case sql.upsert_user(ctx.db_connection, user.id) {
        Ok(_) -> Nil
        Error(error) ->
          wisp.log_error("Failed to upsert user row: " <> string.inspect(error))
      }
    NotAuthenticated | InvalidToken -> Nil
  }
}

/// Cookie the j26-auth service stores the access token in. It is httpOnly and
/// scoped to the whole origin, so the browser attaches it to every API request
/// made from inside the j26-app shell without any client-side code.
const access_token_cookie_name = "j26-auth_access-token"

/// Populates the context with the outcome of access-token verification.
///
/// The token is taken from the `Authorization: Bearer` header when present
/// (API clients), otherwise from the j26-auth access-token cookie (the app
/// shell case). Requests without a token authenticate as the dev fallback
/// user when one is configured, and are `NotAuthenticated` otherwise.
///
/// Public so tests can exercise the token handling directly; production code
/// only reaches it through `middleware`.
pub fn authenticate(req: Request, ctx: Context) -> Context {
  let authentication_result = case access_token(req) {
    Ok(token) -> verify_access_token(ctx, token)
    Error(Nil) ->
      case ctx.dev_fallback_user {
        option.Some(user) -> Authenticated(user)
        option.None -> NotAuthenticated
      }
  }
  Context(..ctx, authentication_result:)
}

fn access_token(req: Request) -> Result(String, Nil) {
  let header_token = case request.get_header(req, "authorization") {
    Ok(header_value) ->
      case string.split_once(header_value, " ") {
        Ok(#("Bearer", token)) -> Ok(token)
        _ -> Error(Nil)
      }
    Error(Nil) -> Error(Nil)
  }
  use <- result.lazy_or(header_token)
  request.get_cookies(req) |> list.key_find(access_token_cookie_name)
}

fn verify_access_token(ctx: Context, token: String) -> AuthenticationResult {
  let claims = [
    claim.issuer(ctx.jwt_verify_keys.issuer, []),
    // Keycloak issues `aud: ["j26-booking", "account"]`; ywt accepts the token
    // when any entry matches an accepted audience. Without this claim ywt 2.0
    // rejects every token that carries an `aud`.
    claim.audience("j26-booking", []),
    // Verification checks the token's own `exp` plus `leeway` (`max_age` only
    // applies when signing). Passing the claim makes `exp` required, so a
    // token without an expiry is rejected.
    claim.expires_at(
      max_age: duration.minutes(15),
      leeway: duration.seconds(30),
    ),
  ]
  case
    ywt.decode(
      token,
      using: user_decoder(),
      claims:,
      keys: ctx.jwt_verify_keys.keys,
    )
  {
    Ok(user) -> Authenticated(user)
    Error(error) -> {
      // The reason stays in the server log; clients get an undetailed 401 so
      // verification failures are not leaked.
      wisp.log_warning("JWT verification failed: " <> string.inspect(error))
      InvalidToken
    }
  }
}

/// Decodes the verified JWT payload into a `User`.
///
/// `resource_access.j26-booking.roles` may be absent (a user with no roles on
/// this client); unknown role strings are skipped since Keycloak adds roles we
/// do not model (e.g. `default-roles-jamboree26`). `groups` may likewise be
/// absent or contain no ScoutID group path.
fn user_decoder() -> decode.Decoder(User) {
  use id <- decode.field("sub", uuid_decoder())
  use name <- decode.field("name", decode.string)
  use roles <- decode.then(decode.optionally_at(
    ["resource_access", "j26-booking", "roles"],
    [],
    shared_utils.decode_partial_list(role_decoder()),
  ))
  use groups <- decode.optional_field("groups", [], decode.list(decode.string))
  let group_id = list.find_map(groups, group_path_to_id) |> option.from_result
  decode.success(User(id:, name:, roles:, group_id:))
}

fn uuid_decoder() -> decode.Decoder(Uuid) {
  decode.string
  |> decode.then(fn(raw) {
    case uuid.from_string(raw) {
      Ok(id) -> decode.success(id)
      Error(Nil) -> decode.failure(uuid.nil, "Uuid")
    }
  })
}

fn role_decoder() -> decode.Decoder(Role) {
  decode.string
  |> decode.then(fn(raw) {
    case string_to_role(raw) {
      Ok(role) -> decode.success(role)
      // The zero value is never observed: decode_partial_list drops failures.
      Error(Nil) -> decode.failure(Admin, "Role")
    }
  })
}

/// Extracts the numeric ScoutID group id from a Keycloak group path like
/// `/j26-scoutid-sync/groups/1386`.
fn group_path_to_id(path: String) -> Result(Int, Nil) {
  case string.split(path, "/") {
    ["", "j26-scoutid-sync", "groups", raw_id] -> int.parse(raw_id)
    _ -> Error(Nil)
  }
}

/// Resolve the authenticated user from the request context.
///
/// Calls `next` with the `User` when the request carries a valid
/// authentication result, otherwise short-circuits with a 401 response.
pub fn with_authenticated_user(
  ctx: Context,
  next: fn(User) -> Response,
) -> Response {
  case ctx.authentication_result {
    Authenticated(user) -> next(user)
    NotAuthenticated | InvalidToken -> wisp.response(401)
  }
}

/// True when the user holds `role`. `Admin` implies every role, matching
/// `require_role`. Use when a handler needs the boolean rather than the
/// short-circuiting guard (e.g. to vary a query instead of rejecting).
pub fn has_role(user: User, role: Role) -> Bool {
  list.contains(user.roles, role) || list.contains(user.roles, Admin)
}

/// Calls `next` when the user holds `role`, otherwise short-circuits with a
/// 403 response. `Admin` implies every role.
pub fn require_role(
  user: User,
  role: Role,
  next: fn() -> Response,
) -> Response {
  case has_role(user, role) {
    True -> next()
    False -> wisp.response(403)
  }
}

/// Calls `next` when the user holds at least one of `roles`, otherwise
/// short-circuits with a 403 response. `Admin` implies every role.
pub fn require_any_role(
  user: User,
  roles: List(Role),
  next: fn() -> Response,
) -> Response {
  let holds_any =
    list.contains(user.roles, Admin)
    || list.any(roles, list.contains(user.roles, _))
  case holds_any {
    True -> next()
    False -> wisp.response(403)
  }
}

/// Serves `body` as a JSON response carrying a strong ETag derived from the
/// body bytes, or a `304 Not Modified` when the request's `If-None-Match`
/// already matches. Hashing the exact bytes keeps the validator correct even
/// for responses that differ per caller. `cache_control` is set verbatim, and
/// `Vary: Cookie` is always added because API responses are scoped to the
/// caller's auth cookie, so no shared cache may serve one to another user.
pub fn json_response_with_etag(
  req: Request,
  body: String,
  status: Int,
  cache_control: String,
) -> Response {
  let etag = strong_etag(body)
  let response = case request.get_header(req, "if-none-match") {
    Ok(client_etag) if client_etag == etag -> wisp.response(304)
    _ -> wisp.json_response(body, status)
  }
  response
  |> wisp.set_header("etag", etag)
  |> wisp.set_header("cache-control", cache_control)
  |> wisp.set_header("vary", "cookie")
}

/// A strong ETag: the SHA-256 of the response body, base16-encoded and quoted.
fn strong_etag(body: String) -> String {
  let digest =
    body
    |> bit_array.from_string
    |> crypto.hash(crypto.Sha256, _)
    |> bit_array.base16_encode
  "\"" <> digest <> "\""
}

/// Logs a database query error and responds with a 500. Shared by handlers so
/// the log-and-500 shape stays consistent across the API.
pub fn query_error(error: pog.QueryError) -> Response {
  wisp.log_error("QueryError " <> string.inspect(error))
  wisp.internal_server_error()
}

/// True when booking `requested` more spots on top of `already_booked` would
/// push past the cap. `None` means the activity is uncapped, so it never
/// exceeds. Kept pure so it can be unit-tested without a database.
pub fn exceeds_capacity(
  max: Option(Int),
  already_booked: Int,
  requested: Int,
) -> Bool {
  case max {
    option.None -> False
    option.Some(limit) -> already_booked + requested > limit
  }
}

/// 409 response for a booking that would overbook an activity. Carries the cap
/// and the count already booked so the client can refresh its view.
pub fn capacity_exceeded(max_attendees: Int, spots_booked: Int) -> Response {
  json.object([
    #("error", json.string("capacity_exceeded")),
    #("max_attendees", json.int(max_attendees)),
    #("spots_booked", json.int(spots_booked)),
  ])
  |> json.to_string
  |> wisp.json_response(409)
}

/// Reads and discards the request body.
///
/// Body-less endpoints (e.g. the favourite/booking/activity PUT and DELETE
/// handlers) must still drain any body a client sends. mist exposes the body as
/// a lazy reader and does not auto-drain it; an unread body stays buffered on
/// the socket and, on a keep-alive connection, gets parsed as the start of the
/// next request — corrupting it ("Received malformed HTTP request") and crashing
/// the connection handler. Draining here keeps the connection in sync.
pub fn discard_body(req: Request) -> Nil {
  let _ = wisp.read_body_bits(req)
  Nil
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

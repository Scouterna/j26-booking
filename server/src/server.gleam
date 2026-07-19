import envoy
import gleam/dynamic/decode
import gleam/erlang/process
import gleam/http/request
import gleam/httpc
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option}
import gleam/otp/static_supervisor as supervisor
import gleam/string
import mist
import pog
import server/router
import server/utils
import server/web.{type JWTVerifyKeys, Context, JWTVerifyKeys}
import shared/utils as shared_utils
import wisp
import wisp/wisp_mist
import youid/uuid
import ywt/verify_key

pub fn main() -> Nil {
  wisp.configure_logger()

  // Configuration from environment variables
  let secret_key_base = utils.get_secret_key_base()

  let database_url =
    utils.get_env(
      "DATABASE_URL",
      "postgres://postgres@localhost:5432/j26booking",
    )
  let db_pool_size = utils.get_env_int("DB_POOL_SIZE", 15)

  let server_port = utils.get_env_int("PORT", 8000)
  let open_id_configuration_url =
    utils.get_env(
      "OPEN_ID_CONFIGURATION_URL",
      "https://app.dev.j26.se/auth/.well-known/openid-configuration",
    )
  // Booking opens at the start of the camp (Swedish midnight, 25 July)
  // unless BOOKING_OPENS_AT says otherwise.
  let booking_opens_at =
    option.Some(utils.get_env_rfc3339(
      "BOOKING_OPENS_AT",
      default: "2026-07-25T00:00:00+02:00",
    ))

  let pool_name = process.new_name("j26booking_pool")
  let pool_child = case pog.url_config(pool_name, database_url) {
    Ok(config) ->
      config
      |> pog.pool_size(db_pool_size)
      |> pog.supervised
    Error(Nil) -> {
      wisp.log_error("Invalid DATABASE_URL format: " <> database_url)
      panic as "Invalid DATABASE_URL"
    }
  }

  let jwt_verify_keys = fetch_jwt_verify_keys(open_id_configuration_url)
  let ctx =
    Context(
      static_directory: static_directory(),
      db_connection: pog.named_connection(pool_name),
      jwt_verify_keys:,
      authentication_result: web.NotAuthenticated,
      dev_fallback_user: dev_fallback_user_from_env(),
      booking_opens_at:,
    )
  let handler = router.handle_request(_, ctx)

  let wisp_mist_child =
    wisp_mist.handler(handler, secret_key_base)
    |> mist.new
    |> mist.bind("0.0.0.0")
    |> mist.port(server_port)
    |> mist.supervised

  let assert Ok(_) =
    supervisor.new(supervisor.RestForOne)
    |> supervisor.add(pool_child)
    |> supervisor.add(wisp_mist_child)
    |> supervisor.start

  process.sleep_forever()
}

type OpenIDConfiguration {
  OpenIDConfiguration(issuer: String, jwks_uri: String)
}

fn open_id_configuration_decoder() -> decode.Decoder(OpenIDConfiguration) {
  use issuer <- decode.field("issuer", decode.string)
  use jwks_uri <- decode.field("jwks_uri", decode.string)
  decode.success(OpenIDConfiguration(issuer:, jwks_uri:))
}

fn fetch_jwt_verify_keys(open_id_configuration_url: String) -> JWTVerifyKeys {
  let assert Ok(open_id_configuration_request) =
    request.to(open_id_configuration_url)
  let assert Ok(open_id_configuration_response) =
    open_id_configuration_request
    |> request.prepend_header("accept", "application/json")
    |> httpc.send
  let assert Ok(OpenIDConfiguration(issuer, jwks_uri)) =
    json.parse(
      open_id_configuration_response.body,
      open_id_configuration_decoder(),
    )
  let assert Ok(jwks_request) = request.to(jwks_uri)
  let assert Ok(jwks_response) =
    jwks_request
    |> request.prepend_header("accept", "application/json")
    |> httpc.send
  // The partial-list decoder drops JWKS entries ywt cannot use — Keycloak
  // publishes an RSA-OAEP encryption key alongside the signing keys, and one
  // unusable key must not take the whole set (and startup) down with it.
  let assert Ok(jwt_verify_keys) =
    json.parse(
      jwks_response.body,
      decode.at(
        ["keys"],
        shared_utils.decode_partial_list(verify_key.decoder()),
      ),
    )
  case jwt_verify_keys {
    [] -> panic as { "No usable JWT verify keys in JWKS from " <> jwks_uri }
    _ -> Nil
  }
  wisp.log_info(
    "Loaded "
    <> int.to_string(list.length(jwt_verify_keys))
    <> " JWT verify keys from "
    <> jwks_uri,
  )
  JWTVerifyKeys(issuer, jwt_verify_keys)
}

/// Builds the user that tokenless requests authenticate as in local
/// development, from the comma-separated roles in `DEV_AUTH_ROLES` (e.g.
/// "admin" or "bookings:self:create,bookings:read"). The user matches the
/// seeded "Anna Svensson" so seeded bookings and favourites line up.
///
/// Never set the variable in production: unset means tokenless requests stay
/// unauthenticated. Real tokens always take precedence over the fallback.
fn dev_fallback_user_from_env() -> Option(web.User) {
  case envoy.get("DEV_AUTH_ROLES") {
    Error(Nil) -> option.None
    Ok(raw_roles) -> {
      let roles =
        raw_roles
        |> string.split(",")
        |> list.map(string.trim)
        |> list.map(fn(raw_role) {
          case web.string_to_role(raw_role) {
            Ok(role) -> role
            // A typo in dev configuration; failing fast beats silently
            // running with fewer roles than the developer expects.
            Error(Nil) ->
              panic as { "Unknown role in DEV_AUTH_ROLES: " <> raw_role }
          }
        })
      let assert Ok(user_id) =
        uuid.from_string("a1b2c3d4-e5f6-4a90-abcd-ef1234567890")
      wisp.log_warning(
        "DEV_AUTH_ROLES is set: tokenless requests authenticate as the "
        <> "seeded dev user. Never enable this in production.",
      )
      option.Some(web.User(
        id: user_id,
        name: "Anna Svensson",
        roles:,
        group_id: option.Some(1386),
      ))
    }
  }
}

pub fn static_directory() -> String {
  let assert Ok(priv_directory) = wisp.priv_directory("server")
  priv_directory <> "/static"
}

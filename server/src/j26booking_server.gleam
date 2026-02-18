import envoy
import gleam/dynamic/decode
import gleam/erlang/process
import gleam/http/request
import gleam/httpc
import gleam/int
import gleam/json
import gleam/otp/static_supervisor as supervisor
import gleam/result
import gleam/string
import mist
import pog
import server/router
import server/web.{type JWTVerifyKeys, Context, JWTVerifyKeys}
import shared/utils
import wisp
import wisp/wisp_mist
import ywt/verify_key

pub fn main() -> Nil {
  wisp.configure_logger()

  // Configuration from environment variables
  let secret_key_base = get_secret_key_base()

  let database_url =
    get_env("DATABASE_URL", "postgres://postgres@localhost:5432/j26booking")
  let db_pool_size = get_env_int("DB_POOL_SIZE", 15)

  let base_path = get_env("BASE_PATH", "")
  let server_port = get_env_int("PORT", 8000)
  let open_id_configuration_url =
    get_env(
      "OPEN_ID_CONFIGURATION_URL",
      "https://app.dev.j26.se/auth/.well-known/openid-configuration",
    )

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
      base_path:,
      authentication_result: web.NotAuthenticated,
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
  let assert Ok(jwt_verify_keys) =
    json.parse(
      jwks_response.body,
      decode.at(["keys"], utils.decode_partial_list(verify_key.decoder())),
    )
  JWTVerifyKeys(issuer, jwt_verify_keys)
}

fn get_env(name: String, default: String) -> String {
  envoy.get(name)
  |> result.unwrap(default)
}

fn get_env_int(name: String, default: Int) -> Int {
  envoy.get(name)
  |> result.try(int.parse)
  |> result.unwrap(default)
}

fn get_secret_key_base() -> String {
  let not_set_message =
    "SECRET_KEY_BASE not set, using random key (not suitable for production)"
  case envoy.get("SECRET_KEY_BASE") {
    Ok(key) -> {
      case string.length(key) >= 64 {
        True -> key
        False -> {
          case key {
            "" -> {
              wisp.log_warning(not_set_message)
            }
            _ ->
              wisp.log_error(
                "SECRET_KEY_BASE is too short (minimum 64 characters required), using random key",
              )
          }
          wisp.random_string(64)
        }
      }
    }
    Error(_) -> {
      wisp.log_warning(not_set_message)
      wisp.random_string(64)
    }
  }
}

pub fn static_directory() -> String {
  let assert Ok(priv_directory) = wisp.priv_directory("j26booking_server")
  priv_directory <> "/static"
}

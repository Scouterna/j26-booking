import envoy
import gleam/erlang/process
import gleam/int
import gleam/otp/static_supervisor as supervisor
import gleam/result
import gleam/string
import j26booking/router
import j26booking/web.{Context}
import mist
import pog
import wisp
import wisp/wisp_mist

pub fn main() -> Nil {
  wisp.configure_logger()

  // Configuration from environment variables
  let secret_key_base = get_secret_key_base()
  let database_url =
    get_env("DATABASE_URL", "postgres://postgres@localhost:5432/j26booking")
  let db_pool_size = get_env_int("DB_POOL_SIZE", 15)
  let base_path = get_env("BASE_PATH", "")
  let server_port = get_env_int("PORT", 8000)

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

  let ctx =
    Context(
      static_directory: static_directory(),
      db_connection: pog.named_connection(pool_name),
      base_path:,
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
  let assert Ok(priv_directory) = wisp.priv_directory("j26booking")
  priv_directory <> "/static"
}

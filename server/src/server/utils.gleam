import envoy
import gleam/int
import gleam/result
import gleam/string
import wisp

pub fn ensure_non_negative(i: Int) -> Result(Int, Nil) {
  case i {
    natural if i >= 0 -> Ok(natural)
    _ -> Error(Nil)
  }
}

pub fn get_env(name: String, default: String) -> String {
  envoy.get(name)
  |> result.unwrap(default)
}

pub fn get_env_int(name: String, default: Int) -> Int {
  envoy.get(name)
  |> result.try(int.parse)
  |> result.unwrap(default)
}

pub fn get_secret_key_base() -> String {
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

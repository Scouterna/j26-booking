import gleam/erlang/process
import gleam/otp/static_supervisor as supervisor
import j26booking/router
import j26booking/web.{Context}
import mist
import pog
import wisp
import wisp/wisp_mist

pub fn main() -> Nil {
  wisp.configure_logger()
  let secret_key_base = wisp.random_string(64)

  let pool_name = process.new_name("j26booking_pool")
  let pool_child =
    pog.default_config(pool_name)
    |> pog.host("localhost")
    |> pog.database("j26booking")
    |> pog.pool_size(15)
    |> pog.supervised

  let ctx =
    Context(
      static_directory: static_directory(),
      db_connection: pog.named_connection(pool_name),
    )
  let handler = router.handle_request(_, ctx)

  let wisp_mist_child =
    wisp_mist.handler(handler, secret_key_base)
    |> mist.new
    |> mist.port(8000)
    |> mist.supervised

  let assert Ok(_) =
    supervisor.new(supervisor.RestForOne)
    |> supervisor.add(pool_child)
    |> supervisor.add(wisp_mist_child)
    |> supervisor.start

  process.sleep_forever()
}

pub fn static_directory() -> String {
  let assert Ok(priv_directory) = wisp.priv_directory(".")
  priv_directory <> "/static"
}

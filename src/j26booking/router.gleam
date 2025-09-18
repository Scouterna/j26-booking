import gleam/list
import j26booking/components
import j26booking/data.{get_title}
import j26booking/sql
import j26booking/web.{type Context}
import lustre/element
import pog
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  use req <- web.middleware(req, ctx)
  case wisp.path_segments(req) {
    [] -> wisp.redirect("/index.html")
    ["book", id] -> book(id)
    ["activities"] -> activities(ctx.db_connection)
    _ -> wisp.not_found()
  }
}

fn book(id: String) -> Response {
  wisp.html_response("Booked " <> id, 200)
}

fn activities(db_connection: pog.Connection) -> Response {
  let assert Ok(pog.Returned(_, activity_rows)) =
    sql.get_activities(db_connection)

  components.activities(list.map(activity_rows, get_title))
  |> element.to_string
  |> wisp.html_response(200)
}

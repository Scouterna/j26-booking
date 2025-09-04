import j26booking/components
import j26booking/web.{type Context}
import lustre/element
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  use req <- web.middleware(req, ctx)
  case wisp.path_segments(req) {
    ["book", id] -> book(id)
    ["activities"] -> activities()
    _ -> wisp.not_found()
  }
}

fn book(id: String) -> Response {
  wisp.html_response("Booked " <> id, 200)
}

fn activities() -> Response {
  components.activities(["Badbuss", "Klättervägg", "Traktorrace"])
  |> element.to_string
  |> wisp.html_response(200)
}

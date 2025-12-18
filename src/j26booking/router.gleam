import gleam/list
import gleam/result
import j26booking/components
import j26booking/sql
import j26booking/web.{type Context}
import lustre/element.{type Element}
import pog
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  use req <- web.middleware(req, ctx)
  let base_path = web.get_base_path(req) |> result.unwrap("")
  case wisp.path_segments(req) {
    [] -> index()
    ["book", id] -> book(id)
    ["activities"] ->
      activities_fragment_or_page(req, base_path, ctx.db_connection)
    _ -> wisp.not_found()
  }
}

fn index() -> Response {
  components.index_page() |> element.to_string |> wisp.html_response(200)
}

fn book(id: String) -> Response {
  wisp.html_response("Booked " <> id, 200)
}

fn activities_fragment_or_page(
  req: Request,
  base_path: String,
  db_connection: pog.Connection,
) -> Response {
  let search_query = wisp.get_query(req)
  let search_term = case list.key_find(search_query, "q") {
    Ok(term) -> term
    Error(_) -> ""
  }

  let assert Ok(pog.Returned(_, activity_rows)) =
    sql.search_activities(db_connection, search_term)

  let activity_names = list.map(activity_rows, fn(row) { row.title })

  fragment_or_page(
    req,
    components.activities_list(base_path, activity_names),
    components.activities_page(base_path, activity_names, search_term),
  )
}

fn fragment_or_page(
  req: Request,
  fragment: Element(a),
  page: Element(a),
) -> Response {
  case web.is_htmx_request(req) {
    True -> fragment
    False -> page
  }
  |> element.to_string
  |> wisp.html_response(200)
}

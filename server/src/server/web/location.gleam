import gleam/dict.{type Dict}
import gleam/http.{Get}
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import pog
import server/model/location
import server/sql
import server/web
import wisp.{type Request, type Response}
import youid/uuid.{type Uuid}

/// Returns all locations with their tag ids embedded. Locations and their
/// join-table links are fetched separately and stitched together here, avoiding
/// an array aggregation in SQL.
pub fn get_all(req: Request, ctx: web.Context) -> Response {
  use <- wisp.require_method(req, Get)
  case
    sql.list_locations(ctx.db_connection),
    sql.list_location_tag_links(ctx.db_connection)
  {
    Ok(pog.Returned(_, location_rows)), Ok(pog.Returned(_, link_rows)) -> {
      let tags_by_location = group_tags_by_location(link_rows)
      let locations =
        list.map(location_rows, fn(row) {
          let tags = dict.get(tags_by_location, row.id) |> result.unwrap([])
          location.from_list_locations_row(row, tags)
        })
      wisp.json_response(
        json.object([#("locations", json.array(locations, location.to_json))])
          |> json.to_string,
        200,
      )
    }
    Error(error), _ | _, Error(error) -> {
      wisp.log_error("QueryError " <> string.inspect(error))
      wisp.internal_server_error()
    }
  }
}

/// Returns all location tags.
pub fn get_tags(req: Request, ctx: web.Context) -> Response {
  use <- wisp.require_method(req, Get)
  case sql.list_location_tags(ctx.db_connection) {
    Error(error) -> {
      wisp.log_error("QueryError " <> string.inspect(error))
      wisp.internal_server_error()
    }
    Ok(pog.Returned(_, rows)) -> {
      let tags = list.map(rows, location.from_list_location_tags_row)
      wisp.json_response(
        json.object([#("location_tags", json.array(tags, location.tag_to_json))])
          |> json.to_string,
        200,
      )
    }
  }
}

fn group_tags_by_location(
  links: List(sql.ListLocationTagLinksRow),
) -> Dict(Uuid, List(Uuid)) {
  list.fold(links, dict.new(), fn(acc, link) {
    use existing <- dict.upsert(acc, link.location_id)
    case existing {
      Some(tag_ids) -> [link.location_tag_id, ..tag_ids]
      None -> [link.location_tag_id]
    }
  })
}

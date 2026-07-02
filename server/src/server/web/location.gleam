import given
import gleam/dict.{type Dict}
import gleam/dynamic/decode
import gleam/http.{Delete, Get, Post, Put}
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import pog
import server/model/location
import server/sql
import server/web
import shared/utils
import wisp.{type Request, type Response}
import youid/uuid.{type Uuid}

// --- Input types -----------------------------------------------------------

pub type LocationInput {
  LocationInput(
    name: String,
    name_en: String,
    description: String,
    description_en: String,
    icon_name: String,
    icon_variant: String,
    color: String,
    latitude: Float,
    longitude: Float,
    opening_hours: json.Json,
    tags: List(Uuid),
  )
}

pub type LocationTagInput {
  LocationTagInput(
    name: String,
    name_en: String,
    icon_name: String,
    icon_variant: String,
  )
}

fn uuid_decoder() -> decode.Decoder(Uuid) {
  use raw <- decode.then(decode.string)
  case uuid.from_string(raw) {
    Ok(id) -> decode.success(id)
    Error(_) -> decode.failure(uuid.v7(), "valid UUID string")
  }
}

/// Coordinates arrive as JSON numbers; accept both float and int forms.
fn coordinate_decoder() -> decode.Decoder(Float) {
  decode.one_of(decode.float, [decode.int |> decode.map(int.to_float)])
}

fn location_input_decoder() -> decode.Decoder(LocationInput) {
  use name <- decode.field("name", decode.string)
  use name_en <- decode.field("name_en", decode.string)
  use description <- decode.field("description", decode.string)
  use description_en <- decode.field("description_en", decode.string)
  use icon_name <- decode.field("icon_name", decode.string)
  use icon_variant <- decode.field("icon_variant", decode.string)
  use color <- decode.field("color", decode.string)
  use latitude <- decode.field("latitude", coordinate_decoder())
  use longitude <- decode.field("longitude", coordinate_decoder())
  use opening_hours <- decode.optional_field(
    "opening_hours",
    json.object([]),
    utils.json_passthrough_decoder(),
  )
  use tags <- decode.optional_field("tags", [], decode.list(uuid_decoder()))
  decode.success(LocationInput(
    name:,
    name_en:,
    description:,
    description_en:,
    icon_name:,
    icon_variant:,
    color:,
    latitude:,
    longitude:,
    opening_hours:,
    tags:,
  ))
}

fn location_tag_input_decoder() -> decode.Decoder(LocationTagInput) {
  use name <- decode.field("name", decode.string)
  use name_en <- decode.field("name_en", decode.string)
  use icon_name <- decode.field("icon_name", decode.string)
  use icon_variant <- decode.field("icon_variant", decode.string)
  decode.success(LocationTagInput(name:, name_en:, icon_name:, icon_variant:))
}

// --- Locations -------------------------------------------------------------

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
    Error(error), _ | _, Error(error) -> web.query_error(error)
  }
}

pub fn get_one(req: Request, id: String, ctx: web.Context) -> Response {
  use <- wisp.require_method(req, Get)
  use location_id <- given.ok(uuid.from_string(id), fn(_) {
    wisp.bad_request("Invalid location ID format")
  })
  case sql.get_location(ctx.db_connection, location_id) {
    Error(error) -> web.query_error(error)
    Ok(pog.Returned(_, [])) -> wisp.not_found()
    Ok(pog.Returned(_, [row, ..])) ->
      case sql.get_location_tag_ids(ctx.db_connection, location_id) {
        Error(error) -> web.query_error(error)
        Ok(pog.Returned(_, tag_rows)) -> {
          let tags = list.map(tag_rows, fn(tag_row) { tag_row.location_tag_id })
          location.from_get_location_row(row, tags)
          |> location.to_json
          |> json.to_string
          |> wisp.json_response(200)
        }
      }
  }
}

pub fn create(req: Request, ctx: web.Context) -> Response {
  use <- wisp.require_method(req, Post)
  use body <- wisp.require_json(req)
  use input <- given.ok(decode.run(body, location_input_decoder()), fn(_) {
    wisp.bad_request("Invalid JSON payload")
  })
  let id = uuid.v7()
  let transaction_result =
    pog.transaction(ctx.db_connection, fn(conn) {
      use created <- result.try(sql.create_location(
        conn,
        id,
        input.name,
        input.name_en,
        input.description,
        input.description_en,
        input.icon_name,
        input.icon_variant,
        input.color,
        input.latitude,
        input.longitude,
        input.opening_hours,
      ))
      use _ <- result.try(sql.insert_location_tag_links(conn, id, input.tags))
      Ok(created)
    })
  case transaction_result {
    Ok(pog.Returned(_, [row, ..])) -> {
      let created = location.from_create_location_row(row, input.tags)
      created
      |> location.to_json
      |> json.to_string
      |> wisp.json_response(201)
      |> wisp.set_header(
        "location",
        web.base_path <> "/api/locations/" <> uuid.to_string(created.id),
      )
    }
    Ok(pog.Returned(_, [])) -> wisp.internal_server_error()
    Error(error) -> transaction_error(error)
  }
}

/// Distinguishes a missing location (404) from a genuine query failure (500)
/// inside the update transaction.
type UpdateError {
  LocationNotFound
  UpdateQueryFailed(pog.QueryError)
}

pub fn update(req: Request, id: String, ctx: web.Context) -> Response {
  use <- wisp.require_method(req, Put)
  use location_id <- given.ok(uuid.from_string(id), fn(_) {
    wisp.bad_request("Invalid location ID format")
  })
  use body <- wisp.require_json(req)
  use input <- given.ok(decode.run(body, location_input_decoder()), fn(_) {
    wisp.bad_request("Invalid JSON payload")
  })
  let transaction_result =
    pog.transaction(ctx.db_connection, fn(conn) {
      use updated <- result.try(
        sql.update_location(
          conn,
          location_id,
          input.name,
          input.name_en,
          input.description,
          input.description_en,
          input.icon_name,
          input.icon_variant,
          input.color,
          input.latitude,
          input.longitude,
          input.opening_hours,
        )
        |> result.map_error(UpdateQueryFailed),
      )
      case updated.rows {
        [] -> Error(LocationNotFound)
        [row, ..] -> {
          // Re-sync the tag links to match the request body.
          use _ <- result.try(
            sql.delete_location_tag_links(conn, location_id)
            |> result.map_error(UpdateQueryFailed),
          )
          use _ <- result.try(
            sql.insert_location_tag_links(conn, location_id, input.tags)
            |> result.map_error(UpdateQueryFailed),
          )
          Ok(row)
        }
      }
    })
  case transaction_result {
    Ok(row) ->
      location.from_update_location_row(row, input.tags)
      |> location.to_json
      |> json.to_string
      |> wisp.json_response(200)
    Error(pog.TransactionRolledBack(LocationNotFound)) -> wisp.not_found()
    Error(error) -> {
      wisp.log_error("TransactionError " <> string.inspect(error))
      wisp.internal_server_error()
    }
  }
}

pub fn delete(req: Request, id: String, ctx: web.Context) -> Response {
  use <- wisp.require_method(req, Delete)
  web.discard_body(req)
  use location_id <- given.ok(uuid.from_string(id), fn(_) {
    wisp.bad_request("Invalid location ID format")
  })
  let transaction_result =
    pog.transaction(ctx.db_connection, fn(conn) {
      use _ <- result.try(sql.delete_location_tag_links(conn, location_id))
      use deleted <- result.try(sql.delete_location(conn, location_id))
      Ok(deleted)
    })
  case transaction_result {
    Ok(pog.Returned(_, [])) -> wisp.not_found()
    Ok(pog.Returned(_, [_, ..])) -> wisp.no_content()
    Error(error) -> transaction_error(error)
  }
}

// --- Location tags ---------------------------------------------------------

/// Returns all location tags.
pub fn get_tags(req: Request, ctx: web.Context) -> Response {
  use <- wisp.require_method(req, Get)
  case sql.list_location_tags(ctx.db_connection) {
    Error(error) -> web.query_error(error)
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

pub fn get_tag(req: Request, id: String, ctx: web.Context) -> Response {
  use <- wisp.require_method(req, Get)
  use tag_id <- given.ok(uuid.from_string(id), fn(_) {
    wisp.bad_request("Invalid location tag ID format")
  })
  case sql.get_location_tag(ctx.db_connection, tag_id) {
    Error(error) -> web.query_error(error)
    Ok(pog.Returned(_, [])) -> wisp.not_found()
    Ok(pog.Returned(_, [row, ..])) ->
      location.from_get_location_tag_row(row)
      |> location.tag_to_json
      |> json.to_string
      |> wisp.json_response(200)
  }
}

pub fn create_tag(req: Request, ctx: web.Context) -> Response {
  use <- wisp.require_method(req, Post)
  use body <- wisp.require_json(req)
  use input <- given.ok(decode.run(body, location_tag_input_decoder()), fn(_) {
    wisp.bad_request("Invalid JSON payload")
  })
  let id = uuid.v7()
  case
    sql.create_location_tag(
      ctx.db_connection,
      id,
      input.name,
      input.name_en,
      input.icon_name,
      input.icon_variant,
    )
  {
    Error(error) -> web.query_error(error)
    Ok(pog.Returned(_, [])) -> wisp.internal_server_error()
    Ok(pog.Returned(_, [row, ..])) -> {
      let created = location.from_create_location_tag_row(row)
      created
      |> location.tag_to_json
      |> json.to_string
      |> wisp.json_response(201)
      |> wisp.set_header(
        "location",
        web.base_path <> "/api/location-tags/" <> uuid.to_string(created.id),
      )
    }
  }
}

pub fn update_tag(req: Request, id: String, ctx: web.Context) -> Response {
  use <- wisp.require_method(req, Put)
  use tag_id <- given.ok(uuid.from_string(id), fn(_) {
    wisp.bad_request("Invalid location tag ID format")
  })
  use body <- wisp.require_json(req)
  use input <- given.ok(decode.run(body, location_tag_input_decoder()), fn(_) {
    wisp.bad_request("Invalid JSON payload")
  })
  case
    sql.update_location_tag(
      ctx.db_connection,
      tag_id,
      input.name,
      input.name_en,
      input.icon_name,
      input.icon_variant,
    )
  {
    Error(error) -> web.query_error(error)
    Ok(pog.Returned(_, [])) -> wisp.not_found()
    Ok(pog.Returned(_, [row, ..])) ->
      location.from_update_location_tag_row(row)
      |> location.tag_to_json
      |> json.to_string
      |> wisp.json_response(200)
  }
}

pub fn delete_tag(req: Request, id: String, ctx: web.Context) -> Response {
  use <- wisp.require_method(req, Delete)
  web.discard_body(req)
  use tag_id <- given.ok(uuid.from_string(id), fn(_) {
    wisp.bad_request("Invalid location tag ID format")
  })
  let transaction_result =
    pog.transaction(ctx.db_connection, fn(conn) {
      use _ <- result.try(sql.delete_location_links_by_tag(conn, tag_id))
      use deleted <- result.try(sql.delete_location_tag(conn, tag_id))
      Ok(deleted)
    })
  case transaction_result {
    Ok(pog.Returned(_, [])) -> wisp.not_found()
    Ok(pog.Returned(_, [_, ..])) -> wisp.no_content()
    Error(error) -> transaction_error(error)
  }
}

// --- Helpers ---------------------------------------------------------------

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

fn transaction_error(error: pog.TransactionError(pog.QueryError)) -> Response {
  wisp.log_error("TransactionError " <> string.inspect(error))
  wisp.internal_server_error()
}

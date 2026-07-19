import given
import gleam/dynamic/decode
import gleam/http.{Delete, Get, Post, Put}
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import pog
import server/model/location
import server/sql
import server/web
import shared/model.{type BilingualString}
import shared/utils
import wisp.{type Request, type Response}
import youid/uuid.{type Uuid}

// --- Input types -----------------------------------------------------------

pub type LocationInput {
  LocationInput(
    name: BilingualString,
    description: BilingualString,
    icon_name: String,
    icon_variant: String,
    color: String,
    /// `None` for name-only locations without a map position (issue #26).
    coordinates: Option(model.Coordinates),
    opening_hours: json.Json,
    tags: List(Uuid),
  )
}

pub type LocationTagInput {
  LocationTagInput(
    name: BilingualString,
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

fn location_input_decoder() -> decode.Decoder(LocationInput) {
  use name <- decode.field("name", model.bilingual_string_decoder())
  use description <- decode.field(
    "description",
    model.bilingual_string_decoder(),
  )
  use icon_name <- decode.field("icon_name", decode.string)
  use icon_variant <- decode.field("icon_variant", decode.string)
  use color <- decode.field("color", decode.string)
  // Both-or-neither: a payload with only one of latitude/longitude fails the
  // decode, which the handlers turn into a 400.
  use coordinates <- decode.then(model.coordinates_decoder())
  use opening_hours <- decode.optional_field(
    "opening_hours",
    json.object([]),
    utils.json_passthrough_decoder(),
  )
  use tags <- decode.optional_field("tags", [], decode.list(uuid_decoder()))
  decode.success(LocationInput(
    name:,
    description:,
    icon_name:,
    icon_variant:,
    color:,
    coordinates:,
    opening_hours:,
    tags:,
  ))
}

fn location_tag_input_decoder() -> decode.Decoder(LocationTagInput) {
  use name <- decode.field("name", model.bilingual_string_decoder())
  use icon_name <- decode.field("icon_name", decode.string)
  use icon_variant <- decode.field("icon_variant", decode.string)
  decode.success(LocationTagInput(name:, icon_name:, icon_variant:))
}

// --- Locations -------------------------------------------------------------

/// Returns all locations with their tag ids embedded. Locations and their
/// join-table links are fetched separately and stitched together in
/// `location.fetch_all`, avoiding an array aggregation in SQL.
pub fn get_all(req: Request, ctx: web.Context) -> Response {
  use <- wisp.require_method(req, Get)
  case location.fetch_all(ctx.db_connection) {
    Error(error) -> web.query_error(error)
    Ok(locations) ->
      wisp.json_response(
        json.object([#("locations", json.array(locations, location.to_json))])
          |> json.to_string,
        200,
      )
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
  use user <- web.with_authenticated_user(ctx)
  use <- web.require_role(user, web.ActivitiesManage)
  use body <- wisp.require_json(req)
  use input <- given.ok(decode.run(body, location_input_decoder()), fn(_) {
    wisp.bad_request("Invalid JSON payload")
  })
  let id = uuid.v7()
  // Squirrel cannot generate optional query parameters, so inserting with or
  // without coordinates goes through separate query variants. Each branch
  // converts its own row type, so the transaction yields ready `Location`s.
  let transaction_result =
    pog.transaction(ctx.db_connection, fn(conn) {
      use created <- result.try(case input.coordinates {
        Some(coordinates) -> {
          use returned <- result.map(sql.create_location_with_coordinates(
            conn,
            id,
            input.name.sv,
            input.name.en,
            input.description.sv,
            input.description.en,
            input.icon_name,
            input.icon_variant,
            input.color,
            coordinates.latitude,
            coordinates.longitude,
            input.opening_hours,
          ))
          list.map(returned.rows, fn(row) {
            location.from_create_location_with_coordinates_row(row, input.tags)
          })
        }
        None -> {
          use returned <- result.map(sql.create_location_without_coordinates(
            conn,
            id,
            input.name.sv,
            input.name.en,
            input.description.sv,
            input.description.en,
            input.icon_name,
            input.icon_variant,
            input.color,
            input.opening_hours,
          ))
          list.map(returned.rows, fn(row) {
            location.from_create_location_without_coordinates_row(
              row,
              input.tags,
            )
          })
        }
      })
      use _ <- result.try(sql.insert_location_tag_links(conn, id, input.tags))
      Ok(created)
    })
  case transaction_result {
    Ok([created, ..]) ->
      created
      |> location.to_json
      |> json.to_string
      |> wisp.json_response(201)
      |> wisp.set_header(
        "location",
        web.base_path <> "/api/locations/" <> uuid.to_string(created.id),
      )
    Ok([]) -> wisp.internal_server_error()
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
  use user <- web.with_authenticated_user(ctx)
  use <- web.require_role(user, web.ActivitiesManage)
  use location_id <- given.ok(uuid.from_string(id), fn(_) {
    wisp.bad_request("Invalid location ID format")
  })
  use body <- wisp.require_json(req)
  use input <- given.ok(decode.run(body, location_input_decoder()), fn(_) {
    wisp.bad_request("Invalid JSON payload")
  })
  // Setting and clearing coordinates are separate query variants (Squirrel
  // cannot generate optional query parameters); each branch converts its own
  // row type so the transaction yields ready `Location`s.
  let transaction_result =
    pog.transaction(ctx.db_connection, fn(conn) {
      use updated <- result.try(
        case input.coordinates {
          Some(coordinates) -> {
            use returned <- result.map(sql.update_location_with_coordinates(
              conn,
              location_id,
              input.name.sv,
              input.name.en,
              input.description.sv,
              input.description.en,
              input.icon_name,
              input.icon_variant,
              input.color,
              coordinates.latitude,
              coordinates.longitude,
              input.opening_hours,
            ))
            list.map(returned.rows, fn(row) {
              location.from_update_location_with_coordinates_row(
                row,
                input.tags,
              )
            })
          }
          None -> {
            use returned <- result.map(sql.update_location_without_coordinates(
              conn,
              location_id,
              input.name.sv,
              input.name.en,
              input.description.sv,
              input.description.en,
              input.icon_name,
              input.icon_variant,
              input.color,
              input.opening_hours,
            ))
            list.map(returned.rows, fn(row) {
              location.from_update_location_without_coordinates_row(
                row,
                input.tags,
              )
            })
          }
        }
        |> result.map_error(UpdateQueryFailed),
      )
      case updated {
        [] -> Error(LocationNotFound)
        [updated, ..] -> {
          // Re-sync the tag links to match the request body.
          use _ <- result.try(
            sql.delete_location_tag_links(conn, location_id)
            |> result.map_error(UpdateQueryFailed),
          )
          use _ <- result.try(
            sql.insert_location_tag_links(conn, location_id, input.tags)
            |> result.map_error(UpdateQueryFailed),
          )
          Ok(updated)
        }
      }
    })
  case transaction_result {
    Ok(updated) ->
      updated
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
  use user <- web.with_authenticated_user(ctx)
  use <- web.require_role(user, web.ActivitiesManage)
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
  use user <- web.with_authenticated_user(ctx)
  use <- web.require_role(user, web.ActivitiesManage)
  use body <- wisp.require_json(req)
  use input <- given.ok(decode.run(body, location_tag_input_decoder()), fn(_) {
    wisp.bad_request("Invalid JSON payload")
  })
  let id = uuid.v7()
  case
    sql.create_location_tag(
      ctx.db_connection,
      id,
      input.name.sv,
      input.name.en,
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
  use user <- web.with_authenticated_user(ctx)
  use <- web.require_role(user, web.ActivitiesManage)
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
      input.name.sv,
      input.name.en,
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
  use user <- web.with_authenticated_user(ctx)
  use <- web.require_role(user, web.ActivitiesManage)
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

fn transaction_error(error: pog.TransactionError(pog.QueryError)) -> Response {
  wisp.log_error("TransactionError " <> string.inspect(error))
  wisp.internal_server_error()
}

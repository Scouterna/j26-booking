import given
import gleam/dict.{type Dict}
import gleam/dynamic/decode
import gleam/float
import gleam/http.{Delete, Get, Post, Put}
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/time/timestamp
import pog
import server/model/activity
import server/model/location
import server/sql
import server/web
import shared/model.{type Location}
import wisp.{type Request, type Response}
import youid/uuid.{type Uuid}

type SortQueryParams {
  Title
  StartTime
}

const default_sort = Title

fn parse_sort(value: String) -> Result(SortQueryParams, Nil) {
  case value {
    "title" -> Ok(Title)
    "start_time" -> Ok(StartTime)
    _ -> Error(Nil)
  }
}

/// Fetches every location keyed by id and hands it to `next`, so activity
/// handlers can embed locations without a per-activity query. Short-circuits to
/// a query error response if the fetch fails.
fn with_locations(
  ctx: web.Context,
  next: fn(Dict(Uuid, Location)) -> Response,
) -> Response {
  case location.fetch_all_dict(ctx.db_connection) {
    Error(error) -> web.query_error(error)
    Ok(locations) -> next(locations)
  }
}

fn response_from_db_activity_summaries(
  query_result: Result(pog.Returned(a), pog.QueryError),
  to_activity: fn(a) -> model.Activity,
) -> Response {
  case query_result {
    Error(error) -> web.query_error(error)
    Ok(pog.Returned(_, rows)) -> {
      let activities = rows |> list.map(to_activity)
      wisp.json_response(
        json.object([
          #("activities", json.array(activities, activity.summary_to_json)),
        ])
          |> json.to_string,
        200,
      )
    }
  }
}

/// Returns ordinary activities as slim summaries (no `description`), excluding
/// recurring-kind slots (swim bus, climbing wall) which have their own
/// endpoints. Unpaginated; `sort` is honoured.
pub fn get_page(req: Request, ctx: web.Context) -> Response {
  use <- wisp.require_method(req, Get)
  let request_query = wisp.get_query(req)

  use sort <- web.ensure_valid_query_param(
    in: request_query,
    with_name: "sort",
    if_missing_return: default_sort,
    using: parse_sort,
    else_respond_with: "Invalid sort parameter. Allowed values: title, start_time",
  )
  use locations <- with_locations(ctx)

  case sort {
    StartTime ->
      response_from_db_activity_summaries(
        sql.list_activities_by_start_time(ctx.db_connection),
        activity.from_list_activities_by_start_time_row(_, locations),
      )
    Title ->
      response_from_db_activity_summaries(
        sql.list_activities_by_title(ctx.db_connection),
        activity.from_list_activities_by_title_row(_, locations),
      )
  }
}

/// Returns all swim bus slots as slim summaries, ordered by start time.
pub fn get_swim_bus(req: Request, ctx: web.Context) -> Response {
  use <- wisp.require_method(req, Get)
  use locations <- with_locations(ctx)
  response_from_db_activity_summaries(
    sql.list_swim_bus_activities(ctx.db_connection),
    activity.from_list_swim_bus_activities_row(_, locations),
  )
}

/// Returns all climbing wall slots as slim summaries, ordered by start time.
pub fn get_climbing_wall(req: Request, ctx: web.Context) -> Response {
  use <- wisp.require_method(req, Get)
  use locations <- with_locations(ctx)
  response_from_db_activity_summaries(
    sql.list_climbing_wall_activities(ctx.db_connection),
    activity.from_list_climbing_wall_activities_row(_, locations),
  )
}

/// Returns the authenticated user's favourited and booked activities as slim
/// summaries, ordered by start time. Used to hydrate the client's entity cache
/// with favourites the user may not have browsed to yet; membership of the
/// Favourites tab is derived from `/api/statuses/me`, not from this list.
pub fn get_favourited(req: Request, ctx: web.Context) -> Response {
  use <- wisp.require_method(req, Get)
  use user_id <- web.with_authenticated_user(ctx)
  use locations <- with_locations(ctx)
  response_from_db_activity_summaries(
    sql.list_favourited_activities(ctx.db_connection, user_id),
    activity.from_list_favourited_activities_row(_, locations),
  )
}

pub fn get_one(req: Request, id: String, ctx: web.Context) -> Response {
  use <- wisp.require_method(req, Get)
  use activity_id <- given.ok(uuid.from_string(id), fn(_) {
    wisp.bad_request("Invalid activity ID format")
  })
  use locations <- with_locations(ctx)
  case sql.get_activity(ctx.db_connection, activity_id) {
    Error(error) -> web.query_error(error)
    Ok(pog.Returned(_, [])) -> wisp.not_found()
    Ok(pog.Returned(_, [row, ..])) ->
      wisp.json_response(
        row
          |> activity.from_get_activity_row(locations)
          |> activity.to_json
          |> json.to_string,
        200,
      )
  }
}

pub fn delete(req: Request, id: String, ctx: web.Context) -> Response {
  use <- wisp.require_method(req, Delete)
  web.discard_body(req)
  use activity_id <- given.ok(uuid.from_string(id), fn(_) {
    wisp.bad_request("Invalid activity ID format")
  })

  case sql.delete_activity(ctx.db_connection, activity_id) {
    Error(error) -> web.query_error(error)
    Ok(pog.Returned(_, [])) -> wisp.not_found()
    Ok(pog.Returned(_, [_, ..])) -> wisp.no_content()
  }
}

pub type ActivityInput {
  ActivityInput(
    title: String,
    description: String,
    max_attendees: Option(Int),
    start_time: Int,
    end_time: Int,
  )
}

fn activity_input_decoder() -> decode.Decoder(ActivityInput) {
  use title <- decode.field("title", decode.string)
  use description <- decode.field("description", decode.string)
  use max_attendees <- decode.optional_field(
    "max_attendees",
    None,
    decode.optional(decode.int),
  )
  use start_time <- decode.field(
    "start_time",
    decode.one_of(decode.int, [decode.float |> decode.map(float.round)]),
  )
  use end_time <- decode.field(
    "end_time",
    decode.one_of(decode.int, [decode.float |> decode.map(float.round)]),
  )
  decode.success(ActivityInput(
    title:,
    description:,
    max_attendees:,
    start_time:,
    end_time:,
  ))
}

fn response_from_db_activity_creation(
  query_result: Result(pog.Returned(a), pog.QueryError),
  to_activity: fn(a) -> model.Activity,
) -> Response {
  case query_result {
    Error(error) -> web.query_error(error)
    Ok(pog.Returned(_, [])) -> wisp.internal_server_error()
    Ok(pog.Returned(_, [row, ..])) -> {
      let created_activity = to_activity(row)
      let location =
        web.base_path
        <> "/api/activities/"
        <> uuid.to_string(created_activity.id)
      wisp.json_response(
        activity.to_json(created_activity) |> json.to_string,
        201,
      )
      |> wisp.set_header("location", location)
    }
  }
}

pub fn create(req: Request, ctx: web.Context) -> Response {
  use <- wisp.require_method(req, Post)
  use json_body <- wisp.require_json(req)
  use input <- given.ok(decode.run(json_body, activity_input_decoder()), fn(_) {
    wisp.bad_request("Invalid JSON payload")
  })
  let id = uuid.v7()
  let start_time = timestamp.from_unix_seconds(input.start_time)
  let end_time = timestamp.from_unix_seconds(input.end_time)

  // A newly created activity never has a location (the form cannot set one), so
  // resolving against an empty map always yields `None`.
  let locations = dict.new()
  case input.max_attendees {
    Some(max_attendees) ->
      response_from_db_activity_creation(
        sql.create_activity_with_max_attendees(
          ctx.db_connection,
          id,
          input.title,
          input.description,
          max_attendees,
          start_time,
          end_time,
        ),
        activity.from_create_activity_with_max_attendees_row(_, locations),
      )
    None ->
      response_from_db_activity_creation(
        sql.create_activity_without_max_attendees(
          ctx.db_connection,
          id,
          input.title,
          input.description,
          start_time,
          end_time,
        ),
        activity.from_create_activity_without_max_attendees_row(_, locations),
      )
  }
}

fn response_from_db_activity_update(
  query_result: Result(pog.Returned(a), pog.QueryError),
  to_activity: fn(a) -> model.Activity,
) -> Response {
  case query_result {
    Error(error) -> web.query_error(error)
    Ok(pog.Returned(_, [])) -> wisp.not_found()
    Ok(pog.Returned(_, [row, ..])) -> {
      let updated_activity = row |> to_activity
      wisp.json_response(
        activity.to_json(updated_activity) |> json.to_string,
        200,
      )
    }
  }
}

pub fn update(req: Request, id: String, ctx: web.Context) -> Response {
  use <- wisp.require_method(req, Put)
  use activity_id <- given.ok(uuid.from_string(id), fn(_) {
    wisp.bad_request("Invalid activity ID format")
  })
  use json_body <- wisp.require_json(req)
  use input <- given.ok(decode.run(json_body, activity_input_decoder()), fn(_) {
    wisp.bad_request("Invalid JSON payload")
  })
  use locations <- with_locations(ctx)
  let start_time = timestamp.from_unix_seconds(input.start_time)
  let end_time = timestamp.from_unix_seconds(input.end_time)

  case input.max_attendees {
    Some(max_attendees) ->
      response_from_db_activity_update(
        sql.update_activity_with_max_attendees(
          ctx.db_connection,
          activity_id,
          input.title,
          input.description,
          max_attendees,
          start_time,
          end_time,
        ),
        activity.from_update_activity_with_max_attendees_row(_, locations),
      )
    None ->
      response_from_db_activity_update(
        sql.update_activity_without_max_attendees(
          ctx.db_connection,
          activity_id,
          input.title,
          input.description,
          start_time,
          end_time,
        ),
        activity.from_update_activity_without_max_attendees_row(_, locations),
      )
  }
}

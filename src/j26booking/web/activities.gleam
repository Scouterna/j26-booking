import given
import gleam/dynamic/decode
import gleam/float
import gleam/http.{Delete, Get, Post, Put}
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import gleam/time/timestamp
import j26booking/model/activity
import j26booking/sql
import j26booking/utils
import j26booking/web
import pog
import wisp.{type Request, type Response}
import youid/uuid

type SortQueryParams {
  Title
  StartTime
}

const default_page = 0

const page_size = 20

const default_sort = Title

fn parse_sort(value: String) -> Result(SortQueryParams, Nil) {
  case value {
    "title" -> Ok(Title)
    "start_time" -> Ok(StartTime)
    _ -> Error(Nil)
  }
}

fn response_from_db_activities_page(
  query_result: Result(pog.Returned(a), pog.QueryError),
  to_activity: fn(a) -> activity.Activity,
) -> Response {
  case query_result {
    Error(error) -> {
      wisp.log_error("QueryError " <> string.inspect(error))
      wisp.internal_server_error()
    }
    Ok(pog.Returned(_, rows)) -> {
      let activities = rows |> list.map(to_activity)
      wisp.json_response(
        json.object([#("activities", json.array(activities, activity.to_json))])
          |> json.to_string,
        200,
      )
    }
  }
}

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

  use page <- web.ensure_valid_query_param(
    in: request_query,
    with_name: "page",
    if_missing_return: default_page,
    using: fn(i) { int.parse(i) |> result.try(utils.ensure_non_negative) },
    else_respond_with: "Invalid page parameter. Must be a non-negative integer",
  )

  let limit = page_size
  let offset = page * page_size
  case sort {
    StartTime ->
      response_from_db_activities_page(
        sql.get_activities_by_start_time(ctx.db_connection, limit, offset),
        activity.from_get_activities_by_start_time_row,
      )
    Title ->
      response_from_db_activities_page(
        sql.get_activities_by_title(ctx.db_connection, limit, offset),
        activity.from_get_activities_by_title_row,
      )
  }
}

pub fn get_one(req: Request, id: String, ctx: web.Context) -> Response {
  use <- wisp.require_method(req, Get)
  use activity_id <- given.ok(uuid.from_string(id), fn(_) {
    wisp.bad_request("Invalid activity ID format")
  })
  case sql.get_activity(ctx.db_connection, activity_id) {
    Error(error) -> {
      wisp.log_error("QueryError " <> string.inspect(error))
      wisp.internal_server_error()
    }
    Ok(pog.Returned(_, [])) -> wisp.not_found()
    Ok(pog.Returned(_, [row, ..])) ->
      wisp.json_response(
        row
          |> activity.from_get_activity_row
          |> activity.to_json
          |> json.to_string,
        200,
      )
  }
}

pub fn delete(req: Request, id: String, ctx: web.Context) -> Response {
  use <- wisp.require_method(req, Delete)
  use activity_id <- given.ok(uuid.from_string(id), fn(_) {
    wisp.bad_request("Invalid activity ID format")
  })

  case sql.delete_activity(ctx.db_connection, activity_id) {
    Error(error) -> {
      wisp.log_error("QueryError " <> string.inspect(error))
      wisp.internal_server_error()
    }
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
  to_activity: fn(a) -> activity.Activity,
) -> Response {
  case query_result {
    Error(error) -> {
      wisp.log_error("QueryError " <> string.inspect(error))
      wisp.internal_server_error()
    }
    Ok(pog.Returned(_, [])) -> wisp.internal_server_error()
    Ok(pog.Returned(_, [row, ..])) -> {
      let created_activity = to_activity(row)
      let location = "/api/activities/" <> uuid.to_string(created_activity.id)
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
        activity.from_create_activity_with_max_attendees_row,
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
        activity.from_create_activity_without_max_attendees_row,
      )
  }
}

fn response_from_db_activity_update(
  query_result: Result(pog.Returned(a), pog.QueryError),
  to_activity: fn(a) -> activity.Activity,
) -> Response {
  case query_result {
    Error(error) -> {
      wisp.log_error("QueryError " <> string.inspect(error))
      wisp.internal_server_error()
    }
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
        activity.from_update_activity_with_max_attendees_row,
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
        activity.from_update_activity_without_max_attendees_row,
      )
  }
}

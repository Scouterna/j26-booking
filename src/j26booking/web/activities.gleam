import gleam/dynamic/decode
import gleam/float
import gleam/http.{Delete, Get, Post}
import gleam/int
import gleam/json
import gleam/option.{type Option, None}
import gleam/result
import gleam/string
import gleam/time/timestamp
import j26booking/db
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
  let activities_result = case sort {
    StartTime -> {
      use returned <- result.map(sql.get_activities_by_start_time(
        ctx.db_connection,
        limit,
        offset,
      ))
      db.map_returned_rows(
        returned,
        activity.from_get_activities_by_start_time_row,
      )
    }
    Title -> {
      use returned <- result.map(sql.get_activities_by_title(
        ctx.db_connection,
        limit,
        offset,
      ))
      db.map_returned_rows(returned, activity.from_get_activities_by_title_row)
    }
  }
  case activities_result {
    Error(error) -> {
      wisp.log_error("QueryError " <> string.inspect(error))
      wisp.internal_server_error()
    }
    Ok(activities) ->
      wisp.json_response(
        json.object([#("activities", json.array(activities, activity.to_json))])
          |> json.to_string,
        200,
      )
  }
}

pub fn get_one(req: Request, id: String, ctx: web.Context) -> Response {
  use <- wisp.require_method(req, Get)
  case uuid.from_string(id) {
    Error(_) -> wisp.bad_request("Invalid activity ID format")
    Ok(activity_id) -> {
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
  }
}

pub fn delete(req: Request, id: String, ctx: web.Context) -> Response {
  use <- wisp.require_method(req, Delete)
  case uuid.from_string(id) {
    Error(_) -> wisp.bad_request("Invalid activity ID format")
    Ok(activity_id) -> {
      case sql.delete_activity(ctx.db_connection, activity_id) {
        Error(error) -> {
          wisp.log_error("QueryError " <> string.inspect(error))
          wisp.internal_server_error()
        }
        Ok(pog.Returned(_, [])) -> wisp.not_found()
        Ok(pog.Returned(_, [_, ..])) -> wisp.no_content()
      }
    }
  }
}

pub type ActivityInput {
  ActivityInput(
    title: String,
    description: String,
    max_attendees: Option(Int),
    start_time: Float,
    end_time: Float,
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
  use start_time <- decode.field("start_time", decode.float)
  use end_time <- decode.field("end_time", decode.float)
  decode.success(ActivityInput(
    title:,
    description:,
    max_attendees:,
    start_time:,
    end_time:,
  ))
}

pub fn create(req: Request, ctx: web.Context) -> Response {
  use <- wisp.require_method(req, Post)
  use json_body <- wisp.require_json(req)

  case decode.run(json_body, activity_input_decoder()) {
    Error(_) -> wisp.bad_request("Invalid JSON payload")
    Ok(input) -> {
      let id = uuid.v7()
      let start_time =
        timestamp.from_unix_seconds(float.truncate(input.start_time))
      let end_time = timestamp.from_unix_seconds(float.truncate(input.end_time))

      case input.max_attendees {
        option.Some(max) -> {
          case
            sql.create_activity_with_max_attendees(
              ctx.db_connection,
              id,
              input.title,
              input.description,
              max,
              start_time,
              end_time,
            )
          {
            Error(error) -> {
              wisp.log_error("QueryError " <> string.inspect(error))
              wisp.internal_server_error()
            }
            Ok(pog.Returned(_, [row, ..])) -> {
              let created =
                activity.from_create_activity_with_max_attendees_row(row)
              let location = "/api/activities/" <> uuid.to_string(created.id)
              wisp.json_response(
                activity.to_json(created) |> json.to_string,
                201,
              )
              |> wisp.set_header("location", location)
            }
            Ok(pog.Returned(_, [])) -> wisp.internal_server_error()
          }
        }
        option.None -> {
          case
            sql.create_activity_without_max_attendees(
              ctx.db_connection,
              id,
              input.title,
              input.description,
              start_time,
              end_time,
            )
          {
            Error(error) -> {
              wisp.log_error("QueryError " <> string.inspect(error))
              wisp.internal_server_error()
            }
            Ok(pog.Returned(_, [row, ..])) -> {
              let created =
                activity.from_create_activity_without_max_attendees_row(row)
              let location = "/api/activities/" <> uuid.to_string(created.id)
              wisp.json_response(
                activity.to_json(created) |> json.to_string,
                201,
              )
              |> wisp.set_header("location", location)
            }
            Ok(pog.Returned(_, [])) -> wisp.internal_server_error()
          }
        }
      }
    }
  }
}

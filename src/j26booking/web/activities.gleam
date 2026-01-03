import gleam/http.{Get}
import gleam/int
import gleam/json
import gleam/result
import gleam/string
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

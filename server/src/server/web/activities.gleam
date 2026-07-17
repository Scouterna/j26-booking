import given
import gleam/dict.{type Dict}
import gleam/dynamic/decode
import gleam/float
import gleam/http.{Delete, Get, Post, Put}
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import gleam/time/calendar
import gleam/time/duration
import gleam/time/timestamp.{type Timestamp}
import pog
import server/model/activity
import server/model/location
import server/sql
import server/web
import shared/event
import shared/model.{type BilingualString, type Location, type TargetGroup}
import wisp.{type Request, type Response}
import youid/uuid.{type Uuid}

type SortQueryParams {
  Title
  StartTime
}

const default_sort = Title

/// Browse/list responses are scoped to the caller's auth cookie and revalidated
/// via ETag on every visit, so they may be stored but must be re-checked.
const list_cache_control = "private, no-cache"

fn parse_sort(value: String) -> Result(SortQueryParams, Nil) {
  case value {
    "title" -> Ok(Title)
    "start_time" -> Ok(StartTime)
    _ -> Error(Nil)
  }
}

fn parse_bool(value: String) -> Result(Bool, Nil) {
  case value {
    "true" -> Ok(True)
    "false" -> Ok(False)
    _ -> Error(Nil)
  }
}

/// Resolves the manager-only `include_call_offs` query param. Absent or `false`
/// yields the cacheable default (`False` — called-off activities excluded, so
/// the response is identical for every user). `true` requires the
/// `ActivitiesManage` role: a non-manager asking for call-offs gets a 403 so a
/// cached default response can never be mistaken for a manager view. A
/// malformed value is a 400.
fn with_include_call_offs(
  req: Request,
  user: web.User,
  next: fn(Bool) -> Response,
) -> Response {
  use requested <- web.ensure_valid_query_param(
    in: wisp.get_query(req),
    with_name: "include_call_offs",
    if_missing_return: False,
    using: parse_bool,
    else_respond_with: "Invalid include_call_offs parameter. Allowed values: true, false",
  )
  case requested {
    False -> next(False)
    True ->
      case web.has_role(user, web.ActivitiesManage) {
        True -> next(True)
        False -> wisp.response(403)
      }
  }
}

/// Fixed Stockholm summer (CEST) offset in hours. The whole event window
/// (25/7–1/8 2026) sits inside CEST — DST does not shift until late October —
/// so a constant +2h is exact for every event day and no day boundary ever
/// straddles a DST transition. `activity.start_time` is stored as UTC
/// wall-clock (the API round-trips it through unix instants), and the client
/// buckets/displays days at its own local offset, which for on-site attendees
/// is this same Stockholm offset.
const stockholm_summer_offset_hours = 2

/// The `[day_start, day_end)` instants bounding one calendar date in Stockholm
/// local time — `day_start` is that date's local midnight, `day_end` the next
/// date's. Passed as the `start_time` window to the browse queries so an
/// activity at 23:30 local lands on the right day. Exposed for unit testing the
/// boundary math (the load-bearing timezone conversion).
pub fn day_bounds(date: calendar.Date) -> #(Timestamp, Timestamp) {
  let offset = duration.hours(stockholm_summer_offset_hours)
  let day_start =
    timestamp.from_calendar(date, calendar.TimeOfDay(0, 0, 0, 0), offset)
  let day_end = timestamp.add(day_start, duration.hours(24))
  #(day_start, day_end)
}

/// Today's date in Stockholm local time — the browse default day before
/// clamping into the event range.
fn today_in_stockholm() -> calendar.Date {
  let #(date, _) =
    timestamp.to_calendar(
      timestamp.system_time(),
      duration.hours(stockholm_summer_offset_hours),
    )
  date
}

/// Resolves the `?day=YYYY-MM-DD` query param for the day-windowed browse
/// endpoints. Absent → today clamped into the event range. A valid date is
/// clamped into `[event_first_day, event_last_day]` (the client only ever
/// offers in-range dates). A malformed value is a 400.
fn with_day(req: Request, next: fn(calendar.Date) -> Response) -> Response {
  use date <- web.ensure_valid_query_param(
    in: wisp.get_query(req),
    with_name: "day",
    if_missing_return: event.clamp_to_event(today_in_stockholm()),
    using: fn(raw) {
      event.date_from_iso(raw) |> result.map(event.clamp_to_event)
    },
    else_respond_with: "Invalid day parameter. Expected format: YYYY-MM-DD",
  )
  next(date)
}

fn uuid_decoder() -> decode.Decoder(Uuid) {
  use raw <- decode.then(decode.string)
  case uuid.from_string(raw) {
    Ok(id) -> decode.success(id)
    Error(_) -> decode.failure(uuid.v7(), "valid UUID string")
  }
}

/// Fetches every location keyed by id and hands it to `next`, so activity
/// handlers can resolve locations without a per-activity query. Short-circuits
/// to a query error response if the fetch fails.
fn with_locations(
  ctx: web.Context,
  next: fn(Dict(Uuid, Location)) -> Response,
) -> Response {
  case location.fetch_all_dict(ctx.db_connection) {
    Error(error) -> web.query_error(error)
    Ok(locations) -> next(locations)
  }
}

/// Fetches everything embedded into activities — locations, tag links and
/// target-group links — grouped by activity id, so list/detail responses can
/// stitch them in without per-activity queries.
fn with_embeds(
  ctx: web.Context,
  next: fn(activity.Embeds) -> Response,
) -> Response {
  use locations <- with_locations(ctx)
  case sql.list_activity_tag_links(ctx.db_connection) {
    Error(error) -> web.query_error(error)
    Ok(pog.Returned(_, tag_links)) ->
      case sql.list_activity_target_groups(ctx.db_connection) {
        Error(error) -> web.query_error(error)
        Ok(pog.Returned(_, target_group_links)) ->
          case sql.list_call_offs(ctx.db_connection) {
            Error(error) -> web.query_error(error)
            Ok(pog.Returned(_, call_off_rows)) ->
              next(activity.Embeds(
                locations:,
                tags_by_activity: activity.group_tags_by_activity(tag_links),
                target_groups_by_activity: activity.group_target_groups_by_activity(
                  target_group_links,
                ),
                call_offs: activity.group_call_offs_by_activity(call_off_rows),
              ))
          }
      }
  }
}

/// Builds the embeds for a single activity from the tags and target groups just
/// written for it (avoids re-fetching after a create/update).
fn embeds_for_one(
  locations: Dict(Uuid, Location),
  id: Uuid,
  tags: List(Uuid),
  target_groups: List(TargetGroup),
  call_offs: Dict(Uuid, String),
) -> activity.Embeds {
  activity.Embeds(
    locations:,
    tags_by_activity: dict.from_list([#(id, tags)]),
    target_groups_by_activity: dict.from_list([#(id, target_groups)]),
    call_offs:,
  )
}

/// The call-off map for a single activity — `{id: reason}` if it is called off,
/// empty otherwise. A query failure is treated as "not called off" since the
/// caller only uses it to embed the reason into a response the client refetches.
fn call_offs_for_one(
  ctx: web.Context,
  activity_id: Uuid,
) -> Dict(Uuid, String) {
  case sql.get_call_off_by_activity(ctx.db_connection, activity_id) {
    Ok(pog.Returned(_, [row, ..])) ->
      dict.from_list([#(activity_id, row.reason)])
    _ -> dict.new()
  }
}

/// Rejects a `location_id` that doesn't refer to a known location, so an unknown
/// (but well-formed) id fails fast with 400 rather than tripping the `location_id`
/// foreign key mid-transaction and surfacing as a 500. `None` always passes.
fn require_valid_location(
  locations: Dict(Uuid, Location),
  location_id: Option(Uuid),
  next: fn() -> Response,
) -> Response {
  case location_id {
    None -> next()
    Some(id) ->
      case dict.has_key(locations, id) {
        True -> next()
        False -> wisp.bad_request("Unknown location_id")
      }
  }
}

/// Sets a newly-created activity's location, inside the create transaction. The
/// inserted row already has `location_id = NULL`, so `None` needs no write —
/// unlike an update, which must clear any previously-set location.
fn set_new_activity_location(
  conn: pog.Connection,
  activity_id: Uuid,
  location_id: Option(Uuid),
) -> Result(pog.Returned(Nil), pog.QueryError) {
  case location_id {
    Some(id) -> sql.set_activity_location(conn, activity_id, id)
    None -> Ok(pog.Returned(0, []))
  }
}

/// Writes an activity's location during an update, inside the transaction.
/// `location_id` is nullable but Squirrel params are not, so setting a location
/// and clearing it are two queries. Clearing matters on update because the row
/// may already hold a location; a fresh create uses `set_new_activity_location`.
fn write_activity_location(
  conn: pog.Connection,
  activity_id: Uuid,
  location_id: Option(Uuid),
) -> Result(pog.Returned(Nil), pog.QueryError) {
  case location_id {
    Some(id) -> sql.set_activity_location(conn, activity_id, id)
    None -> sql.clear_activity_location(conn, activity_id)
  }
}

/// Resolve the chosen `location_id` to the full location, for embedding into the
/// create/update response. `None` when no location was chosen (unknown ids are
/// rejected upstream by `require_valid_location`). Used to override the response's
/// location, since the insert/update queries return a stale/NULL `location_id`.
fn chosen_location(
  locations: Dict(Uuid, Location),
  location_id: Option(Uuid),
) -> Option(Location) {
  case location_id {
    None -> None
    Some(id) -> dict.get(locations, id) |> option.from_result
  }
}

/// Replaces an activity's location with `location`, so a create/update response
/// reflects the location just written rather than the stale value the main query
/// returned.
fn with_location(
  activity: model.Activity,
  location: Option(Location),
) -> model.Activity {
  model.Activity(..activity, location:)
}

fn response_from_db_activity_summaries(
  req: Request,
  query_result: Result(pog.Returned(a), pog.QueryError),
  to_activity: fn(a) -> model.Activity,
  audience: web.CacheAudience,
) -> Response {
  case query_result {
    Error(error) -> web.query_error(error)
    Ok(pog.Returned(_, rows)) -> {
      let activities = rows |> list.map(to_activity)
      let body =
        json.object([
          #("activities", json.array(activities, activity.summary_to_json)),
        ])
        |> json.to_string
      web.json_response_with_etag(req, body, 200, list_cache_control, audience)
    }
  }
}

/// The cache audience of a browse list: the default response is byte-identical
/// for everyone, but the manager-only `include_call_offs` view is role-scoped
/// and must not be reused across callers.
fn list_audience(include_call_offs: Bool) -> web.CacheAudience {
  case include_call_offs {
    True -> web.ScopedToUser
    False -> web.SharedAcrossUsers
  }
}

/// Returns ordinary activities as slim summaries (no `description`), excluding
/// recurring-kind slots (beach bus, climbing wall) which have their own
/// endpoints. Unpaginated; `sort` is honoured.
pub fn get_page(req: Request, ctx: web.Context) -> Response {
  use <- wisp.require_method(req, Get)
  // Authenticated because the whole API requires auth; the list itself no longer
  // varies by user unless `include_call_offs` is requested (managers only), so
  // the default response is byte-identical for everyone and shares one ETag.
  use user <- web.with_authenticated_user(ctx)

  use sort <- web.ensure_valid_query_param(
    in: wisp.get_query(req),
    with_name: "sort",
    if_missing_return: default_sort,
    using: parse_sort,
    else_respond_with: "Invalid sort parameter. Allowed values: title, start_time",
  )
  use include_call_offs <- with_include_call_offs(req, user)
  use day <- with_day(req)
  use embeds <- with_embeds(ctx)
  let #(day_start, day_end) = day_bounds(day)

  case sort {
    StartTime ->
      response_from_db_activity_summaries(
        req,
        sql.list_activities_by_start_time(
          ctx.db_connection,
          include_call_offs,
          day_start,
          day_end,
        ),
        activity.from_list_activities_by_start_time_row(_, embeds),
        list_audience(include_call_offs),
      )
    Title ->
      response_from_db_activity_summaries(
        req,
        sql.list_activities_by_title(
          ctx.db_connection,
          include_call_offs,
          day_start,
          day_end,
        ),
        activity.from_list_activities_by_title_row(_, embeds),
        list_audience(include_call_offs),
      )
  }
}

/// Returns all beach bus slots as slim summaries, ordered by start time.
pub fn get_beach_bus(req: Request, ctx: web.Context) -> Response {
  use <- wisp.require_method(req, Get)
  use user <- web.with_authenticated_user(ctx)
  use include_call_offs <- with_include_call_offs(req, user)
  use day <- with_day(req)
  use embeds <- with_embeds(ctx)
  let #(day_start, day_end) = day_bounds(day)
  response_from_db_activity_summaries(
    req,
    sql.list_beach_bus_activities(
      ctx.db_connection,
      include_call_offs,
      day_start,
      day_end,
    ),
    activity.from_list_beach_bus_activities_row(_, embeds),
    list_audience(include_call_offs),
  )
}

/// Returns all climbing wall slots as slim summaries, ordered by start time.
pub fn get_climbing_wall(req: Request, ctx: web.Context) -> Response {
  use <- wisp.require_method(req, Get)
  use user <- web.with_authenticated_user(ctx)
  use include_call_offs <- with_include_call_offs(req, user)
  use day <- with_day(req)
  use embeds <- with_embeds(ctx)
  let #(day_start, day_end) = day_bounds(day)
  response_from_db_activity_summaries(
    req,
    sql.list_climbing_wall_activities(
      ctx.db_connection,
      include_call_offs,
      day_start,
      day_end,
    ),
    activity.from_list_climbing_wall_activities_row(_, embeds),
    list_audience(include_call_offs),
  )
}

/// Returns the authenticated user's favourited and booked activities as slim
/// summaries, ordered by start time. Used to hydrate the client's entity cache
/// with favourites the user may not have browsed to yet; membership of the
/// Favourites tab is derived from `/api/statuses/me`, not from this list.
pub fn get_favourited(req: Request, ctx: web.Context) -> Response {
  use <- wisp.require_method(req, Get)
  use user <- web.with_authenticated_user(ctx)
  use embeds <- with_embeds(ctx)
  response_from_db_activity_summaries(
    req,
    sql.list_favourited_activities(ctx.db_connection, user.id),
    activity.from_list_favourited_activities_row(_, embeds),
    // Per-user list (keyed on the caller's id), so it must never be shared.
    web.ScopedToUser,
  )
}

pub fn get_one(req: Request, id: String, ctx: web.Context) -> Response {
  use <- wisp.require_method(req, Get)
  use activity_id <- given.ok(uuid.from_string(id), fn(_) {
    wisp.bad_request("Invalid activity ID format")
  })
  use embeds <- with_embeds(ctx)
  case sql.get_activity(ctx.db_connection, activity_id) {
    Error(error) -> web.query_error(error)
    Ok(pog.Returned(_, [])) -> wisp.not_found()
    Ok(pog.Returned(_, [row, ..])) ->
      wisp.json_response(
        row
          |> activity.from_get_activity_row(embeds)
          |> activity.to_json
          |> json.to_string,
        200,
      )
  }
}

pub fn delete(req: Request, id: String, ctx: web.Context) -> Response {
  use <- wisp.require_method(req, Delete)
  web.discard_body(req)
  use user <- web.with_authenticated_user(ctx)
  use <- web.require_role(user, web.ActivitiesManage)
  use activity_id <- given.ok(uuid.from_string(id), fn(_) {
    wisp.bad_request("Invalid activity ID format")
  })

  let transaction_result =
    pog.transaction(ctx.db_connection, fn(conn) {
      use _ <- result.try(sql.delete_activity_tag_links(conn, activity_id))
      use _ <- result.try(sql.delete_activity_target_groups(conn, activity_id))
      use deleted <- result.try(sql.delete_activity(conn, activity_id))
      Ok(deleted)
    })
  case transaction_result {
    Ok(pog.Returned(_, [])) -> wisp.not_found()
    Ok(pog.Returned(_, [_, ..])) -> wisp.no_content()
    Error(error) -> transaction_error(error)
  }
}

pub type ActivityInput {
  ActivityInput(
    title: BilingualString,
    description: BilingualString,
    max_attendees: Option(Int),
    start_time: Int,
    end_time: Int,
    tags: List(Uuid),
    target_groups: List(TargetGroup),
    /// The chosen location's id, or `None` for no location. Omitting the field
    /// or sending `null` both clear the location.
    location_id: Option(Uuid),
  )
}

fn activity_input_decoder() -> decode.Decoder(ActivityInput) {
  use title <- decode.field("title", model.bilingual_string_decoder())
  use description <- decode.field(
    "description",
    model.bilingual_string_decoder(),
  )
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
  use tags <- decode.optional_field("tags", [], decode.list(uuid_decoder()))
  use target_groups <- decode.optional_field(
    "target_groups",
    [],
    decode.list(model.target_group_decoder()),
  )
  use location_id <- decode.optional_field(
    "location_id",
    None,
    decode.optional(uuid_decoder()),
  )
  decode.success(ActivityInput(
    title:,
    description:,
    max_attendees:,
    start_time:,
    end_time:,
    tags:,
    target_groups:,
    location_id:,
  ))
}

/// Renders the 201 response for a created activity, or the appropriate error.
fn creation_response(
  transaction_result: Result(
    pog.Returned(a),
    pog.TransactionError(pog.QueryError),
  ),
  to_activity: fn(a) -> model.Activity,
) -> Response {
  case transaction_result {
    Ok(pog.Returned(_, [row, ..])) -> {
      let created = to_activity(row)
      wisp.json_response(activity.to_json(created) |> json.to_string, 201)
      |> wisp.set_header(
        "location",
        web.base_path <> "/api/activities/" <> uuid.to_string(created.id),
      )
    }
    Ok(pog.Returned(_, [])) -> wisp.internal_server_error()
    Error(error) -> transaction_error(error)
  }
}

pub fn create(req: Request, ctx: web.Context) -> Response {
  use <- wisp.require_method(req, Post)
  use user <- web.with_authenticated_user(ctx)
  use <- web.require_role(user, web.ActivitiesManage)
  use json_body <- wisp.require_json(req)
  use input <- given.ok(decode.run(json_body, activity_input_decoder()), fn(_) {
    wisp.bad_request("Invalid JSON payload")
  })
  let id = uuid.v7()
  let start_time = timestamp.from_unix_seconds(input.start_time)
  let end_time = timestamp.from_unix_seconds(input.end_time)
  let target_groups_sql =
    list.map(input.target_groups, activity.model_target_group_to_sql)
  // Locations are fetched so the chosen id can be validated and resolved for
  // the response. The insert doesn't set `location_id` (it's written separately,
  // below), so the response location is stitched in afterwards.
  use locations <- with_locations(ctx)
  use <- require_valid_location(locations, input.location_id)
  let location = chosen_location(locations, input.location_id)

  // Tags and target groups come from the request body we just wrote; a new
  // activity is never called off. A created row's `location_id` is NULL and the
  // response location is set by `with_location` below, so no locations are
  // needed in the embeds here.
  let embeds =
    embeds_for_one(dict.new(), id, input.tags, input.target_groups, dict.new())

  case input.max_attendees {
    Some(max_attendees) ->
      pog.transaction(ctx.db_connection, fn(conn) {
        use created <- result.try(sql.create_activity_with_max_attendees(
          conn,
          id,
          input.title.sv,
          input.title.en,
          input.description.sv,
          input.description.en,
          max_attendees,
          start_time,
          end_time,
        ))
        use _ <- result.try(sql.insert_activity_tag_links(conn, id, input.tags))
        use _ <- result.try(sql.insert_activity_target_groups(
          conn,
          id,
          target_groups_sql,
        ))
        use _ <- result.try(set_new_activity_location(
          conn,
          id,
          input.location_id,
        ))
        Ok(created)
      })
      |> creation_response(fn(row) {
        activity.from_create_activity_with_max_attendees_row(row, embeds)
        |> with_location(location)
      })
    None ->
      pog.transaction(ctx.db_connection, fn(conn) {
        use created <- result.try(sql.create_activity_without_max_attendees(
          conn,
          id,
          input.title.sv,
          input.title.en,
          input.description.sv,
          input.description.en,
          start_time,
          end_time,
        ))
        use _ <- result.try(sql.insert_activity_tag_links(conn, id, input.tags))
        use _ <- result.try(sql.insert_activity_target_groups(
          conn,
          id,
          target_groups_sql,
        ))
        use _ <- result.try(set_new_activity_location(
          conn,
          id,
          input.location_id,
        ))
        Ok(created)
      })
      |> creation_response(fn(row) {
        activity.from_create_activity_without_max_attendees_row(row, embeds)
        |> with_location(location)
      })
  }
}

/// Distinguishes a missing activity (404) from a genuine query failure (500)
/// inside the update transaction.
type UpdateError {
  ActivityNotFound
  UpdateQueryFailed(pog.QueryError)
}

/// Renders the 200 response for an updated activity, or the appropriate error.
fn update_response(
  transaction_result: Result(a, pog.TransactionError(UpdateError)),
  to_activity: fn(a) -> model.Activity,
) -> Response {
  case transaction_result {
    Ok(row) ->
      wisp.json_response(
        to_activity(row) |> activity.to_json |> json.to_string,
        200,
      )
    Error(pog.TransactionRolledBack(ActivityNotFound)) -> wisp.not_found()
    Error(error) -> {
      wisp.log_error("TransactionError " <> string.inspect(error))
      wisp.internal_server_error()
    }
  }
}

pub fn update(req: Request, id: String, ctx: web.Context) -> Response {
  use <- wisp.require_method(req, Put)
  use user <- web.with_authenticated_user(ctx)
  use <- web.require_role(user, web.ActivitiesManage)
  use activity_id <- given.ok(uuid.from_string(id), fn(_) {
    wisp.bad_request("Invalid activity ID format")
  })
  use json_body <- wisp.require_json(req)
  use input <- given.ok(decode.run(json_body, activity_input_decoder()), fn(_) {
    wisp.bad_request("Invalid JSON payload")
  })
  use locations <- with_locations(ctx)
  use <- require_valid_location(locations, input.location_id)
  let start_time = timestamp.from_unix_seconds(input.start_time)
  let end_time = timestamp.from_unix_seconds(input.end_time)
  let target_groups_sql =
    list.map(input.target_groups, activity.model_target_group_to_sql)
  let embeds =
    embeds_for_one(
      locations,
      activity_id,
      input.tags,
      input.target_groups,
      call_offs_for_one(ctx, activity_id),
    )
  // The update query returns the *old* `location_id` (its SET doesn't touch it;
  // the new location is written separately, below), so the response location is
  // stitched in afterwards via `with_location`.
  let location = chosen_location(locations, input.location_id)

  case input.max_attendees {
    Some(max_attendees) ->
      pog.transaction(ctx.db_connection, fn(conn) {
        use updated <- result.try(
          sql.update_activity_with_max_attendees(
            conn,
            activity_id,
            input.title.sv,
            input.title.en,
            input.description.sv,
            input.description.en,
            max_attendees,
            start_time,
            end_time,
          )
          |> result.map_error(UpdateQueryFailed),
        )
        case updated.rows {
          [] -> Error(ActivityNotFound)
          [row, ..] -> {
            use _ <- result.try(
              sql.resync_activity_tags_and_target_groups(
                conn,
                activity_id,
                input.tags,
                target_groups_sql,
              )
              |> result.map_error(UpdateQueryFailed),
            )
            use _ <- result.try(
              write_activity_location(conn, activity_id, input.location_id)
              |> result.map_error(UpdateQueryFailed),
            )
            Ok(row)
          }
        }
      })
      |> update_response(fn(row) {
        activity.from_update_activity_with_max_attendees_row(row, embeds)
        |> with_location(location)
      })
    None ->
      pog.transaction(ctx.db_connection, fn(conn) {
        use updated <- result.try(
          sql.update_activity_without_max_attendees(
            conn,
            activity_id,
            input.title.sv,
            input.title.en,
            input.description.sv,
            input.description.en,
            start_time,
            end_time,
          )
          |> result.map_error(UpdateQueryFailed),
        )
        case updated.rows {
          [] -> Error(ActivityNotFound)
          [row, ..] -> {
            use _ <- result.try(
              sql.resync_activity_tags_and_target_groups(
                conn,
                activity_id,
                input.tags,
                target_groups_sql,
              )
              |> result.map_error(UpdateQueryFailed),
            )
            use _ <- result.try(
              write_activity_location(conn, activity_id, input.location_id)
              |> result.map_error(UpdateQueryFailed),
            )
            Ok(row)
          }
        }
      })
      |> update_response(fn(row) {
        activity.from_update_activity_without_max_attendees_row(row, embeds)
        |> with_location(location)
      })
  }
}

// --- Call off --------------------------------------------------------------

type CallOffInput {
  CallOffInput(reason: String)
}

fn call_off_input_decoder() -> decode.Decoder(CallOffInput) {
  use reason <- decode.field("reason", decode.string)
  decode.success(CallOffInput(reason:))
}

/// Calls off (cancels) an activity with a reason. The activity stays in the
/// database and remains visible to users who booked or favourited it — the
/// call-off row just hides it from everyone else's browse lists and shows the
/// reason. Manager-only; idempotent (re-calling-off updates the reason).
pub fn cancel(req: Request, id: String, ctx: web.Context) -> Response {
  use <- wisp.require_method(req, Post)
  use user <- web.with_authenticated_user(ctx)
  use <- web.require_role(user, web.ActivitiesManage)
  use activity_id <- given.ok(uuid.from_string(id), fn(_) {
    wisp.bad_request("Invalid activity ID format")
  })
  use json_body <- wisp.require_json(req)
  use input <- given.ok(decode.run(json_body, call_off_input_decoder()), fn(_) {
    wisp.bad_request("Invalid JSON payload")
  })

  case sql.get_activity(ctx.db_connection, activity_id) {
    Error(error) -> web.query_error(error)
    Ok(pog.Returned(_, [])) -> wisp.not_found()
    Ok(pog.Returned(_, [row, ..])) ->
      case
        sql.create_call_off(
          ctx.db_connection,
          uuid.v7(),
          activity_id,
          input.reason,
        )
      {
        Error(error) -> web.query_error(error)
        Ok(_) -> {
          use embeds <- with_embeds(ctx)
          wisp.json_response(
            row
              |> activity.from_get_activity_row(embeds)
              |> activity.to_json
              |> json.to_string,
            200,
          )
        }
      }
  }
}

// --- Activity tags ---------------------------------------------------------

pub type ActivityTagInput {
  ActivityTagInput(name: BilingualString)
}

fn activity_tag_input_decoder() -> decode.Decoder(ActivityTagInput) {
  use name <- decode.field("name", model.bilingual_string_decoder())
  decode.success(ActivityTagInput(name:))
}

/// Returns all activity tags.
pub fn get_tags(req: Request, ctx: web.Context) -> Response {
  use <- wisp.require_method(req, Get)
  case sql.list_activity_tags(ctx.db_connection) {
    Error(error) -> web.query_error(error)
    Ok(pog.Returned(_, rows)) -> {
      let tags = list.map(rows, activity.from_list_activity_tags_row)
      wisp.json_response(
        json.object([
          #("activity_tags", json.array(tags, activity.activity_tag_to_json)),
        ])
          |> json.to_string,
        200,
      )
    }
  }
}

pub fn get_tag(req: Request, id: String, ctx: web.Context) -> Response {
  use <- wisp.require_method(req, Get)
  use tag_id <- given.ok(uuid.from_string(id), fn(_) {
    wisp.bad_request("Invalid activity tag ID format")
  })
  case sql.get_activity_tag(ctx.db_connection, tag_id) {
    Error(error) -> web.query_error(error)
    Ok(pog.Returned(_, [])) -> wisp.not_found()
    Ok(pog.Returned(_, [row, ..])) ->
      activity.from_get_activity_tag_row(row)
      |> activity.activity_tag_to_json
      |> json.to_string
      |> wisp.json_response(200)
  }
}

pub fn create_tag(req: Request, ctx: web.Context) -> Response {
  use <- wisp.require_method(req, Post)
  use user <- web.with_authenticated_user(ctx)
  use <- web.require_role(user, web.ActivitiesManage)
  use body <- wisp.require_json(req)
  use input <- given.ok(decode.run(body, activity_tag_input_decoder()), fn(_) {
    wisp.bad_request("Invalid JSON payload")
  })
  let id = uuid.v7()
  case
    sql.create_activity_tag(ctx.db_connection, id, input.name.sv, input.name.en)
  {
    Error(error) -> web.query_error(error)
    Ok(pog.Returned(_, [])) -> wisp.internal_server_error()
    Ok(pog.Returned(_, [row, ..])) -> {
      let created = activity.from_create_activity_tag_row(row)
      created
      |> activity.activity_tag_to_json
      |> json.to_string
      |> wisp.json_response(201)
      |> wisp.set_header(
        "location",
        web.base_path <> "/api/activity-tags/" <> uuid.to_string(created.id),
      )
    }
  }
}

pub fn update_tag(req: Request, id: String, ctx: web.Context) -> Response {
  use <- wisp.require_method(req, Put)
  use user <- web.with_authenticated_user(ctx)
  use <- web.require_role(user, web.ActivitiesManage)
  use tag_id <- given.ok(uuid.from_string(id), fn(_) {
    wisp.bad_request("Invalid activity tag ID format")
  })
  use body <- wisp.require_json(req)
  use input <- given.ok(decode.run(body, activity_tag_input_decoder()), fn(_) {
    wisp.bad_request("Invalid JSON payload")
  })
  case
    sql.update_activity_tag(
      ctx.db_connection,
      tag_id,
      input.name.sv,
      input.name.en,
    )
  {
    Error(error) -> web.query_error(error)
    Ok(pog.Returned(_, [])) -> wisp.not_found()
    Ok(pog.Returned(_, [row, ..])) ->
      activity.from_update_activity_tag_row(row)
      |> activity.activity_tag_to_json
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
    wisp.bad_request("Invalid activity tag ID format")
  })
  let transaction_result =
    pog.transaction(ctx.db_connection, fn(conn) {
      use _ <- result.try(sql.delete_activity_links_by_tag(conn, tag_id))
      use deleted <- result.try(sql.delete_activity_tag(conn, tag_id))
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

import gleam/http.{Get}
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option}
import pog
import server/sql
import server/web
import shared/model
import wisp.{type Request, type Response}

/// The authenticated user's identity and access roles, as the client needs
/// them: `roles` are the Keycloak role strings the client parses; `name` and
/// `group_name` are the booker identity taken from the token and stored on any
/// booking the user makes (the client shows them as read-only in the booking
/// form). `group_name` is `null` when the token carries no scout group.
/// 401 when unauthenticated.
pub fn get_me(req: Request, ctx: web.Context) -> Response {
  use <- wisp.require_method(req, Get)
  use user <- web.with_authenticated_user(ctx)

  case group_name(ctx, user.group_id) {
    Error(error) -> web.query_error(error)
    Ok(group_name) ->
      wisp.json_response(
        json.object([
          #("name", json.string(user.name)),
          #("group_name", json.nullable(group_name, json.string)),
          #(
            "roles",
            json.array(list.map(user.roles, web.role_to_string), json.string),
          ),
        ])
          |> json.to_string,
        200,
      )
  }
}

/// The kår display name for the token's group id: the scout_group row's name,
/// or `"Kår <id>"` for a kårnummer not among the registered kårer — matching
/// the fallback the booking queries apply when joining scout_group.
fn group_name(
  ctx: web.Context,
  group_id: Option(Int),
) -> Result(Option(String), pog.QueryError) {
  case group_id {
    option.None -> Ok(option.None)
    option.Some(group_id) ->
      case sql.get_scout_group_name(ctx.db_connection, group_id) {
        Error(error) -> Error(error)
        Ok(pog.Returned(_, [row, ..])) -> Ok(option.Some(row.name))
        Ok(pog.Returned(_, [])) ->
          Ok(option.Some("Kår " <> int.to_string(group_id)))
      }
  }
}

/// The full registered-kår list, for the book-for-other kår picker. Gated to
/// `bookings:others:create` — the only users whose UI needs it. The body is
/// identical for every authorized caller and changes only when the scout_group
/// table does (a new registration-export migration), so it revalidates by ETag
/// as `SharedAcrossUsers`.
pub fn get_scout_groups(req: Request, ctx: web.Context) -> Response {
  use <- wisp.require_method(req, Get)
  use user <- web.with_authenticated_user(ctx)
  use <- web.require_role(user, web.BookingsOthersCreate)
  case sql.list_scout_groups(ctx.db_connection) {
    Error(error) -> web.query_error(error)
    Ok(pog.Returned(_, rows)) -> {
      let body =
        rows
        |> list.map(fn(row) { model.ScoutGroup(id: row.id, name: row.name) })
        |> model.scout_groups_to_json
        |> json.to_string
      web.json_response_with_etag(
        req,
        body,
        200,
        "private, no-cache",
        web.SharedAcrossUsers,
      )
    }
  }
}

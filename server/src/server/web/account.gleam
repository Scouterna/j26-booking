import gleam/http.{Get}
import gleam/json
import gleam/list
import gleam/option
import server/scout_group
import server/web
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

  let group_name = option.map(user.group_id, scout_group.group_id_to_name)

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

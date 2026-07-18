import gleam/http.{Get}
import gleam/json
import gleam/list
import gleam/option
import server/scout_group
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

/// The full registered-kår list, for the book-for-other kår picker. Gated to
/// `bookings:others:create` — the only users whose UI needs it. The body is
/// identical for every authorized caller and changes only on deploy (the list
/// is compiled in), so it revalidates by ETag as `SharedAcrossUsers`.
pub fn get_scout_groups(req: Request, ctx: web.Context) -> Response {
  use <- wisp.require_method(req, Get)
  use user <- web.with_authenticated_user(ctx)
  use <- web.require_role(user, web.BookingsOthersCreate)
  let body = scout_group.groups |> model.scout_groups_to_json |> json.to_string
  web.json_response_with_etag(
    req,
    body,
    200,
    "private, no-cache",
    web.SharedAcrossUsers,
  )
}

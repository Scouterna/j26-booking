import gleam/http.{Get}
import gleam/json
import gleam/list
import server/web
import wisp.{type Request, type Response}

/// The authenticated user's access roles, as the Keycloak role strings the
/// client parses. 401 when unauthenticated.
pub fn get_me(req: Request, ctx: web.Context) -> Response {
  use <- wisp.require_method(req, Get)
  use user <- web.with_authenticated_user(ctx)

  wisp.json_response(
    json.object([
      #(
        "roles",
        json.array(list.map(user.roles, web.role_to_string), json.string),
      ),
    ])
      |> json.to_string,
    200,
  )
}

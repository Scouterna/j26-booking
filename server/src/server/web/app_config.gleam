import gleam/json.{type Json}
import gleam/list
import server/web.{type Context}
import wisp.{type Response}

/// Helper to generate a page navigation item
fn page(id: String, label: String, icon: String, path: String) -> Json {
  json.object([
    #("type", json.string("page")),
    #("id", json.string(id)),
    #("label", json.string(label)),
    #("icon", json.string(icon)),
    #("path", json.string(path)),
  ])
}

/// Whether the request's authenticated user may manage activities. Mirrors the
/// server's `require_role`: `Admin` implies every role. Anonymous or invalid
/// tokens never qualify.
fn can_manage_activities(ctx: Context) -> Bool {
  case ctx.authentication_result {
    web.Authenticated(user) ->
      list.contains(user.roles, web.ActivitiesManage)
      || list.contains(user.roles, web.Admin)
    web.NotAuthenticated | web.InvalidToken -> False
  }
}

pub fn navigation(ctx: Context) -> Response {
  // The manage-activities page is included only for users who may manage
  // activities, so the shell surfaces it in the "More" menu only to them. The
  // page itself is a copy of the activities list that links each card to its
  // edit view (see the client's `ManageList`).
  let pages = [
    page(
      "page_activities",
      "booking.activities.label",
      "campfire",
      "../activities",
    ),
    ..case can_manage_activities(ctx) {
      True -> [
        page(
          "page_manage_activities",
          "booking.manage_activities.label",
          "pencil",
          "../activities/manage",
        ),
      ]
      False -> []
    }
  ]
  json.object([#("navigation", json.preprocessed_array(pages))])
  |> json.to_string
  |> wisp.json_response(200)
}

import gleam/json.{type Json}
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

pub fn navigation() -> Response {
  json.object([
    #(
      "navigation",
      json.preprocessed_array([
        page(
          "page_activities",
          "booking.activities.label",
          "campfire",
          "../activities",
        ),
      ]),
    ),
  ])
  |> json.to_string
  |> wisp.json_response(200)
}

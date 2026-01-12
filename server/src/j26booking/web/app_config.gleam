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
        json.object([
          #("type", json.string("group")),
          #("id", json.string("group_booking")),
          #("label", json.string("booking.schedule.label")),
          #(
            "children",
            json.preprocessed_array([
              page(
                "page_all_activities",
                "booking.all_activities.label",
                "campfire",
                "../activities",
              ),
              page(
                "page_my_schedule",
                "booking.my_schedule.label",
                "calendar-event",
                "../",
              ),
            ]),
          ),
        ]),
      ]),
    ),
  ])
  |> json.to_string
  |> wisp.json_response(200)
}

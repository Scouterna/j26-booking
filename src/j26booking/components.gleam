import gleam/int
import gleam/list
import gleam/option.{None}
import hx
import lustre/attribute
import lustre/element
import lustre/element/html

pub fn activities_list(base_path: String, activity_names: List(String)) {
  html.table(
    [],
    list.index_map(activity_names, fn(name, booking_id) {
      html.tr([], [
        html.td([], [element.text(name)]),
        html.td([], [
          html.button(
            [
              hx.post(base_path <> "/book/" <> int.to_string(booking_id)),
              hx.swap(hx.OuterHTML, None),
            ],
            [element.text("Book")],
          ),
        ]),
      ])
    }),
  )
}

pub fn activities_page(
  base_path: String,
  activity_names: List(String),
  search_query: String,
) {
  html.html([], [
    html.head([], [
      html.meta([attribute.attribute("charset", "UTF-8")]),
      html.title([], "Activities"),
      html.script(
        [
          attribute.src(
            "https://cdn.jsdelivr.net/npm/htmx.org@2.0.6/dist/htmx.min.js",
          ),
        ],
        "",
      ),
    ]),
    html.body([], [
      html.h1([], [element.text("Activities")]),
      html.div([], [
        html.input([
          attribute.type_("text"),
          attribute.name("q"),
          attribute.placeholder("Search activities..."),
          attribute.value(search_query),
          hx.get(base_path <> "/activities"),
          attribute.attribute("hx-trigger", "keyup changed delay:300ms"),
          attribute.attribute("hx-target", "#activities-list"),
        ]),
      ]),
      html.div([attribute.id("activities-list")], [
        activities_list(base_path, activity_names),
      ]),
    ]),
  ])
}

pub fn index_page() {
  html.html([attribute.attribute("lang", "en")], [
    html.head([], [
      html.meta([attribute.charset("UTF-8")]),
      html.title([], "Jamboree 2026 Booking"),
      html.script(
        [
          attribute.src(
            "https://cdn.jsdelivr.net/npm/htmx.org@2.0.6/dist/htmx.min.js",
          ),
        ],
        "",
      ),
    ]),
    html.body([], [
      html.h1([], [html.text("Welcome to Jamboree 2026")]),
      html.p([], [html.text("Book your activities for the event")]),
      html.a([attribute.href("/activities")], [
        html.button([], [html.text("View Activities")]),
      ]),
    ]),
  ])
}

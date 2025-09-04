import gleam/int
import gleam/list
import gleam/option.{None}
import hx
import lustre/element
import lustre/element/html

pub fn activities(activity_names: List(String)) {
  html.table(
    [],
    list.index_map(activity_names, fn(name, booking_id) {
      html.tr([], [
        html.td([], [element.text(name)]),
        html.td([], [
          html.button(
            [
              hx.post("/book/" <> int.to_string(booking_id)),
              hx.swap(hx.OuterHTML, None),
            ],
            [element.text("Book")],
          ),
        ]),
      ])
    }),
  )
}

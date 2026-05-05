import formal/form.{type Form}
import gleam/dynamic/decode
import gleam/int
import gleam/list
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

import icons

pub fn scout_card(children: List(Element(msg))) -> Element(msg) {
  element.element("scout-card", [], children)
}

pub fn scout_field(label: String, child: Element(msg)) -> Element(msg) {
  element.element("scout-field", [attribute.attribute("label", label)], [child])
}

pub fn scout_form_field(
  f: Form(a),
  label: String,
  input_type: String,
  name: String,
) -> Element(msg) {
  let errors = form.field_error_messages(f, name)
  scout_field(
    label,
    element.fragment([
      element.element(
        "scout-input",
        [
          attribute.attribute("type", input_type),
          attribute.attribute("name", name),
          attribute.attribute("value", form.field_value(f, name)),
        ],
        [],
      ),
      ..list.map(errors, fn(msg) {
        html.small(
          [
            attribute.styles([
              #("color", "var(--color-text-danger-base)"),
            ]),
          ],
          [element.text(msg)],
        )
      })
    ]),
  )
}

pub fn scout_button_action(
  text: String,
  variant: String,
  msg: msg,
) -> Element(msg) {
  element.element(
    "scout-button",
    [
      attribute.attribute("variant", variant),
      event.on("scoutClick", decode.success(msg)),
    ],
    [element.text(text)],
  )
}

pub fn scout_button_el(text: String, variant: String) -> Element(msg) {
  element.element("scout-button", [attribute.attribute("variant", variant)], [
    element.text(text),
  ])
}

pub fn scout_button_icon(
  text: String,
  variant: String,
  icon: String,
) -> Element(msg) {
  element.element(
    "scout-button",
    [
      attribute.attribute("variant", variant),
      attribute.attribute("icon", icon),
      attribute.attribute("icon-only", ""),
      attribute.attribute("aria-label", text),
    ],
    [],
  )
}

pub fn scout_loader(text: String) -> Element(msg) {
  element.element(
    "scout-loader",
    [
      attribute.attribute("text", text),
      attribute.attribute("size", "base"),
    ],
    [],
  )
}

pub fn error_banner(message: String) -> Element(msg) {
  html.div(
    [
      attribute.styles([
        #("padding", "var(--spacing-2) var(--spacing-4)"),
        #("background", "var(--color-background-danger-base)"),
        #("color", "var(--color-text-danger-base)"),
        #("border-radius", "4px"),
      ]),
    ],
    [element.text(message)],
  )
}

pub fn quick_info_tile(
  svg: String,
  title: String,
  content: List(Element(msg)),
) -> Element(msg) {
  html.div([attribute.class("flex flex-col")], [
    html.div([attribute.class("flex items-center gap-1 text-gray-800")], [
      icon(svg, "size-4"),
      html.div([attribute.class("text-body-sm")], [
        element.text(title),
      ]),
    ]),
    html.div([], content),
  ])
}

pub fn icon(svg: String, class: String) -> Element(msg) {
  element.unsafe_raw_html("", "div", [attribute.class(class)], svg)
}

pub fn scout_input_search(
  value: String,
  placeholder: String,
  on_input: fn(String) -> msg,
) -> Element(msg) {
  element.element(
    "scout-input",
    [
      attribute.attribute("type", "search"),
      attribute.attribute("value", value),
      attribute.attribute("placeholder", placeholder),
      event.on_input(on_input),
    ],
    [],
  )
}

/// Segmented control for mutually-exclusive filter choices.
/// `value` is the zero-based index of the active segment.
/// `on_change` receives the new index from a `scoutChange` event.
pub fn scout_segmented_control(
  value: Int,
  options: List(String),
  on_change: fn(Int) -> msg,
) -> Element(msg) {
  element.element(
    "scout-segmented-control",
    [
      attribute.attribute("value", int.to_string(value)),
      attribute.attribute("size", "small"),
      event.on("scoutChange", {
        use new_value <- decode.subfield(["detail", "value"], decode.int)
        decode.success(on_change(new_value))
      }),
    ],
    list.map(options, fn(label) {
      html.button([attribute.type_("button")], [element.text(label)])
    }),
  )
}

pub fn filter_pill(label: String, active: Bool, msg: msg) -> Element(msg) {
  let variant = case active {
    True -> "primary"
    False -> "outlined"
  }
  element.element(
    "scout-button",
    [
      attribute.attribute("variant", variant),
      attribute.attribute("size", "small"),
      event.on("scoutClick", decode.success(msg)),
    ],
    [element.text(label)],
  )
}

pub fn filter_pill_icon(
  aria_label: String,
  icon_svg: String,
  active: Bool,
  msg: msg,
) -> Element(msg) {
  let variant = case active {
    True -> "primary"
    False -> "outlined"
  }
  element.element(
    "scout-button",
    [
      attribute.attribute("variant", variant),
      attribute.attribute("size", "small"),
      attribute.attribute("icon", icon_svg),
      attribute.attribute("icon-only", ""),
      attribute.attribute("aria-label", aria_label),
      event.on("scoutClick", decode.success(msg)),
    ],
    [],
  )
}

pub fn filter_chip(label: String, selected: Bool, msg: msg) -> Element(msg) {
  let base = "px-3 py-1 rounded-full text-body-sm border cursor-pointer "
  let class = case selected {
    True -> base <> "bg-blue-100 border-blue-500 text-blue-900"
    False -> base <> "bg-white border-gray-300 text-gray-800"
  }
  html.button(
    [
      attribute.type_("button"),
      attribute.class(class),
      event.on_click(msg),
    ],
    [element.text(label)],
  )
}

pub fn activity_card(
  href: String,
  title: String,
  is_booked: Bool,
  booked_label: String,
  time: Element(msg),
  location: String,
  spots_remaining_text: String,
) -> Element(msg) {
  let booked_accent = case is_booked {
    True -> " border-l-4 border-l-green-600"
    False -> ""
  }
  html.a(
    [
      attribute.href(href),
      attribute.class(
        "block no-underline text-current rounded-lg border border-gray-200 bg-white px-4 py-3 transition-shadow shadow-sm hover:shadow-md active:shadow-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue-500"
        <> booked_accent,
      ),
    ],
    [
      html.div(
        [attribute.class("flex items-start justify-between gap-3 mb-2")],
        [
          html.h3([attribute.class("text-body-l font-semibold leading-tight")], [
            element.text(title),
          ]),
          case is_booked {
            True ->
              html.span(
                [
                  attribute.class(
                    "shrink-0 rounded-full bg-green-100 text-green-800 text-body-sm font-semibold px-2 py-0.5",
                  ),
                ],
                [element.text(booked_label)],
              )
            False -> element.none()
          },
        ],
      ),
      html.dl(
        [
          attribute.class(
            "grid grid-cols-[auto_1fr] gap-x-2 gap-y-1 text-body-sm text-gray-700 m-0",
          ),
        ],
        [
          html.dt([attribute.class("flex items-center text-gray-500")], [
            icon(icons.clock, "size-4"),
          ]),
          html.dd([attribute.class("m-0")], [time]),
          html.dt([attribute.class("flex items-center text-gray-500")], [
            icon(icons.pin, "size-4"),
          ]),
          html.dd([attribute.class("m-0")], [element.text(location)]),
          html.dt([attribute.class("flex items-center text-gray-500")], [
            icon(icons.users, "size-4"),
          ]),
          html.dd([attribute.class("m-0")], [
            element.text(spots_remaining_text),
          ]),
        ],
      ),
    ],
  )
}

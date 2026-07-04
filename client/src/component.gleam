import formal/form.{type Form}
import gleam/dynamic/decode
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
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
      attribute.attribute("icon", icons.search),
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
  attrs: List(attribute.Attribute(msg)),
) -> Element(msg) {
  element.element(
    "scout-segmented-control",
    [
      attribute.attribute("value", int.to_string(value)),
      attribute.attribute("size", "large"),
      event.on("scoutChange", {
        use new_value <- decode.subfield(["detail", "value"], decode.int)
        decode.success(on_change(new_value))
      }),
      ..attrs
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
    True -> base <> "bg-background-brand-base border-transparent text-white"
    False -> base <> "bg-white border-gray-300 text-gray-800"
  }
  let aria_pressed = case selected {
    True -> "true"
    False -> "false"
  }
  html.button(
    [
      attribute.type_("button"),
      attribute.class(class),
      attribute.aria_pressed(aria_pressed),
      event.on_click(msg),
    ],
    [element.text(label)],
  )
}

pub type BadgeTone {
  BadgeGreen
  BadgePurple
}

/// Rounded, coloured pill used for status labels.
/// Background uses the 100 shade; text uses the 600 shade.
pub fn badge(tone: BadgeTone, label: String) -> Element(msg) {
  let tone_classes = case tone {
    BadgeGreen -> "text-(--color-green-600) bg-(--color-green-100)"
    BadgePurple -> "text-(--color-purple-600) bg-(--color-purple-100)"
  }
  html.span(
    [
      attribute.class(
        "inline-flex items-center rounded-full px-2 py-0.5 text-body-sm font-semibold "
        <> tone_classes,
      ),
    ],
    [element.text(label)],
  )
}

pub type CardStatus {
  StatusNone
  StatusBooked(label: String)
  StatusNeedsBooking(label: String)
}

/// Favourite toggle rendered as an outlined, icon-only round button.
/// `locked` (e.g. an activity the user has booked) renders a non-interactive,
/// muted heart. `in_link` stops the click from triggering an enclosing `<a>`.
pub fn heart_button(
  favourited: Bool,
  locked: Bool,
  on_toggle: msg,
  in_link: Bool,
) -> Element(msg) {
  let svg = case favourited {
    True -> icons.heart_filled
    False -> icons.heart
  }
  // Mirror the filter pill: same icon-only scout-button chrome, primary when
  // active (favourited) and outlined otherwise.
  let variant = case favourited {
    True -> "primary"
    False -> "outlined"
  }
  let base_attrs = [
    attribute.attribute("variant", variant),
    attribute.attribute("size", "small"),
    attribute.attribute("icon", svg),
    attribute.attribute("icon-only", ""),
    attribute.attribute("aria-label", "Toggle favourite"),
  ]
  case locked {
    True ->
      element.element(
        "scout-button",
        [attribute.attribute("disabled", ""), ..base_attrs],
        [],
      )
    False -> {
      // scout-button emits scoutClick but lets the native click keep bubbling,
      // so inside the card link we listen for the native click to stop it from
      // following the link; elsewhere the dedicated scoutClick event is enough.
      let click = case in_link {
        True ->
          event.on("click", decode.success(on_toggle))
          |> event.stop_propagation
          |> event.prevent_default
        False -> event.on("scoutClick", decode.success(on_toggle))
      }
      element.element("scout-button", [click, ..base_attrs], [])
    }
  }
}

pub fn activity_card(
  href: String,
  title: String,
  status: CardStatus,
  favourited: Bool,
  on_toggle_favourite: option_msg,
  time: Element(option_msg),
  location: Option(String),
  spots_remaining_text: Option(String),
) -> Element(option_msg) {
  let heart_locked = case status {
    StatusBooked(_) -> True
    _ -> False
  }
  let heart_btn =
    heart_button(favourited, heart_locked, on_toggle_favourite, True)
  let status_badge = case status {
    StatusBooked(label) -> badge(BadgeGreen, label)
    StatusNeedsBooking(label) -> badge(BadgePurple, label)
    StatusNone -> element.none()
  }
  // Whole card is a link; scout-card supplies the surface (white, rounded,
  // padded). Shadow + hover live on the anchor so the affordance survives the
  // shadow-DOM boundary, with the radius matched to scout-card's.
  html.a(
    [
      attribute.href(href),
      attribute.class(
        "block no-underline text-current transition-shadow shadow-sm hover:shadow-md active:shadow-sm rounded-[var(--spacing-6)] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue-500",
      ),
    ],
    [
      scout_card([
        html.div([attribute.class("flex flex-col gap-2")], [
          // Header: title, status badge and heart share one row.
          html.div([attribute.class("flex items-start gap-3")], [
            html.h3(
              [
                attribute.class(
                  "flex-1 min-w-0 text-body-l font-semibold leading-tight break-words",
                ),
              ],
              [element.text(title)],
            ),
            html.div([attribute.class("shrink-0 flex items-start gap-2")], [
              status_badge,
              heart_btn,
            ]),
          ]),
          // Meta: time and place (plus spots when capped) on a single row.
          html.div(
            [
              attribute.class(
                "flex flex-wrap items-center gap-x-4 gap-y-1 text-body-sm text-gray-700",
              ),
            ],
            list.flatten([
              [card_meta(icons.clock, time)],
              case location {
                Some(name) -> [card_meta(icons.pin, element.text(name))]
                None -> []
              },
              case spots_remaining_text {
                Some(text) -> [card_meta(icons.users, element.text(text))]
                None -> []
              },
            ]),
          ),
        ]),
      ]),
    ],
  )
}

/// One icon + value pair on the card's single-row meta line.
fn card_meta(icon_svg: String, child: Element(msg)) -> Element(msg) {
  html.span([attribute.class("inline-flex items-center gap-1")], [
    icon(icon_svg, "size-4 text-gray-500"),
    child,
  ])
}

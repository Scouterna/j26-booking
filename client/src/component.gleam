import formal/form.{type Form}
import gleam/dynamic/decode
import gleam/int
import gleam/json
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

/// A labelled, non-editable `scout-input` showing a fixed value. Used for
/// values that are displayed for context but cannot be changed by the user
/// (e.g. the booker identity taken from the login token). Rendered `disabled`
/// so it reads as read-only and never submits with the form.
pub fn scout_readonly_field(label: String, value: String) -> Element(msg) {
  scout_field(
    label,
    element.element(
      "scout-input",
      [
        attribute.attribute("value", value),
        attribute.attribute("disabled", ""),
      ],
      [],
    ),
  )
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

/// A `scout-input type="number"` form field with a `min` and an optional `max`
/// bound. `max` is `None` for an uncapped field. Mirrors `scout_form_field`,
/// including the error `<small>`s beneath the input.
pub fn scout_form_number_field(
  f: Form(a),
  label: String,
  name: String,
  min: Int,
  max: Option(Int),
) -> Element(msg) {
  let errors = form.field_error_messages(f, name)
  let max_attr = case max {
    Some(limit) -> [attribute.attribute("max", int.to_string(limit))]
    None -> []
  }
  scout_field(
    label,
    element.fragment([
      element.element(
        "scout-input",
        [
          attribute.attribute("type", "number"),
          attribute.attribute("name", name),
          attribute.attribute("value", form.field_value(f, name)),
          attribute.attribute("min", int.to_string(min)),
          ..max_attr
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

/// Like `scout_form_field` but a multi-line `scout-text-area` for longer text
/// (e.g. descriptions). Uncontrolled (no `on_input`) so its value is seeded once
/// and read from the form on submit, matching the other fields.
pub fn scout_textarea_field(
  f: Form(a),
  label: String,
  name: String,
  rows: Int,
) -> Element(msg) {
  let errors = form.field_error_messages(f, name)
  scout_field(
    label,
    element.fragment([
      element.element(
        "scout-text-area",
        [
          attribute.attribute("name", name),
          attribute.attribute("rows", int.to_string(rows)),
          attribute.attribute("value", form.field_value(f, name)),
        ],
        [],
      ),
      ..list.map(errors, fn(msg) {
        html.small(
          [attribute.styles([#("color", "var(--color-text-danger-base)")])],
          [element.text(msg)],
        )
      })
    ]),
  )
}

pub fn scout_button_action(
  text: String,
  variant: ButtonVariant,
  msg: msg,
) -> Element(msg) {
  element.element(
    "scout-button",
    [
      attribute.attribute("variant", button_variant_to_string(variant)),
      event.on("scoutClick", decode.success(msg)),
    ],
    [element.text(text)],
  )
}

pub fn scout_button_disabled(
  text: String,
  variant: ButtonVariant,
) -> Element(msg) {
  element.element(
    "scout-button",
    [
      attribute.attribute("variant", button_variant_to_string(variant)),
      attribute.attribute("disabled", ""),
    ],
    [element.text(text)],
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

pub fn scout_drawer(
  open: Bool,
  heading: String,
  on_exit: msg,
  content: List(Element(msg)),
) -> Element(msg) {
  element.element(
    "scout-drawer",
    [
      attribute.property("open", json.bool(open)),
      attribute.attribute("heading", heading),
      attribute.attribute("show-exit-button", "true"),
      event.on("exitButtonClicked", decode.success(on_exit)),
    ],
    content,
  )
}

/// Visual intent of a `scout-callout` — the component's six `variant`
/// attribute values, typed so a call site can't pass a string the component
/// silently ignores.
pub type CalloutVariant {
  CalloutInfo
  CalloutTip
  CalloutSuccess
  CalloutWarning
  CalloutError
  CalloutAnnouncement
}

fn callout_variant_to_string(variant: CalloutVariant) -> String {
  case variant {
    CalloutInfo -> "info"
    CalloutTip -> "tip"
    CalloutSuccess -> "success"
    CalloutWarning -> "warning"
    CalloutError -> "error"
    CalloutAnnouncement -> "announcement"
  }
}

/// Visual style of a `scout-button` — the component's five `variant`
/// attribute values.
pub type ButtonVariant {
  ButtonPrimary
  ButtonOutlined
  ButtonText
  ButtonCaution
  ButtonDanger
}

fn button_variant_to_string(variant: ButtonVariant) -> String {
  case variant {
    ButtonPrimary -> "primary"
    ButtonOutlined -> "outlined"
    ButtonText -> "text"
    ButtonCaution -> "caution"
    ButtonDanger -> "danger"
  }
}

/// A `scout-button` for a callout's `actions` slot. Any button variant works
/// here — the slot only lays actions out in a row.
pub fn callout_action(
  text: String,
  variant: ButtonVariant,
  msg: msg,
) -> Element(msg) {
  element.element(
    "scout-button",
    [
      attribute.attribute("slot", "actions"),
      attribute.attribute("variant", button_variant_to_string(variant)),
      event.on("scoutClick", decode.success(msg)),
    ],
    [element.text(text)],
  )
}

/// A dismissable callout hovering at the bottom of the viewport, floating
/// over the page content instead of displacing it — for error/warning
/// messages that annotate a list or page (e.g. the partially-loaded
/// "Alla dagar" week). `actions` are `callout_action` buttons rendered in the
/// callout's actions slot; the component's built-in dismiss (×) button fires
/// `on_dismiss` — the caller owns the shown/dismissed state.
pub fn hovering_callout(
  variant: CalloutVariant,
  heading: String,
  message: String,
  actions: List(Element(msg)),
  on_dismiss: msg,
) -> Element(msg) {
  html.div([attribute.class("fixed bottom-3 inset-x-3 z-20 mx-auto max-w-lg")], [
    element.element(
      "scout-callout",
      [
        attribute.class("shadow-lg"),
        attribute.attribute("variant", callout_variant_to_string(variant)),
        attribute.attribute("heading", heading),
        attribute.attribute("dismissible", ""),
        event.on("scoutDismiss", decode.success(on_dismiss)),
      ],
      [element.text(message), ..actions],
    ),
  ])
}

/// An inline callout with action buttons in the component's `actions` slot
/// (use `callout_action`) — for states where the callout is the content
/// itself, e.g. a failed view offering a retry. Contrast `hovering_callout`,
/// which floats over content it merely annotates.
pub fn callout(
  variant: CalloutVariant,
  heading: String,
  message: String,
  actions: List(Element(msg)),
) -> Element(msg) {
  element.element(
    "scout-callout",
    [
      attribute.attribute("variant", callout_variant_to_string(variant)),
      attribute.attribute("heading", heading),
    ],
    [element.text(message), ..actions],
  )
}

pub fn error_banner(heading: String, message: String) -> Element(msg) {
  callout(CalloutError, heading, message, [])
}

/// A warning-variant callout, used for the "called off" notice on a cancelled
/// activity's detail page.
pub fn warning_banner(heading: String, message: String) -> Element(msg) {
  callout(CalloutWarning, heading, message, [])
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
  BadgeRed
}

/// Rounded, coloured pill used for status labels.
/// Background uses the 100 shade; text uses the 600 shade.
pub fn badge(tone: BadgeTone, label: String) -> Element(msg) {
  let tone_classes = case tone {
    BadgeGreen -> "text-(--color-green-600) bg-(--color-green-100)"
    BadgePurple -> "text-(--color-purple-600) bg-(--color-purple-100)"
    BadgeRed -> "text-(--color-red-600) bg-(--color-red-100)"
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
  StatusCancelled(label: String)
}

/// The action shown in a card's top-right corner. `FavouriteAction` is the
/// interactive favourite heart (browse list); `EditAction` (manage list) carries
/// the message fired when the card is activated — the pen itself is decorative,
/// so a click anywhere on the card (pen included) opens the edit form drawer.
/// `NoAction` renders no corner affordance at all — the browse card of an
/// anonymous visitor, who cannot favourite (issue #20).
pub type CardAction(msg) {
  FavouriteAction(favourited: Bool, on_toggle: msg)
  EditAction(on_edit: msg)
  NoAction
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

/// Edit affordance for a manage-list card, mirroring the favourite heart's
/// chrome so the two read as one family. Purely decorative: it carries no
/// handler, so a click bubbles to the enclosing card (whose click opens the edit
/// form drawer), matching a click anywhere else on the card.
fn pen_button() -> Element(msg) {
  element.element(
    "scout-button",
    [
      attribute.attribute("variant", "outlined"),
      attribute.attribute("size", "small"),
      attribute.attribute("icon", icons.pencil),
      attribute.attribute("icon-only", ""),
      attribute.attribute("aria-label", "Edit activity"),
    ],
    [],
  )
}

pub fn activity_card(
  href: String,
  title: String,
  status: CardStatus,
  action: CardAction(msg),
  time: Element(msg),
  location: Option(String),
  spots_remaining_text: Option(String),
) -> Element(msg) {
  let corner = case action {
    FavouriteAction(favourited:, on_toggle:) -> {
      let heart_locked = case status {
        StatusBooked(_) -> True
        _ -> False
      }
      heart_button(favourited, heart_locked, on_toggle, True)
    }
    EditAction(_) -> pen_button()
    NoAction -> element.none()
  }
  // Browse cards navigate via the anchor's href; manage cards intercept the click
  // (keyboard Enter included) to open the edit drawer instead, keeping the list —
  // and its scroll — mounted. `stop_propagation` keeps the click from reaching
  // modem's global anchor handler (which would otherwise SPA-navigate); the href
  // stays a valid fallback for new-tab clicks.
  let activate = case action {
    FavouriteAction(..) | NoAction -> []
    EditAction(on_edit) -> [
      event.on("click", decode.success(on_edit))
      |> event.stop_propagation
      |> event.prevent_default,
    ]
  }
  let status_badge = case status {
    StatusBooked(label) -> badge(BadgeGreen, label)
    StatusNeedsBooking(label) -> badge(BadgePurple, label)
    StatusCancelled(label) -> badge(BadgeRed, label)
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
      ..activate
    ],
    [
      scout_card([
        html.div([attribute.class("flex flex-col gap-2")], [
          // Header: title, status badge and the corner action (heart or pen)
          // share one row.
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
              corner,
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

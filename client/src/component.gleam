import formal/form.{type Form}
import gleam/dynamic/decode
import gleam/list
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

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

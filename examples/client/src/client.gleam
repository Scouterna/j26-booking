import gleam/dynamic/decode
import gleam/int
import gleam/list
import gleam/string
import lustre
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

// MAIN ------------------------------------------------------------------------

pub fn main() {
  let app = lustre.simple(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

// MODEL -----------------------------------------------------------------------

type Model {
  Model(count: Int, name: String, active_tab: Int, agreed: Bool)
}

fn init(_flags) -> Model {
  Model(count: 0, name: "", active_tab: 0, agreed: False)
}

// UPDATE ----------------------------------------------------------------------

type Msg {
  Incremented
  Decremented
  NameChanged(String)
  TabChanged(Int)
  AgreedToggled(Bool)
}

fn update(model: Model, msg: Msg) -> Model {
  case msg {
    Incremented -> Model(..model, count: model.count + 1)
    Decremented -> Model(..model, count: model.count - 1)
    NameChanged(value) -> Model(..model, name: value)
    TabChanged(index) -> Model(..model, active_tab: index)
    AgreedToggled(checked) -> Model(..model, agreed: checked)
  }
}

// VIEW ------------------------------------------------------------------------

fn scout_button(text: String, variant: String, msg: Msg) -> Element(Msg) {
  element.element(
    "scout-button",
    [
      attribute.attribute("variant", variant),
      event.on("scoutClick", decode.success(msg)),
    ],
    [element.text(text)],
  )
}

fn scout_field(label: String, child: Element(Msg)) -> Element(Msg) {
  element.element("scout-field", [attribute.attribute("label", label)], [child])
}

fn scout_input(value: String, on_input: fn(String) -> Msg) -> Element(Msg) {
  element.element(
    "scout-input",
    [
      attribute.attribute("value", value),
      event.on_input(on_input),
    ],
    [],
  )
}

fn scout_checkbox(
  label: String,
  checked: Bool,
  on_check: fn(Bool) -> Msg,
) -> Element(Msg) {
  element.element(
    "scout-checkbox",
    [
      attribute.attribute("label", label),
      case checked {
        True -> attribute.attribute("checked", "")
        False -> attribute.none()
      },
      event.on("scoutChecked", {
        use checked <- decode.subfield(["detail", "checked"], decode.bool)
        decode.success(on_check(checked))
      }),
    ],
    [],
  )
}

fn scout_tabs(
  active: Int,
  labels: List(String),
  on_change: fn(Int) -> Msg,
) -> Element(Msg) {
  element.element(
    "scout-tabs",
    [
      attribute.attribute("value", int.to_string(active)),
      event.on("scoutChange", {
        use value <- decode.subfield(["detail", "value"], decode.int)
        decode.success(on_change(value))
      }),
    ],
    labels
      |> list.map(fn(label) {
        element.element("scout-tabs-tab", [], [element.text(label)])
      }),
  )
}

fn scout_card(children: List(Element(Msg))) -> Element(Msg) {
  element.element("scout-card", [], children)
}

fn scout_loader(text: String) -> Element(Msg) {
  element.element(
    "scout-loader",
    [
      attribute.attribute("text", text),
      attribute.attribute("size", "base"),
    ],
    [],
  )
}

fn view(model: Model) -> Element(Msg) {
  let count = int.to_string(model.count)
  let greeting = case string.is_empty(model.name) {
    True -> "World"
    False -> model.name
  }

  html.div(
    [
      attribute.styles([
        #("display", "flex"),
        #("flex-direction", "column"),
        #("gap", "var(--spacing-6)"),
      ]),
    ],
    [
      // App bar
      element.element(
        "scout-app-bar",
        [
          attribute.attribute("title-text", "Web Component Demo"),
        ],
        [],
      ),
      // Tabs
      scout_tabs(model.active_tab, ["Counter", "Form", "Misc"], TabChanged),
      // Tab content
      case model.active_tab {
        0 -> counter_tab(count)
        1 -> form_tab(model, greeting)
        _ -> misc_tab()
      },
    ],
  )
}

fn counter_tab(count: String) -> Element(Msg) {
  scout_card([
    html.div(
      [
        attribute.styles([
          #("display", "flex"),
          #("flex-direction", "column"),
          #("gap", "var(--spacing-4)"),
        ]),
      ],
      [
        html.p([], [html.text("Count: " <> count)]),
        html.div(
          [
            attribute.styles([
              #("display", "flex"),
              #("flex-direction", "row"),
              #("gap", "var(--spacing-2)"),
            ]),
          ],
          [
            scout_button("-", "outlined", Decremented),
            scout_button("+", "primary", Incremented),
          ],
        ),
      ],
    ),
  ])
}

fn form_tab(model: Model, greeting: String) -> Element(Msg) {
  scout_card([
    html.div(
      [
        attribute.styles([
          #("display", "flex"),
          #("flex-direction", "column"),
          #("gap", "var(--spacing-4)"),
        ]),
      ],
      [
        scout_field("Your name", scout_input(model.name, NameChanged)),
        html.p([], [html.text("Hello, " <> greeting <> "!")]),
        scout_checkbox("I agree to the terms", model.agreed, AgreedToggled),
        case model.agreed {
          True -> html.p([], [html.text("Thanks for agreeing!")])
          False -> element.none()
        },
      ],
    ),
  ])
}

fn misc_tab() -> Element(Msg) {
  scout_card([
    html.div(
      [
        attribute.styles([
          #("display", "flex"),
          #("flex-direction", "column"),
          #("gap", "var(--spacing-4)"),
        ]),
      ],
      [
        scout_loader("Loading something..."),
        element.element("scout-divider", [], []),
        element.element(
          "scout-link",
          [
            attribute.attribute("label", "Scouterna Storybook"),
            attribute.attribute(
              "href",
              "https://scouterna.github.io/j26-components/?path=/docs/home--docs",
            ),
            attribute.attribute("target", "_blank"),
          ],
          [],
        ),
      ],
    ),
  ])
}

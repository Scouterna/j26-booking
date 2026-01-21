import gleam/dynamic/decode
import gleam/int
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

/// The `Model` is the state of our entire application.
///
type Model =
  Int

/// The `init` function gets called when we first start our app. It sets the
/// initial state of the app.
///
fn init(_) -> Model {
  0
}

// UPDATE ----------------------------------------------------------------------

/// The `Msg` type describes all the ways the outside world can talk to our app.
/// That includes user input, network requests, and any other external events.
///
type Msg {
  UserClickedIncrement
  UserClickedDecrement
  ScoutClick
}

/// The `update` function is called every time we receive a message from the
/// outside world. We get the message and the current state of the app, and we
/// use those to calculate the new state.
///
fn update(model: Model, msg: Msg) -> Model {
  case msg {
    UserClickedIncrement -> model + 1
    UserClickedDecrement -> model - 1
    ScoutClick -> model + 10
  }
}

// VIEW ------------------------------------------------------------------------

fn scout_button(text: String, variant: String, msg: Msg) {
  element.element(
    "scout-button",
    [
      attribute.attribute("variant", variant),
      event.on("scoutClick", decode.success(msg)),
    ],
    [html.text(text)],
  )
}

/// The `view` function is called after every `update`. It takes the current
/// state of our application and renders it as an `Element`
fn view(model: Model) -> Element(Msg) {
  let count = int.to_string(model)

  html.div([], [
    scout_button("hej", "primary", ScoutClick),
    html.p([attribute.class("bg-blue-600")], [
      html.text("Counter: "),
      html.text(count),
    ]),
    scout_button("-", "primary", UserClickedDecrement),
    scout_button("+", "primary", UserClickedIncrement),
  ])
}

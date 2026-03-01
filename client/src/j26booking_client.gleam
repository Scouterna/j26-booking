import gleam/dynamic/decode
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/result
import gleam/time/timestamp
import lustre
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import shared/model.{type Activity, Activity}
import youid/uuid

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
  #(Int, List(Activity))

/// The `init` function gets called when we first start our app. It sets the
/// initial state of the app.
///
fn init(_) -> Model {
  #(0, [
    Activity(
      id: uuid.v7(),
      title: "Kayaking",
      description: "Paddling around",
      end_time: timestamp.parse_rfc3339("2026-01-01T08:00:01Z")
        |> result.unwrap(timestamp.from_unix_seconds(0)),
      start_time: timestamp.parse_rfc3339("2026-01-01T10:00:01Z")
        |> result.unwrap(timestamp.from_unix_seconds(0)),
      max_attendees: option.Some(2),
    ),
  ])
}

// UPDATE ----------------------------------------------------------------------

/// The `Msg` type describes all the ways the outside world can talk to our app.
/// That includes user input, network requests, and any other external events.
///
type Msg {
  UserClickedIncrement
  UserClickedDecrement
  ScoutClick
  ActivityTitleInput(String)
}

/// The `update` function is called every time we receive a message from the
/// outside world. We get the message and the current state of the app, and we
/// use those to calculate the new state.
///
fn update(model: Model, msg: Msg) -> Model {
  case msg {
    UserClickedIncrement -> #(model.0 + 1, model.1)
    UserClickedDecrement -> #(model.0 - 1, model.1)
    ScoutClick -> #(model.0 + 10, model.1)
    ActivityTitleInput(text) -> {
      let assert Ok(first) = list.first(model.1)
      #(model.0, [
        Activity(..first, title: text),
        ..list.rest(model.1)
        |> result.unwrap([])
      ])
    }
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

fn scout_input(label: String) {
  element.element("scout-field", [attribute.attribute("label", label)], [
    element.element("scout-input", [event.on_input(ActivityTitleInput)], []),
  ])
}

pub fn activities_list(activities: List(Activity)) {
  html.table(
    [],
    list.map(activities, fn(activity) {
      html.tr([], [
        html.td([], [element.text(activity.title)]),
        html.td([attribute.class("p-5")], [element.text(activity.description)]),
      ])
    }),
  )
}

fn activity_form() {
  html.form([attribute.class("bg-adventurerorange-300")], [
    scout_input("Title"),
    scout_input("Description"),
    html.label([attribute.for("date")], [html.text("Date")]),
    html.br([]),
    html.input([
      attribute.name("date"),
      attribute.id("date"),
      attribute.type_("date"),
    ]),
  ])
}

/// The `view` function is called after every `update`. It takes the current
/// state of our application and renders it as an `Element`
fn view(model: Model) -> Element(Msg) {
  let count = int.to_string(model.0)

  html.div([], [
    scout_button("hej", "primary", ScoutClick),
    html.p([attribute.class("bg-blue-300"), attribute.class("m-5")], [
      html.text("Counter: "),
      html.text(count),
    ]),
    scout_button("-", "primary", UserClickedDecrement),
    scout_button("+", "primary", UserClickedIncrement),
    activity_form(),
    activities_list(model.1),
  ])
}

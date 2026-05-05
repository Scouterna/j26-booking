# Lustre Framework Guide

Reference for building Lustre applications in Gleam. Based on the [official Lustre docs](https://lustre.build/).

## Architecture (Model-View-Update)

Lustre follows the Elm Architecture — a unidirectional data flow pattern:

```
                                       +--------+
                                       |        |
                                       | update |
                                       |        |
                                       +--------+
                                         ^    |
                                         |    |
                                     Msg |    | #(Model, Effect(Msg))
                                         |    |
                                         |    v
+------+                         +------------------------+
|      |  #(Model, Effect(Msg))  |                        |
| init |------------------------>|     Lustre Runtime     |
|      |                         |                        |
+------+                         +------------------------+
                                         ^    |
                                         |    |
                                     Msg |    | Model
                                         |    |
                                         |    v
                                       +--------+
                                       |        |
                                       |  view  |
                                       |        |
                                       +--------+
```

1. **Model** — the entire state of the application at a point in time.
2. **View** — a pure function of the model: if the model doesn't change, the UI doesn't change.
3. **Messages** — events from the outside world (user interaction, HTTP responses, etc.) sent to the update function.
4. **Update** — receives model + message, returns new model (and optional effects).
5. The runtime re-renders the view with the new model.

### Application Constructors

```gleam
// Static element — no state, no events
lustre.element(element)

// Simple app — state + events, no managed effects
lustre.simple(init, update, view)
// init:   fn(flags) -> model
// update: fn(model, msg) -> model
// view:   fn(model) -> Element(msg)

// Full app — state + events + managed effects
lustre.application(init, update, view)
// init:   fn(flags) -> #(model, Effect(msg))
// update: fn(model, msg) -> #(model, Effect(msg))
// view:   fn(model) -> Element(msg)

// Component — registered as a Custom Element
lustre.component(init, update, view, on_attribute_change)
```

### Starting an App

```gleam
pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}
```

## State Management

### The best model is not always a record

Use custom type variants to model distinct application states:

```gleam
type Model {
  LoggedIn(LoggedInModel)
  Public(PublicModel)
}
```

This makes impossible states impossible — you can write separate update/view functions per variant.

A type alias (`type Model = Dict(String, Post)`) is also fine when appropriate.

### Make invalid state unrepresentable

Three patterns to keep the model honest. Each removes a category of "this combination shouldn't be possible but the type allows it."

**Collapse loading/data/error triples.** Three independent fields representing one logical state machine let bogus combinations exist (`loading=True ∧ data=Some(...)`, `loading=False ∧ data=None ∧ error=None`, etc.).

```gleam
// Bad — three fields, many combinations, only some are valid
Model(loading: Bool, data: Option(a), error: Option(String))

// Good — one field, three variants, every value is valid
type RemoteData(a) {
  Loading
  Loaded(a)
  Failed(String)
}
```

**Push per-route state into the route variant.** Top-level fields that are only meaningful on some routes leak across navigations and force defensive `case` checks in views.

```gleam
// Bad — form lives at the top level even on routes that never use it
type Model {
  Model(route: Route, activities: List(Activity), form: Form(F), ...)
}

// Good — each route carries exactly the state it needs
type Page {
  ListPage(state: RemoteData(List(Activity)))
  NewPage(form: Form(F), submit_error: Option(String))
  DetailPage(id: String, state: RemoteData(Activity))
}
type Model {
  Model(page: Page, translator: Translator)
}
```

A useful consequence: API result handlers must pattern-match on `model.page`, which naturally drops stale responses if the user has navigated away while a fetch was in flight.

**Bind correlated fields in one constructor.** Fields that must agree (e.g. an entity and a form prefilled from it) belong in the same variant, not as siblings that can drift apart.

```gleam
// Bad — form and selected_activity can disagree
Model(selected_activity: Option(Activity), form: Form(F), ...)

// Good — both are populated together; one without the other is unrepresentable
type EditState {
  EditLoading
  EditReady(activity: Activity, form: Form(F), submit_error: Option(String))
  EditLoadFailed(String)
}
```

### Messages not actions

Name messages using **Subject Verb Object** to describe who sent them and what happened:

```gleam
// Good — clear origin and intent
type Msg {
  UserUpdatedPassword(String)
  UserRequestedPasswordReset
  BackendResetPassword(Result(Nil, String))
}

// Bad — action-style, unclear origin
type Msg {
  SetPassword(String)
  ResetPassword
  PasswordReset(Result(Nil, String))
}
```

Never recursively call your `update` function with different messages. Use plain functions to compose behavior.

### View functions not components

Prefer stateless view functions (`fn(...) -> Element(Msg)`) over stateful components. Components are for when you genuinely need encapsulated state + Custom Element features (shadow DOM, slots, attributes). View functions are easier to test, refactor, and reason about.

## Event Handling

### Common `lustre/event` helpers

| Function | Decodes | Use for |
|---|---|---|
| `event.on(name, decoder)` | Custom decoder on event object | Any event, especially custom ones |
| `event.on_click(msg)` | Nothing (fixed msg) | Standard click |
| `event.on_input(fn(String) -> msg)` | `event.target.value` as String | Text inputs, textareas, selects |
| `event.on_check(fn(Bool) -> msg)` | `event.target.checked` as Bool | Checkboxes |
| `event.on_submit(fn(FormData) -> msg)` | Form name/value pairs | Form submission (auto-prevents default) |
| `event.on_keydown(fn(String) -> msg)` | Key name as String | Keyboard handling |
| `event.prevent_default(attr)` | — | Wrap any event attr to cancel default |
| `event.stop_propagation(attr)` | — | Wrap any event attr to stop bubbling |

### Custom event decoders

Use `event.on` with `gleam/dynamic/decode` for custom events:

```gleam
event.on("scoutChange", {
  use value <- decode.subfield(["detail", "value"], decode.int)
  decode.success(TabChanged(value))
})
```

## Controlled vs Uncontrolled Inputs

### Controlled — model is single source of truth

```gleam
// View
html.input([
  attribute.value(model.name),
  event.on_input(UserUpdatedName),
])

// Update
UserUpdatedName(value) -> #(Model(..model, name: value), effect.none())
```

Use when: validating on every keystroke, formatting as user types, restricting input.

### Uncontrolled — browser manages state

```gleam
html.form([event.on_submit(UserSubmittedForm)], [
  html.input([
    attribute.type_("text"),
    attribute.name("username"),
  ]),
])
```

Use when: many form fields, only need values on submit, leveraging native validation, server components.

To clear an uncontrolled input: render it in a `keyed.div` or `keyed.fragment` and change the key.

## Side Effects

Effects tell the runtime what side effects to perform. Your `init`, `update`, and `view` functions must remain pure.

### Basics

```gleam
// No effect
effect.none()

// Run multiple effects at once
effect.batch([effect_a, effect_b])
```

### Custom effects with `effect.from`

```gleam
fn read(key: String, to_msg: fn(Result(String, Nil)) -> msg) -> Effect(msg) {
  effect.from(fn(dispatch) {
    do_read(key)
    |> to_msg
    |> dispatch
  })
}
```

Effects without dispatch (fire-and-forget):

```gleam
fn write(key: String, value: String) -> Effect(msg) {
  effect.from(fn(_) { do_write(key, value) })
}
```

Effects can dispatch multiple messages over time (timers, WebSockets, event listeners).

### DOM-timing effects

- `effect.before_paint` — runs after view but before browser paints
- `effect.after_paint` — runs after browser paints

Use these when you need to measure or manipulate DOM elements.

### Community packages

| Package | Purpose |
|---|---|
| [`rsvp`](https://hexdocs.pm/rsvp/) | HTTP requests |
| [`modem`](https://hexdocs.pm/modem/) | Navigation and routing |
| [`plinth`](https://hexdocs.pm/plinth/) | Node.js and browser platform API bindings |

## Rendering Lists

Use `element.keyed` (or `keyed.div`, `keyed.ul`, etc.) for lists to help Lustre accurately track which items changed, moved, or were removed:

```gleam
keyed.ul([], list.map(model.items, fn(item) {
  #(item.id, html.li([], [html.text(item.name)]))
}))
```

Without keys, reordering or prepending to lists can cause visual glitches (e.g. stale images appearing briefly).

## Attributes vs Properties

- **`attribute.attribute(name, value)`** — sets an HTML attribute (string only, visible in DOM, serialized for SSR)
- **`attribute.property(name, value)`** — sets a JS property directly (any JSON type, NOT serialized for SSR)

Use `attribute` for simple strings. Use `property` for arrays, objects, or booleans the element reads as JS properties. For SVG elements, always use attributes (properties are typically read-only).

## Pure Functions

Lustre assumes `init`, `update`, and `view` are **pure** — same input always produces same output, no side effects. Breaking this causes unexpected behavior. Use managed effects (`Effect` type) for anything that touches the outside world.

## Official Guides

| Guide | Topic |
|---|---|
| [01-quickstart](https://github.com/lustre-labs/lustre/blob/main/pages/guide/01-quickstart.md) | First Lustre app, cat API example |
| [02-state-management](https://github.com/lustre-labs/lustre/blob/main/pages/guide/02-state-management.md) | Model design, message naming, view functions vs components |
| [03-side-effects](https://github.com/lustre-labs/lustre/blob/main/pages/guide/03-side-effects.md) | Managed effects, custom effects, FFI, batching |
| [04-spa-deployments](https://github.com/lustre-labs/lustre/blob/main/pages/guide/04-spa-deployments.md) | Deploying a Lustre SPA |
| [05-server-side-rendering](https://github.com/lustre-labs/lustre/blob/main/pages/guide/05-server-side-rendering.md) | SSR with Lustre |
| [06-full-stack-applications](https://github.com/lustre-labs/lustre/blob/main/pages/guide/06-full-stack-applications.md) | Full-stack Gleam app (grocery list example) |
| [07-full-stack-deployments](https://github.com/lustre-labs/lustre/blob/main/pages/guide/07-full-stack-deployments.md) | Deploying full-stack apps |

### Hints

| Hint | Topic |
|---|---|
| [attributes-vs-properties](https://github.com/lustre-labs/lustre/blob/main/pages/hints/attributes-vs-properties.md) | When to use attribute vs property |
| [controlled-vs-uncontrolled-inputs](https://github.com/lustre-labs/lustre/blob/main/pages/hints/controlled-vs-uncontrolled-inputs.md) | Input handling strategies |
| [pure-functions](https://github.com/lustre-labs/lustre/blob/main/pages/hints/pure-functions.md) | Why purity matters in Lustre |
| [rendering-lists](https://github.com/lustre-labs/lustre/blob/main/pages/hints/rendering-lists.md) | Keyed elements for list rendering |

### Reference

| Page | Topic |
|---|---|
| [for-react-devs](https://github.com/lustre-labs/lustre/blob/main/pages/reference/for-react-devs.md) | Lustre concepts mapped from React |
| [for-elm-devs](https://github.com/lustre-labs/lustre/blob/main/pages/reference/for-elm-devs.md) | Lustre concepts mapped from Elm |
| [for-liveview-devs](https://github.com/lustre-labs/lustre/blob/main/pages/reference/for-liveview-devs.md) | Lustre concepts mapped from LiveView |

## Official Examples

### 01-basics

| Example | Description |
|---|---|
| [01-hello-world](https://github.com/lustre-labs/lustre/tree/main/examples/01-basics/01-hello-world) | Get something on the screen |
| [02-attributes](https://github.com/lustre-labs/lustre/tree/main/examples/01-basics/02-attributes) | Adding attributes to HTML elements |
| [03-view-functions](https://github.com/lustre-labs/lustre/tree/main/examples/01-basics/03-view-functions) | Organizing view code into functions |
| [04-keyed-elements](https://github.com/lustre-labs/lustre/tree/main/examples/01-basics/04-keyed-elements) | Keyed elements for optimized rendering |
| [05-fragments](https://github.com/lustre-labs/lustre/tree/main/examples/01-basics/05-fragments) | Grouping elements with fragments |
| [06-flags](https://github.com/lustre-labs/lustre/tree/main/examples/01-basics/06-flags) | Passing initialization data to an app |

### 02-inputs

| Example | Description |
|---|---|
| [01-controlled-inputs](https://github.com/lustre-labs/lustre/tree/main/examples/02-inputs/01-controlled-inputs) | Model-driven `<input>` handling |
| [02-decoding-events](https://github.com/lustre-labs/lustre/tree/main/examples/02-inputs/02-decoding-events) | Custom event handlers and decoders |
| [03-debouncing](https://github.com/lustre-labs/lustre/tree/main/examples/02-inputs/03-debouncing) | Debouncing user inputs |
| [04-forms](https://github.com/lustre-labs/lustre/tree/main/examples/02-inputs/04-forms) | Working with form submissions |

### 03-effects

| Example | Description |
|---|---|
| [01-http-requests](https://github.com/lustre-labs/lustre/tree/main/examples/03-effects/01-http-requests) | HTTP requests as side effects |
| [02-random](https://github.com/lustre-labs/lustre/tree/main/examples/03-effects/02-random) | Generating random values |
| [03-timers](https://github.com/lustre-labs/lustre/tree/main/examples/03-effects/03-timers) | Timers and intervals |
| [04-local-storage](https://github.com/lustre-labs/lustre/tree/main/examples/03-effects/04-local-storage) | Browser local storage |
| [05-dom-effects](https://github.com/lustre-labs/lustre/tree/main/examples/03-effects/05-dom-effects) | Direct DOM manipulation |
| [06-optimistic-requests](https://github.com/lustre-labs/lustre/tree/main/examples/03-effects/06-optimistic-requests) | Optimistic UI updates |

### 04-applications

| Example | Description |
|---|---|
| [01-routing](https://github.com/lustre-labs/lustre/tree/main/examples/04-applications/01-routing) | Routing and navigation between pages |
| [04-hydration](https://github.com/lustre-labs/lustre/tree/main/examples/04-applications/04-hydration) | Client-side hydration of server-rendered apps |

### 05-components

| Example | Description |
|---|---|
| [01-basic-setup](https://github.com/lustre-labs/lustre/tree/main/examples/05-components/01-basic-setup) | Web components with Lustre |
| [02-attributes-and-events](https://github.com/lustre-labs/lustre/tree/main/examples/05-components/02-attributes-and-events) | Attributes and events in components |
| [03-slots](https://github.com/lustre-labs/lustre/tree/main/examples/05-components/03-slots) | Slots in web components |

### 06-server-components

| Example | Description |
|---|---|
| [01-basic-setup](https://github.com/lustre-labs/lustre/tree/main/examples/06-server-components/01-basic-setup) | Server components introduction |
| [02-attributes-and-events](https://github.com/lustre-labs/lustre/tree/main/examples/06-server-components/02-attributes-and-events) | Attributes and events in server components |
| [03-event-include](https://github.com/lustre-labs/lustre/tree/main/examples/06-server-components/03-event-include) | Including events in server components |
| [04-multiple-clients](https://github.com/lustre-labs/lustre/tree/main/examples/06-server-components/04-multiple-clients) | Multiple clients sharing a server component |
| [05-publish-subscribe](https://github.com/lustre-labs/lustre/tree/main/examples/06-server-components/05-publish-subscribe) | Pub/sub between server components |

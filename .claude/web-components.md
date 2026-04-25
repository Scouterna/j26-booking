# Scouterna Web Components in Lustre

Guide for using `@scouterna/ui-webc` web components in the Lustre client.

See also: [Lustre guide](lustre-guide.md) for general Lustre patterns (MVU, events, effects, state management).

**Working example:** [`examples/client/`](../examples/client/) — standalone Lustre app demonstrating all patterns below.
**Storybook docs:** https://scouterna.github.io/j26-components/?path=/docs/home--docs

## Connecting Scout Events to Lustre Msg

Every event listener must produce a value of your `Msg` type. Three patterns:

**1. Fixed message** — when you don't need the event payload:
```gleam
event.on("scoutClick", decode.success(AddClicked))
```

**2. Standard input event** — scout-input fires native `input` event:
```gleam
event.on_input(fn(value) { TitleChanged(value) })
```

**3. Custom decoder** — for component-specific events with detail payload:
```gleam
event.on("scoutChange", {
  use value <- decode.subfield(["detail", "value"], decode.int)
  decode.success(TabChanged(value))
})
```

## Wrapping Web Components

Use `element.element` from `lustre/element` to create any custom element by tag name:

```gleam
import lustre/element
import lustre/attribute
import lustre/event
import gleam/dynamic/decode
import gleam/json

// Basic wrapper — string attributes, custom event, slot children
fn scout_button(text: String, variant: String, msg: Msg) -> element.Element(Msg) {
  element.element("scout-button", [
    attribute.attribute("variant", variant),
    event.on("scoutClick", decode.success(msg)),
  ], [element.text(text)])
}

// Nested components — scout-field wrapping scout-input
fn scout_input(label: String) -> element.Element(Msg) {
  element.element("scout-field", [attribute.attribute("label", label)], [
    element.element("scout-input", [event.on_input(HandleInput)], []),
  ])
}
```

### Key Patterns

| Pattern | How | When |
|---|---|---|
| String attribute | `attribute.attribute("name", value)` | Simple string props like `variant`, `label` |
| Boolean attribute | `attribute.attribute("disabled", "")` | Presence-based booleans |
| Rich property | `attribute.property("items", json.array(...))` | Arrays, objects, booleans via JS property |
| Custom event | `event.on("scoutClick", decode.success(msg))` | Component-specific events |
| Standard input event | `event.on_input(MsgConstructor)` | `scout-input` fires native `input` event |
| Slot content | Pass children as 3rd arg to `element.element` | Default slot composition |
| Conditional attr | `attribute.none()` | Skip an attribute based on a condition |
| Wrapper function | One function per component | Keep view code clean and typed |

### Attributes vs Properties

- **`attribute.attribute`** — sets HTML attribute (string only, visible in DOM, works with SSR)
- **`attribute.property`** — sets JS property directly (supports any JSON type, does NOT serialize for SSR)

Use `attribute` for simple strings. Use `property` for arrays, objects, or booleans that the component reads as JS properties.

## Component Catalog

All components use the `scout-` prefix. Events prefixed with `_scout` are internal and should be ignored.

### Layout

| Tag | Props | Slots | Events |
|---|---|---|---|
| `scout-card` | — | default | — |
| `scout-divider` | — | — | — |

### Navigation

| Tag | Props | Slots | Events |
|---|---|---|---|
| `scout-app-bar` | `title-text` | `prefix`, `suffix` | — |
| `scout-bottom-bar` | — | default (`scout-bottom-bar-item`) | — |
| `scout-bottom-bar-item` | `icon`\*, `label`\*, `type`, `active`, `href`, `target` | — | `scoutClick` |
| `scout-tabs` | `value` (active tab index) | default (`scout-tabs-tab`) | `scoutChange` (`{value: number}`) |
| `scout-tabs-tab` | — | default (tab label) | — |

### Buttons & Links

| Tag | Props | Slots | Events |
|---|---|---|---|
| `scout-button` | `variant` (`primary`/`outlined`/`text`/`caution`/`danger`), `size`, `type`, `icon`, `icon-position`, `icon-only`, `href` | default (label) | `scoutClick` |
| `scout-link` | `type` (`link`/`button`), `label`, `href`, `target`, `link-aria-label` | — | `scoutLinkClick` |

### Form Controls

Wrap form controls in `scout-field` for label + validation display.

| Tag | Props | Slots | Events |
|---|---|---|---|
| `scout-field` | `label`\*, `help-text` | default (form control) | — |
| `scout-input` | `type`, `inputmode`, `size`, `variant`, `value`, `name`, `disabled`, `placeholder`, `pattern`, `validity` | — | `scoutInputChange`, `scoutBlur`, `scoutValidate` |
| `scout-select` | `value`, `name`, `disabled`, `validity` | default (`<option>`) | `scoutInputChange`, `scoutBlur`, `scoutValidate` |
| `scout-checkbox` | `checked`, `disabled`, `label`, `name`, `value`, `validity` | — | `scoutChecked`, `scoutInputChange`, `scoutBlur` |
| `scout-radio-button` | `checked`, `disabled`, `label`, `name`, `value`, `validity` | — | `scoutChecked`, `scoutInputChange`, `scoutBlur` |
| `scout-switch` | `toggled`, `disabled`, `label`, `validity` | — | `scoutChecked`, `scoutInputChange`, `scoutBlur` |

### List

| Tag | Props | Slots | Events |
|---|---|---|---|
| `scout-list-view` | — | default | — |
| `scout-list-view-item` | `type` (`button`/`link`/`radio`/`checkbox`), `primary`, `secondary`, `icon`, `action`, `href`, `name`, `value`, `checked`, `disabled` | — | `scoutClick` |
| `scout-list-view-subheader` | `text`, `heading-level` | — | — |

### Feedback

| Tag | Props | Slots | Events |
|---|---|---|---|
| `scout-loader` | `size` (`xs`/`sm`/`base`/`lg`/`xl`), `text` | — | — |

\* = required

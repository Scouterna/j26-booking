---
name: web-components
description: Patterns for using @scouterna/ui-webc web components in the Lustre client and examples/client. Covers wrapping custom elements with element.element, decoding scout* CustomEvents (scoutClick, scoutChange, scoutInputChange, scoutChecked, scoutBlur, scoutValidate, scoutDismiss, scoutLinkClick, scoutPaginationClick, scoutSwipeProgress), attributes vs properties for rich JSON data, slot composition, and the full component catalog (scout-app-bar, scout-avatar, scout-bottom-bar, scout-bottom-bar-item, scout-button, scout-callout, scout-card, scout-checkbox, scout-divider, scout-drawer, scout-field, scout-input, scout-link, scout-list-view, scout-list-view-item, scout-list-view-subheader, scout-loader, scout-pagination, scout-radio-button, scout-segmented-control, scout-select, scout-skeleton, scout-stack, scout-switch, scout-tabbed-view, scout-tabbed-view-panel, scout-tabs, scout-tabs-tab). Use this whenever the client touches scout-* tags, @scouterna/ui-webc components, or anything in examples/client.
---

# Scouterna Web Components in Lustre

Guide for using `@scouterna/ui-webc` web components in the Lustre client.

**Working example:** [`examples/client/`](../../../examples/client/) — standalone Lustre app demonstrating all patterns below.
**Storybook docs:** https://scouterna.github.io/j26-components/?path=/docs/home--docs

## Connecting Scout Events to Lustre Msg

Every event listener must produce a value of your `Msg` type. Three patterns:

**1. Fixed message** — when you don't need the event payload:
```gleam
event.on("scoutClick", decode.success(AddClicked))
```

**2. Standard input event** — `scout-input` fires native `input` events too, so `event.on_input` works:
```gleam
event.on_input(fn(value) { TitleChanged(value) })
```

**3. Custom decoder** — for component-specific events with a `detail` payload:
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
    element.element("scout-input", [
      attribute.attribute("name", "title"),
      event.on_input(HandleInput),
    ], []),
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
| Standard input event | `event.on_input(MsgConstructor)` | `scout-input` re-fires native `input` |
| Slot content | Pass children as 3rd arg to `element.element` | Default slot composition |
| Conditional attr | `attribute.none()` | Skip an attribute based on a condition |
| Wrapper function | One function per component | Keep view code clean and typed |

### Attributes vs Properties

- **`attribute.attribute`** — sets HTML attribute (string only, visible in DOM, works with SSR)
- **`attribute.property`** — sets JS property directly (any JSON type, does NOT serialize for SSR)

Use `attribute` for simple strings. Use `property` for arrays, objects, or booleans the component reads as JS properties.

## Component Catalog

All components use the `scout-` prefix. Required props are marked `*`. Events prefixed with `_scout` (e.g. `_scoutFieldId`, `_scoutInvalid`, `_scoutValidityChanged`) are internal — ignore them.

### Layout

| Tag | Props | Slots | Events |
|---|---|---|---|
| `scout-card` | — | default | — |
| `scout-divider` | — | — | — |
| `scout-stack` | `direction` (`row`/`column`, default `row`), `gap-size` (`xs`/`s`/`m`/`l`/`xl`/`xxl`, default `m`) | default | — |

### Navigation

| Tag | Props | Slots | Events |
|---|---|---|---|
| `scout-app-bar` | `title-text` | `prefix`, `suffix`, default | — |
| `scout-bottom-bar` | — | default (`scout-bottom-bar-item`) | — |
| `scout-bottom-bar-item` | `icon`\*, `label`\*, `type` (`button`/`link`, default `button`), `active`, `href`, `target`, `rel` | — | `scoutClick` |
| `scout-drawer` | `open`, `heading`, `show-back-button`, `back-button-label`, `show-exit-button`, `exit-button-label`, `disable-backdrop`, `disable-content-padding` | default | `backButtonClicked`, `exitButtonClicked` |
| `scout-tabs` | `value` (active tab index), `swipe-value` (fractional index for swipe interpolation) | default (`scout-tabs-tab`) | `scoutChange` (`{value: number}`) |
| `scout-tabs-tab` | — | default (tab label) | — |
| `scout-tabbed-view` | `value` (active panel index), `tabs-id` (id of associated `scout-tabs`; auto-detects preceding sibling if omitted) | default (`scout-tabbed-view-panel`) | `scoutChange` (`{value: number}`), `scoutSwipeProgress` (`{swipeValue: number}`) |
| `scout-tabbed-view-panel` | — | default | — |
| `scout-pagination` | `pages`\*, `selected-index`, `max-amount-of-pages-showing` (default `5`), `pagination-aria-label` | — | `scoutPaginationClick` (`{selectedIndex: number}`) |

### Buttons & Links

| Tag | Props | Slots | Events |
|---|---|---|---|
| `scout-button` | `variant` (`primary`/`outlined`/`text`/`caution`/`danger`, default `outlined`), `size` (`medium`/`large`, default `medium`), `type` (`button`/`submit`/`reset`/`link`, default `button`), `disabled`, `icon`, `icon-position` (`before`/`after`, default `after`), `icon-only`, `href`, `target`, `rel` | default (label) | `scoutClick` |
| `scout-link` | `label`\*, `type` (`link`/`button`, default `link`), `href`, `target` (`_blank`/`_self`/`_parent`/`_top`/`framename`, default `_self`), `rel`, `link-aria-label` | — | `scoutLinkClick` (only when `type="button"`) |
| `scout-segmented-control` | `value` (zero-based index), `size` (`small`/`medium`, default `medium`) | default (button elements as segments) | `scoutChange` (`{value: number}`) |

### Form Controls

Wrap form controls in `scout-field` for label + validation display.

| Tag | Props | Slots | Events |
|---|---|---|---|
| `scout-field` | `label`\*, `help-text` | default (form control) | — |
| `scout-input` | `name`\*, `type` (`text`/`email`/`number`/`password`/`tel`/`url`, default `text`), `inputmode`, `size` (`medium`/`large`, default `medium`), `value`, `disabled`, `clearable`, `icon` (raw SVG string), `placeholder`, `pattern`, `validity` | — | `scoutInputChange` (`{value, element}`), `scoutBlur`, `scoutValidate` |
| `scout-select` | `name`\*, `value`, `disabled`, `validity` | default (`<option>` elements) | `scoutInputChange`, `scoutBlur`, `scoutValidate` |
| `scout-checkbox` | `checked`, `disabled`, `label`, `name`, `value`, `validity`, `aria-labelledby` | — | `scoutChecked` (`{checked, element}`), `scoutInputChange`, `scoutBlur`, `scoutValidate` |
| `scout-radio-button` | `checked`, `disabled`, `label`, `name`, `value`, `validity`, `aria-labelledby` | — | `scoutChecked`, `scoutInputChange`, `scoutBlur`, `scoutValidate` |
| `scout-switch` | `toggled`, `disabled`, `label`, `validity`, `aria-labelledby` | — | `scoutChecked`, `scoutInputChange`, `scoutBlur`, `scoutValidate` |

The native `input` event also fires on `scout-input`, so `event.on_input(Msg)` works for simple text capture without subscribing to `scoutInputChange`.

### List

| Tag | Props | Slots | Events |
|---|---|---|---|
| `scout-list-view` | — | default | — |
| `scout-list-view-item` | `type` (`button`/`link`/`radio`/`checkbox`, default `button`), `primary`, `secondary`, `icon`, `action` (`chevron`), `href`, `target`, `rel`, `name`, `value`, `checked`, `disabled` | — | `scoutClick` |
| `scout-list-view-subheader` | `text`\*, `heading-level` (`h1`–`h6`, default `h2`) | — | — |

### Feedback

| Tag | Props | Slots | Events |
|---|---|---|---|
| `scout-callout` | `variant` (`info`/`success`/`warning`/`error`/`tip`/`announcement`, default `info`), `heading`, `dismissible` | default, `actions` (for `scout-button`s) | `scoutDismiss` |
| `scout-loader` | `size` (`xs`/`sm`/`base`/`lg`/`xl`, default `base`), `text` | — | — |
| `scout-skeleton` | `disabled`, `background-color` | — | — |

### Identity

| Tag | Props | Slots | Events |
|---|---|---|---|
| `scout-avatar` | `image-src`, `alt` | — | — |

\* = required

## Related Skills

- See **lustre-guide** for general Lustre patterns (MVU, events, effects, state management).

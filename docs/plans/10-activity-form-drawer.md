# 10. Activity add/edit form in a drawer (consistent with booking)

> **Status: ✅ Done 2026-07-17** — Implemented as designed: `ActivityFormState`
> overlay on the `Model`, rendered in a single `scout-drawer` over the manage
> list (`view_activity_form_drawer`); `/activities/new` and `/:id/edit` routes
> removed; manage cards intercept the click (with `stop_propagation` so modem
> doesn't SPA-navigate) to open the drawer; call-off is a content swap
> (`view_call_off_confirm`), never a nested drawer. Verified end-to-end in the
> real app (Playwright): open/edit/create/cancel/exit all keep the list mounted
> on `/manage`, the call-off swap stays a single drawer, and a save round-trips
> (`200 PUT`) → drawer closes → list refreshes. 85 client tests pass.
>
> **Nested-drawer gotcha spiked 2026-07-17** (standalone harness loading the
> patched `scout-drawer`, driven with Playwright at 390×780). Naive nesting is
> confirmed broken on two counts; **resolved design: swap the single drawer's
> content for call-off — do not nest a second drawer.** See "Spike findings"
> below.

## Context

The activity **add** and **edit** forms are currently route-driven full pages,
while the **booking** form is a `scout-drawer` overlay. This is inconsistent and
has a concrete UX cost: opening add/edit navigates away from the manage list, so
the list's scroll position (and any in-memory filter/tab state on screen) is lost
on both open and cancel/save.

This plan converts add/edit to a drawer overlaid on the manage list, mirroring the
booking form, so the underlying list stays mounted and scroll is preserved.

### How it works today

**Add/edit — routed pages:**
- `ActivityNewPage` / `ActivityEditPage` are `Page` variants
  (`client.gleam:550`, `:559`).
- Opened by navigation: `UserClickedNewActivity` → `modem.push(.../activities/new)`
  (`:1611`); the manage-list edit action pushes `/activities/:id/edit`
  (`view_activity_summary` link, `:2944`). `uri_to_page` maps these to the page
  variants (`:2395`, `:2444`).
- Edit fetches fresh on route change: `ActivityEditPage(id, EditLoading)` +
  `fetch_activity(id)` (`:2448`); `ApiReturnedActivity` seeds `EditReady`
  (`:1325`).
- `view` renders `view_activity_form` as the whole page (`:2469`, `:2504`).
- Save/cancel `modem.push` back to `/activities/manage` (`:1426`, `:1462`,
  `:1622`).
- `EditUi` (language toggle + call-off modal state) lives on the `Model`
  (`:462`), reset when the form opens.

**Booking — drawer overlay (the template to copy):**
- `BookingFormState` (`:382`) is a field on `ActivityDetailPage(id, booking)`
  (`:558`), *not* a route.
- `view_activity_detail_loaded` renders `component.scout_drawer` (`:3316`) whose
  `open` is derived from the `BookingFormState` variant; the underlying detail
  content stays mounted below it, preserving scroll.
- Open/close/submit are plain messages that mutate the overlay state — the route
  never changes.

## Goal

Add/edit opens as a `scout-drawer` over the manage list. The list stays mounted
(scroll preserved). Behaviour otherwise unchanged: bilingual language toggle,
tag/target-group pickers, validation, save/cancel, and (edit-only) call-off.

## Approach

Model the form as **overlay state on the manage list**, exactly like
`BookingFormState` on the detail page.

### 1. State model

Introduce an activity-form overlay state and hang it off the list page (or the
`Model`, scoped to the manage list). Reuse the existing `EditState` /
`Form(ActivityForm)` / `EditUi` machinery — only the *container* changes.

```gleam
pub type ActivityFormState {
  ActivityFormClosed
  ActivityFormNew(
    form: Form(ActivityForm),
    submit_error: Option(AppError),
    tags: List(Uuid),
    target_groups: List(TargetGroup),
  )
  ActivityFormEdit(id: Uuid, state: EditState)  // reuses EditLoading / EditReady
}
```

Preferred placement: a field on `ActivitiesListPage` (so it's only meaningful in
the manage view), e.g. `ActivitiesListPage(filters, mode, form: ActivityFormState)`.
Alternatively a `Model` field if that reads cleaner against the existing update
arms — decide during implementation, keeping `BookingFormState`-on-page as the
precedent.

`EditUi` stays on the `Model` as-is.

### 2. Open on click, not on route

- `UserClickedNewActivity`: set overlay to `ActivityFormNew(activity_form(), …)`
  and reset `edit_ui` — **drop** the `modem.push(.../new)` (`:1611`).
- Manage-list edit action: replace the `/activities/:id/edit` link with a message
  (e.g. `UserClickedEditActivity(id)`) that sets the overlay to
  `ActivityFormEdit(id, EditLoading)` and fires `fetch_activity(id)`.
- `ApiReturnedActivity`: when the overlay is `ActivityFormEdit(id, EditLoading)`
  for the returned id, seed `EditReady` into the overlay (adapt the existing
  `:1325` arm, which currently targets the page variant).

### 3. View

- Render the drawer at the manage-list level: `open` derived from the overlay
  variant (`ActivityFormClosed` → closed), `on_exit` → a cancel message. Put
  `view_activity_form`'s body inside the drawer content. `EditLoading` shows the
  loader inside the drawer.
- `view_activity_form` is largely reusable; it currently returns a
  `flex flex-col` wrapper (`:3073`) — move that into the drawer's content list.

### 4. Save / cancel

- Success (`UserSubmittedCreateForm` / `EditForm` reply) and cancel
  (`UserClickedCancelEdit`): set overlay to `ActivityFormClosed` and refresh the
  list in place — **drop** the three `modem.push(.../manage)` navigations
  (`:1426`, `:1462`, `:1622`). No route change.

### 5. Routing cleanup

- Remove the `["activities", "new"]` and `["activities", id, "edit"]` arms from
  `uri_to_page` (`:2395`, `:2444`), matching booking (which has no route). If
  deep-linkable edit is wanted later, these arms can instead open the drawer over
  the list — but the default here is to drop them for consistency.

## Gotchas (the non-mechanical parts)

1. **Nested drawer — RESOLVED by spike (do not nest).** The call-off
   confirmation is *already* a `scout_drawer` inside the edit form
   (`view_call_off_drawer`, `:3195`, invoked at `:3078`). Wrapping the whole form
   in a drawer would nest `scout-drawer` inside `scout-drawer` — and the spike
   (below) proves that breaks. **Design decision: render call-off by swapping the
   single activity drawer's *content* (driven by the existing
   `edit_ui.cancel_open` flag) — no second drawer.** When `cancel_open` is true,
   the drawer body shows the reason input + confirm/cancel instead of (or above)
   the form fields; the drawer's own exit/backdrop still closes the whole form.
   Delete `view_call_off_drawer`'s wrapping `scout_drawer` and inline its body.
2. **Long form inside a drawer.** The activity form (bilingual fields + pickers +
   actions) is taller than the booking form. Confirm it scrolls cleanly inside
   `scout-drawer` on mobile widths.
3. **Loss of deep-linkable edit / back-to-close.** Dropping the routes means the
   browser back button no longer closes the form and `/activities/:id/edit` is no
   longer a URL. This matches booking's behaviour and is the intended trade-off,
   but note it explicitly — the shell↔iframe navigation work (plan 07) assumes
   route changes mirror to the shell, and this removes two such routes.

## Spike findings (2026-07-17)

Method: a standalone HTML harness rendered a real `scout-drawer` (the patched
build in `server/priv/static/ui-webc-patched/`) with a second `scout-drawer`
nested in its slotted content — the exact shape a naive refactor would produce.
Exit events were wired the same way `component.scout_drawer` wires them
(`event.on("exitButtonClicked", …)` on each host). Driven with Playwright at a
390×780 mobile viewport; geometry read from each drawer's shadow-DOM
`.drawer--container` / `.backdrop`.

The component (`collection/components/drawer/drawer.js` + `drawer.css`) does **not**
use the top layer (`<dialog>`/`popover`). It renders `position: fixed` backdrop
(`z-index:100`) and container (`z-index:101`) in shadow DOM, animates the
container with `transform`, and clips it with `overflow: hidden`; focus is held
by `dom-focus-lock`.

Two confirmed failures when nesting:

1. **Exit event collision (severe).** `exitButtonClicked` is
   `bubbles:true, composed:true` (drawer.js `:301-316`). Clicking the inner
   drawer's X (or its backdrop — same emit path) fired **both** handlers: the
   event bubbled out of the inner host to the outer `scout-drawer` and closed it
   too. In-app that means dismissing the call-off confirmation would close the
   entire edit form and discard unsaved edits. Observed log:
   `INNER exitButtonClicked → OUTER exitButtonClicked`, both `open` went false.
2. **Containing block + clipping (visual).** The outer container's open-state
   `transform` makes it the containing block for the inner drawer's
   `position: fixed`. Measured: outer container `y78 h702` (correct — 90% of the
   702… of viewport), inner container `y148 h632` and inner backdrop `y78 h702` —
   i.e. the inner drawer sizes to **90% of the outer drawer box**, not the
   viewport, and its backdrop dims only the outer drawer. With the outer's
   `overflow: hidden` it's also clipped to that box. Result: a cramped
   drawer-in-a-drawer, not a full-screen sheet.

Mitigations checked:

- `stopPropagation` on the inner `exitButtonClicked` **fixes failure 1** (outer
  stayed open in the harness; Lustre can express this via the `event`
  stop-propagation modifier). But it does **nothing** for failure 2 — the
  geometry is still wrong. So "keep nesting + stop propagation" is rejected.
- **Content-swap in a single drawer** sidesteps both: there is only ever one
  drawer, which the single-drawer case already renders correctly (full-width,
  full-viewport backdrop, focus lock intact). This is the chosen design (gotcha 1
  above). It also removes the focus-lock stacking question entirely (with both
  nested drawers open the harness left `activeElement` on `<body>`, i.e. the
  nested lock did not behave — another reason not to nest).

## Files

- `client/src/client.gleam` — state type, update arms (open/seed/save/cancel),
  `uri_to_page` cleanup, manage-list edit trigger, drawer in `view`.
- `client/src/component.gleam` — `scout_drawer` is ready; no change expected.
- `client/test/client_test.gleam` — update any tests asserting the old routes /
  page variants.

## Estimate

~Half a day. State/wiring changes are mechanical with `BookingFormState` as a
reference; the nested call-off drawer (gotcha 1) is the one part that may need a
small design decision and should be spiked first.

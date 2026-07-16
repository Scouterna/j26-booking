# 10. Activity add/edit form in a drawer (consistent with booking)

> **Status: 🔲 Not started** (as of 2026-07-15)

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

1. **Nested drawer — the real risk.** The call-off confirmation is *already* a
   `scout_drawer` rendered inside the edit form (`view_call_off_drawer`, `:3195`,
   invoked at `:3078`). Wrapping the whole form in a drawer nests
   `scout-drawer` inside `scout-drawer`. Verify `@scouterna/ui-webc` supports
   nested drawers; if not, rework call-off — e.g. swap the drawer's contents to a
   confirmation view, or use an inline confirmation block instead of a second
   drawer. **Validate this before committing to the full refactor.**
2. **Long form inside a drawer.** The activity form (bilingual fields + pickers +
   actions) is taller than the booking form. Confirm it scrolls cleanly inside
   `scout-drawer` on mobile widths.
3. **Loss of deep-linkable edit / back-to-close.** Dropping the routes means the
   browser back button no longer closes the form and `/activities/:id/edit` is no
   longer a URL. This matches booking's behaviour and is the intended trade-off,
   but note it explicitly — the shell↔iframe navigation work (plan 07) assumes
   route changes mirror to the shell, and this removes two such routes.

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

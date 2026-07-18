# 15. Create a booking for someone else (issue #27)

> **Status: ✅ Done 2026-07-19** (commit `81ba2b4`; shipped as planned — see
> the implementation notes below for the two divergences)

## Implementation notes (divergences from the plan)

- **Uncapped activities:** clicking "Boka" on an activity without
  `max_attendees` normally books instantly with empty fields (no drawer). For
  holders of `bookings:others:create` that would have made book-for-other
  impossible there, so those users now get the form drawer on uncapped
  activities too; everyone else keeps the instant-book flow.
- Added a `LoadScoutGroupsFailed` app error (kår-list fetch failure shown
  inside the picker), not in the plan's error list.
- Known limitation (pre-existing, out of scope): the client's status model
  tracks at most one booking per user per activity, and "Boka" is a no-op once
  booked — so info-tent staff can't book the *same* slot for a second kår from
  the UI without unbooking first. The API supports it (no unique constraint);
  lifting the client limitation is follow-up work — see plan 16
  (`16-multiple-bookings-and-manage-bookings-page.md`).

## Context

Staff in the info tent ("infotältet") need to create bookings on behalf of other
kårer. Today `POST /api/activities/:id/bookings` always books for the caller's
own token group (`server/src/server/web/booking.gleam:56`, guarded by
`bookings:self:create`), and there is already a
`TODO(bookings-others)` there anticipating this work. The `bookings:others:create`
role and `web.BookingsOthersCreate` variant already exist but are unused.

### Desired behaviour (from the issue)

- Only holders of `bookings:others:create` (or `admin`) may book for others.
- In the booking form drawer, such users see a segmented control at the top:
  **"Åt dig själv"** / **"Åt någon annan"**.
- "Åt någon annan" reveals a searchable kår picker (the same combobox pattern the
  activity edit form uses for locations — the kår list is ~621 entries).
- The created booking records:
  - `user_id` + `booker_name` = **the person doing the booking** (unchanged, from
    the token),
  - `booker_group_id` / `booker_group_name` = **the selected kår**,
  - a new boolean column flagging that it was booked on behalf of someone else.
- All other fields (`group_free_text`, `responsible_name`, `phone_number`,
  `participant_count`) behave exactly as today.
- Editing a booking keeps today's behaviour — the segmented control only appears
  for **new** bookings.

### Where the kår list lives

`server/src/server/scout_group.gleam` currently maps a kårnummer → name via one
big `case` expression (`group_id_to_name`, with a `"Kår <id>"` fallback). It is a
generated snapshot of the registration export. The client picker needs the full
list, so this plan turns that data into a single source of truth and serves it
from a new endpoint.

## Design decisions

- **New column:** `booking.booked_for_other BOOLEAN NOT NULL DEFAULT FALSE`. The
  permanent `DEFAULT FALSE` means self-bookings and the without-group insert never
  have to mention it, and existing rows backfill to `false`.
- **Request shape:** `BookingInput` gains an optional `booker_group_id`.
  `Some(id)` ⇒ book-for-other with that kår (sets `booked_for_other = true`);
  absent ⇒ book-for-self (today's behaviour, `booked_for_other = false`). No
  separate mode flag on the wire — presence of `booker_group_id` *is* the mode.
- **Authorization:** the create handler picks the required role from the mode:
  book-for-other requires `BookingsOthersCreate`, book-for-self requires
  `BookingsSelfCreate` (`Admin` implies both). This replaces the current
  unconditional `require_role(BookingsSelfCreate)`.
- **`scout_group.gleam` single source of truth:** convert the `case` data into a
  module-level `const groups: List(model.ScoutGroup)` (evaluated once, no
  per-call allocation) and reimplement `group_id_to_name` as a `list.find` over
  it with the same `"Kår <id>"` fallback. These call sites are all low-frequency
  (per booking / per `/me` / per overview row), so a 621-element linear scan is
  negligible.
- **New endpoint:** `GET /api/scout-groups` → `{"scout_groups": [{id,name}, …]}`,
  gated by `require_role(BookingsOthersCreate)` (the only users who need it), with
  an ETag (`SharedAcrossUsers`, identical for every caller) so the big payload is
  a cheap `304` on revalidation.
- **Client fetch timing:** fetch `/api/scout-groups` once, when `/api/me` returns
  and the user holds the role. Store as `RemoteData` on the model.
- **Client form state:** book-for-other UI state (target, selected kår, combobox
  query/open) lives in a new `BookingUi` record on the `Model` (mirroring how
  `EditUi` sits beside the multi-variant `EditState`), reset when the form opens.

## Changes

### 1. DB migration
- `cd server && gleam run -m cigogne new --name booking_booked_for_other` (never
  hand-create the file), then fill in:
  - up: `ALTER TABLE booking ADD COLUMN booked_for_other BOOLEAN NOT NULL DEFAULT FALSE;`
  - down: `ALTER TABLE booking DROP COLUMN booked_for_other;`
- Apply with `gleam run -m cigogne up`.

### 2. SQL + Squirrel (`server/src/server/sql/`)
- `create_booking_with_group.sql`: add `booked_for_other` to the column list, a
  new `$11` value, and to `RETURNING`. (Used for both book-for-other, `TRUE`, and
  self-with-token-group, `FALSE`.)
- `create_booking_without_group.sql`: no change — the column defaults to `FALSE`;
  the model hardcodes `booked_for_other: False` for this row (mirroring how it
  already hardcodes the `None` group).
- Add `booked_for_other` to the `SELECT`/`RETURNING` of `get_booking.sql`,
  `get_bookings_by_activity.sql`, `get_bookings_by_user.sql`,
  `update_booking.sql`.
- Regenerate: `cd server && gleam run -m squirrel`, then `gleam format`.

### 3. Shared model (`shared/src/shared/model.gleam`)
- `Booking` type (~363): add `booked_for_other: Bool`.
- `booking_decoder()` (~379): `use booked_for_other <- decode.optional_field("booked_for_other", False, decode.bool)`; add to both the success and failure `Booking(...)` literals.
- `to_json()` (~145 in model/booking on server; the shared one is the decoder
  side) — the shared type has no encoder; server `model/booking.to_json` encodes
  it (see §5).
- New `ScoutGroup` type for the picker list:
  - `pub type ScoutGroup { ScoutGroup(id: Int, name: String) }`
  - `scout_group_decoder()` (`id`: Int, `name`: String),
  - `scout_groups_decoder()` for `{"scout_groups": [...]}`,
  - `scout_group_to_json()` + `scout_groups_to_json()` (used by the server).

### 4. `server/src/server/scout_group.gleam`
- Replace the `case` with `pub const groups: List(model.ScoutGroup) = [ScoutGroup(1102, "Adolf Fredriks Scoutkår"), …]` (mechanically transform the existing 621 arms; keep the header comment, updated to note both the const and the lookup are generated from the export).
- `group_id_to_name(group_id)` = `list.find(groups, fn(g) { g.id == group_id })`
  → `.name`, falling back to `"Kår " <> int.to_string(group_id)`.
- `import shared/model` and `import gleam/list`.

### 5. Server booking model (`server/src/server/model/booking.gleam`)
- Every `from_*_row` sets `booked_for_other:` — from `row.booked_for_other` for
  `get_booking` / `get_bookings_by_activity` / `get_bookings_by_user` /
  `update_booking` / `create_booking_with_group`; hardcode `False` in
  `from_create_booking_without_group_row`.
- `to_json()` (~145): add `#("booked_for_other", json.bool(booked_for_other))`.

### 6. Server create handler (`server/src/server/web/booking.gleam`)
- `BookingInput` + `booking_input_decoder`: add
  `booker_group_id: Option(Int)` via `decode.optional_field("booker_group_id", None, decode.optional(decode.int))`.
- `create`: remove the unconditional `require_role(BookingsSelfCreate)` and the
  `TODO(bookings-others)`. After decoding input, branch on
  `input.booker_group_id`:
  - `Some(_)` → `use <- web.require_role(user, web.BookingsOthersCreate)`
  - `None` → `use <- web.require_role(user, web.BookingsSelfCreate)`
- `insert_booking`: add a `booker_group_id: Option(Int)` param (the request's).
  - `Some(group_id)` (book-for-other): `create_booking_with_group(... user.name,
    group_id, scout_group.group_id_to_name(group_id), … , booked_for_other: True)`.
  - `None` (self): today's `user.group_id` branch — `with_group` +
    `booked_for_other: False` when the token has a group, else `without_group`.

### 7. New scout-groups endpoint
- `server/src/server/web/account.gleam` (or a small new `scout_group` web
  handler — account is the closest fit): `get_scout_groups(req, ctx)`:
  - `require_method Get`, `with_authenticated_user`, `require_role(BookingsOthersCreate)`,
  - body = `model.scout_groups_to_json(scout_group.groups)`,
  - respond via `web.json_response_with_etag(req, body, 200, "private, no-cache", web.SharedAcrossUsers)`.
- `server/src/server/router.gleam`: `Get, ["scout-groups"] -> account.get_scout_groups(req, ctx)` and a `_, ["scout-groups"] -> wisp.method_not_allowed([Get])`.

### 8. Client (`client/src/client.gleam`)
- **Roles:** add `BookingsOthersCreate` to the client `Role` type (~836) and map
  `"bookings:others:create"` in `role_from_string`. Helper
  `can_book_others(model) -> Bool` (`has_role(model, BookingsOthersCreate)` — Admin
  already implied).
- **Model:** add `scout_groups: RemoteData(List(ScoutGroup))` (init `NotAsked`)
  and `booking_ui: BookingUi` (init default). New types:
  ```
  pub type BookingTarget { BookingForSelf  BookingForOther }
  pub type BookingUi {
    BookingUi(target: BookingTarget, group_id: Option(Int),
              group_query: String, group_open: Bool)
  }
  ```
  `default_booking_ui()` = `BookingForSelf, None, "", False`.
- **Fetch groups:** in `ApiReturnedMe(Ok(me))`, when the roles include
  others-create/admin and `scout_groups` is `NotAsked`, batch a `fetch_scout_groups()`
  effect (rsvp GET `/api/scout-groups`, `model.scout_groups_decoder()`,
  `ApiReturnedScoutGroups`). Add `ApiReturnedScoutGroups(Result(...))` handler.
- **Open form:** `UserClickedBook` resets `booking_ui: default_booking_ui()`.
- **New messages + handlers:** `UserSelectedBookingTarget(Int)`,
  `UserSelectedBookingGroup(Option(Int))`, `UserSearchedBookingGroup(String)`,
  `UserOpenedBookingGroupDropdown`, `UserClosedBookingGroupDropdown` — mirror the
  location-picker handlers (`client.gleam:2188`+). `UserSelectedBookingTarget`
  updates `booking_ui.target` (and clears query/open).
- **View (`view_booking_form_section`, ~4666):** thread in `can_book_others`,
  `booking_ui`, and `scout_groups`. For `BookingNew` and `can_book_others`:
  - render `component.scout_segmented_control` with
    `["Åt dig själv", "Åt någon annan"]` bound to `booking_ui.target`;
  - `BookingForSelf` → today's `view_booker_identity`;
  - `BookingForOther` → the booker's own **name** read-only (recorded as booker)
    + a kår combobox (new `view_scout_group_picker`, adapted from
    `view_location_picker` at ~3580, driven by `scout_groups`), plus a short note
    that the booking is recorded for the chosen kår.
  - `BookingEdit` → unchanged (no segmented control).
- **Submit:** thread the selection into the create effect.
  - `create_booking` gains a `booker_group_id: Option(Int)` param;
    `booking_form_to_json` includes `#("booker_group_id", json.int(id))` only when
    `Some`.
  - `UserSubmittedBookingForm(Ok(fields))`: for `BookingNew`, compute the group
    from `booking_ui` — `BookingForOther` with a selected kår → `Some(id)`;
    `BookingForSelf` → `None`. If `BookingForOther` with no kår selected, keep the
    form open and set `submit_error` to a new `AppError` (e.g.
    `BookingGroupRequired`, with an `error.booking_group_required` translation);
    do **not** send. `BookingEdit` unchanged.
- **Translations:** add sv/en strings for the segmented control labels
  (`booking.for_self`, `booking.for_other`), the picker
  (`booking.select_group`, `booking.group_search`), the on-behalf note
  (`booking.for_other_note`), and the validation error.

### 9. OpenAPI (`server/priv/static/openapi.yaml`)
- `Booking` schema: add `booked_for_other` (boolean) and update the examples.
- `BookingInput` schema: add optional `booker_group_id` (integer, nullable) with a
  description of the `bookings:others:create` semantics.
- Update the `POST /api/activities/:id/bookings` description to cover the
  book-for-other path and its role.
- Add `GET /api/scout-groups` (auth + `bookings:others:create`) and a
  `ScoutGroup` schema.

### 10. Tests
- `client/test/client_test.gleam:94`: the `model.Booking(...)` literal gains
  `booked_for_other: False` (compile fix).
- `server/test/server/model/booking_test.gleam`: overview rows are unaffected by
  the new column, but confirm it still compiles after squirrel regen; add a
  round-trip assertion for `booked_for_other` if a booking encode/decode test
  fits.
- Add a shared round-trip test for `ScoutGroup` decode (and `Booking` with
  `booked_for_other`) if there is a shared/client decoder test suite to extend.

## Verification

- `cd server && gleam test && gleam format`; `cd client && gleam format`.
- `./start.sh`, then as a `bookings:others:create` (or `admin`) dev user
  (`DEV_AUTH_ROLES=admin`): open an activity, confirm the segmented control shows,
  pick "Åt någon annan", search/select a kår, submit, and verify via
  `GET /api/bookings/:id` that `booker_name` is the caller, `booker_group_*` is the
  chosen kår, and `booked_for_other` is `true`.
- Confirm a self-booking still records the token group with `booked_for_other:false`,
  and that a user without the role never sees the control and is `403`ed if they
  post a `booker_group_id`.

# 16. Multiple bookings per person + manage-bookings interface (follow-up to #27)

> **Status: ✅ Done 2026-07-19** (commit `13834ee`; shipped as planned — see
> the implementation notes below for the divergences)

## Implementation notes (divergences from the plan)

- **For-other edit drawer identity:** editing an on-behalf booking from the
  bookings page shows the *booking's* kår + "Bokad av <booker>" read-only
  (new `view_edited_for_other_identity`) instead of the editor's own Scoutnet
  identity block, which would have wrongly implied the editor's kår gets
  stored.
- The shared update arms were unified behind `page_booking_form` /
  `set_page_booking_form` helpers (as the plan suggested), so the detail and
  bookings pages share one booking-drawer state machine.
- `group_by_activity` (server statuses) and `may_manage` (server booking) are
  `pub` so tests exercise them directly, following the `web.authenticate`
  precedent.

## Context

Plan 15 shipped book-for-other (issue #27): holders of `bookings:others:create`
can create a booking on behalf of a kår, recorded with `booked_for_other = true`.
It left one limitation on record: the client tracks **at most one booking per
user per activity** — `ActivityStatus.Booked(booking)` is a single value,
`/api/statuses/me` emits one entry per booking (duplicates collapse in the
client's `Dict`), and "Boka" is a no-op once `is_booked`. So info-tent staff
cannot book the *same* slot for a second kår without unbooking the first,
even though the API and schema already allow it (no unique constraint on
`(user_id, activity_id)`).

This plan lifts that limitation and gives `bookings:others:create` holders a
management variant of the per-activity **"Visa bokningar"** page where they see
**all bookings** for the activity and can **manage every for-other booking**
(`booked_for_other == true`) — including ones created by *other*
`bookings:others:create` holders (the info tent works as a team; any staffer
can correct any on-behalf booking). Self-bookings by other users stay
view-only.

### Current state (anchors)

- `shared/model.gleam` — `ActivityStatus.Booked(booking: Booking)` (single).
- `server/web/status.gleam` — `/api/statuses/me` emits one `booked` entry per
  booking row (`booked_entry`), so two bookings on one activity yield duplicate
  `activity_id` entries.
- `server/web/booking.gleam` — `update`/`delete` still carry
  `TODO(booking-ownership)`: any authenticated user may edit/delete any booking.
- `client.gleam`:
  - `UserClickedBook` short-circuits when `is_booked` (~2485).
  - Detail-page actions (`view_detail_actions`, ~4841): booked → "Ändra
    bokning"/"Avboka" driven by `booking_of(status)` (the single booking).
  - `ActivityBookingsPage(id, bookings)` (~767) is the read-only "Visa
    bokningar" page: header + `view_booking_card` list (~5655, no actions).
    The booking form drawer state (`BookingFormState`) lives only on
    `ActivityDetailPage`.
  - `can_view_bookings` = `BookingsRead || ManageActivities` — a user with
    *only* `bookings:others:create` can't even open the page today, and the
    server's `get_by_activity` would 403 them.

## Design decisions

- **Who may hold multiple bookings:** only the book-for-other flow needs it.
  A user keeps **at most one self-booking** per activity (client-enforced, as
  today), but may stack any number of for-other bookings on top. Regular users'
  UX is unchanged.
- **Status model becomes a list:** `Booked(bookings: List(Booking))` (non-empty
  by construction). The wire shape of `/api/statuses/me` changes to
  `{"status": "booked", "bookings": [...]}`, grouped per activity server-side.
  Client and server live in one repo and deploy together, so no back-compat
  variant is kept; the OpenAPI spec is updated in the same change.
- **Detail-page actions act on the self-booking only.** "Ändra bokning"/"Avboka"
  keep their current meaning but target the user's *self* booking
  (`booked_for_other == False`). For-other bookings are managed from the
  bookings page — that keeps the detail page unambiguous when several bookings
  exist.
- **"Boka" availability:** enabled when the user has no self-booking, OR when
  they hold `bookings:others:create` (they can always add a for-other booking,
  capacity permitting). If a self-booking already exists, the drawer locks the
  segmented control to "Åt någon annan" (prevents a duplicate self-booking
  client-side; the server keeps allowing it — deliberate, same as today).
- **Ownership on the API (closes `TODO(booking-ownership)`):** the rule for
  `PUT`/`DELETE /api/bookings/:id` follows the booking's flag:
  - `booked_for_other == true` → requires the `bookings:others:create` role —
    *any* holder may edit/unbook it, not just its creator (team-managed).
  - `booked_for_other == false` (a self-booking) → only its owner
    (`booking.user_id == user.id`).
  - `admin` overrides both.
- **Read access for the page:** `bookings:others:create` is added to the
  allowed roles of `GET /api/activities/:id/bookings` and `GET /api/bookings/:id`
  (they must see the full list to manage the for-other bookings within it).
  The recurring overviews stay `bookings:read`/`activities:manage`-gated.
- **Card editability needs no identity check:** a card is manageable exactly
  when `booking.booked_for_other && can_book_others(model)` — both already on
  the client, so `/api/me` needs no new fields. For-other cards show
  `booker_name` as a caption so staff can tell who created each entry.
- **The bookings page gets the booking drawer.** `ActivityBookingsPage` gains
  its own `BookingFormState` so edit/unbook reuse the existing state machine
  (`BookingOpen(_, _, BookingEdit(id))`, `UnbookConfirming`, …) without
  navigating away.

## Changes

### 1. Server — statuses grouped per activity (`server/src/server/web/status.gleam`)
- Group `bookings` by `activity_id` (`list.chunk` after the query's stable
  order, or fold into a dict) and emit one entry per activity:
  `#("bookings", json.array(bookings, booking.to_json))` instead of the single
  `"booking"`. Keep `booked` dominating `favourited` (unchanged: the
  `booked_ids` set logic already handles it).

### 2. Server — ownership + read access (`server/src/server/web/booking.gleam`)
- Shared authorization helper, e.g.
  `fn may_manage(user: web.User, booking: Booking) -> Bool`:
  `booking.booked_for_other && web.has_role(user, web.BookingsOthersCreate)`
  `|| booking.user_id == user.id || web.has_role(user, web.Admin)`
  (`has_role` already folds Admin in, so the explicit Admin arm is only for
  the self-booking case).
- `update`: after `load_booking`, roll back with a new `NotBookingManager`
  variant (mapped to 403) when `!may_manage(user, existing)`. The check runs
  inside the existing transaction — the booking is already loaded there.
- `delete`: same rule; load the booking first (`sql.get_booking`) so a
  booking the caller may not manage 403s rather than 404s, then delete.
- `get_by_activity` and `get_one`: extend the guard to
  `web.require_any_role(user, [web.BookingsRead, web.ActivitiesManage, web.BookingsOthersCreate])`.
- Remove both `TODO(booking-ownership)` comments.

### 3. Shared model (`shared/src/shared/model.gleam`)
- `ActivityStatus`: `Booked(bookings: List(Booking))`.
- `activity_status_entry_decoder`: decode `"bookings"` as
  `decode.list(booking_decoder())`; fail a `booked` entry with an empty list
  (keeps `Booked` non-empty by construction).

### 4. Client — model & helpers (`client/src/client.gleam`)
- Status helpers:
  - `booking_of` → `bookings_of(status) -> List(Booking)`.
  - New `self_booking_of(status) -> Option(Booking)` (first with
    `booked_for_other == False`) — drives the detail-page Ändra/Avboka and the
    "Boka" gating.
  - `is_booked` keeps meaning "has any booking" (hearts/Favourites unchanged).
- `cap_for_mode` (~1376): on `BookingEdit(id)`, find the edited booking by id
  in `bookings_of(status)`; also accept the booking directly from the bookings
  page (pass an `Option(Booking)` through, since the page has the full row).
- Status updates — note the edited/deleted booking may be *another user's*
  for-other booking, which is not in my statuses at all, so every arm must
  tolerate an id it doesn't hold:
  - `ApiCreatedBooking(Ok)`: append to the activity's `Booked` list (or create
    it) — a booking I create is always mine.
  - `ApiUpdatedBooking(Ok)`: replace by `booking.id` where present, else leave
    statuses untouched.
  - `ApiDeletedBooking`: remove by id if present; my list becoming empty →
    `Favourited` (the auto-favourite survives unbooking, as today).

### 5. Client — detail page multi-booking UX
- `UserClickedBook` (~2485): no-op only when `self_booking_of` is `Some` **and**
  `!can_book_others(model)`. When a self-booking exists and the user can book
  others, open the form with `booking_ui.target` preset to `BookingForOther`
  and render the segmented control disabled/locked (new flag or derive in view
  from `self_booking_of != None`).
- `view_detail_actions` (~4841): `booked` param becomes "has self-booking" for
  the Ändra/Avboka pair; `UserClickedChangeBooking`/`UserClickedUnbook` (~2521,
  ~2548) switch from `booking_of` to `self_booking_of`. A user with only
  for-other bookings sees "Boka" (not Ändra/Avboka) plus the bookings-page
  entry point.
- Capacity: unchanged — the server transaction still rejects overbooking; the
  client cap maths already work per-booking.

### 6. Client — manage variant of the bookings page
- `ActivityBookingsPage(id, bookings)` → `ActivityBookingsPage(id, bookings,
  booking_form: BookingFormState)` (init `BookingClosed` in `uri_to_page`).
- `can_view_bookings` (~876): include `BookingsOthersCreate`.
- `view_booking_card` (~5655): new `manageable: Bool` param —
  `booking.booked_for_other && can_book_others(model)`, matching the server
  rule. Manageable cards get an action row: "Ändra" (opens the drawer in
  `BookingEdit(booking.id)`, form seeded from the card's `Booking` via
  `booking_form_from`) and "Avboka" (drives `UnbookConfirming(booking.id)` →
  confirm/cancel, reusing the existing confirm pattern; the confirm UI renders
  in place on the card or above the list — pick the drawer-less inline variant
  used on the detail page). Every for-other card also shows a "Bokad åt annan
  kår" badge and `booker_name` as a caption, so staff can tell who created
  each entry.
- New messages (page-scoped, carrying the booking):
  `UserClickedEditBookingCard(Booking)`, `UserClickedUnbookCard(Uuid)` — plus
  arms so the existing `UserSubmittedBookingForm`, `ApiUpdatedBooking`,
  `UserClickedConfirmUnbook`/`UserClickedCancelUnbook`/`ApiDeletedBooking`
  handlers also match `ActivityBookingsPage(id, _, BookingOpen(...))` etc.
  Factor the shared arm bodies into helpers rather than duplicating (e.g. a
  `with_booking_form(page)`/`set_booking_form(page, state)` pair over both page
  variants, mirroring `activity_form_of`/`set_activity_form`).
- After a successful edit/unbook on the page: refetch `fetch_bookings(id)` +
  `fetch_activity_spots(id)` so the list and header stay live.
- The drawer on this page reuses `component.scout_drawer` exactly like the
  detail page (no nested drawers — plan 10's constraint doesn't apply here,
  the page has none).

### 7. OpenAPI (`server/priv/static/openapi.yaml`)
- `/statuses/me`: `ActivityStatusEntry.booking` → required `bookings` array;
  update examples.
- `/bookings/{id}` PUT/DELETE: document the manage rule — for-other bookings
  editable by any `bookings:others:create` holder, self-bookings only by
  their owner, `admin` overrides; 403 otherwise.
- `/activities/{activity_id}/bookings` GET + `/bookings/{id}` GET: add
  `bookings:others:create` to the allowed roles in the descriptions.

### 8. Tests
- Server: statuses grouping (two bookings on one activity → one entry with two
  bookings; favourite suppressed); manage rule (another user's *self* booking
  PUT/DELETE → 403; another user's *for-other* booking with
  `bookings:others:create` → 200/204; without the role → 403; admin overrides
  both).
- Client: `self_booking_of` picks the self booking among for-other ones;
  `UserClickedBook` opens the locked-to-other form when a self-booking exists
  and the role allows; edit/unbook flows on `ActivityBookingsPage` (open
  drawer, submit → `BookingSubmitting`; confirm unbook → delete effect);
  status fold: create appends, delete of last → `Favourited`, update/delete of
  a booking not in my statuses leaves them untouched.
- Update `client_test.gleam` fixtures for the `Booked(List)` shape and the new
  `ActivityBookingsPage` arity.

## Verification

- `gleam test` in `server/` and `client/`; `gleam format` everywhere.
- Seed note: `server/priv/seeding/bookings.sql` predates the flag, so add a
  couple of `booked_for_other = true` rows under a *different* seeded user —
  otherwise step 2/4's "another user's for-other booking" can't be exercised.
- Live (`DEV_AUTH_ROLES=admin`, seeded DB):
  1. Book a slot for yourself, then book the same slot for kår A and kår B —
     three bookings, one `statuses/me` entry with three bookings, spots sum
     correctly.
  2. Open "Visa bokningar": every for-other card (yours *and* the seeded ones
     from other users) carries Ändra/Avboka + the "bokad åt annan kår" badge
     with its creator's name; self-booking cards of other users are view-only.
     Edit one for-other booking's participant count and watch the header count
     update.
  3. Unbook the self booking from the detail page — for-other bookings remain,
     heart stays (still `Booked`), "Boka" still available.
  4. As `DEV_AUTH_ROLES=bookings:others:create` (no `bookings:read`): the
     bookings page loads (200); PUT/DELETE on another user's *for-other*
     booking → 200/204; on another user's *self* booking → 403.
  5. As a role-less self-booker: single-booking UX unchanged (Boka → booked →
     Ändra/Avboka, no second booking possible), and PUT/DELETE on any booking
     that isn't theirs → 403.

# 21. Booking cancellation with reason (issue #43)

> **Status: 🔲 Not started** (as of 2026-07-20)

## Context

Issue #43: staff should be able to remove a booking in a way that leaves a
trace — "a status on the booking with a reason so that both the booker and
the manager can see that they removed it and why." Today the only removal is
the hard `DELETE /api/bookings/:id` (plan 17 gave every `bookings:others:create`
holder that power), which silently erases the row: the booker just sees their
booking vanish.

Design (settled with the user, superseding the issue's "activity managers"
wording):

- The **`bookings:others:create` role** (which `admin` implies) gates the new
  actions — not `activities:manage`.
- On the per-activity bookings page, each card gets **Ändra / Avboka / Ta
  bort**: *Ta bort* is today's hard delete; *Avboka* opens a form asking for
  a reason and soft-cancels the booking.
- A cancelled booking shows a **red "Avbokad" tag instead of the green
  "Bokad"** — on the bookings-page card (for role holders) and on the
  booker's favourites-list card.
- Opening the activity of a cancelled booking shows a **warning callout with
  the cancel reason above the description**.
- **Capacity**: a cancelled booking frees its spots (excluded from every
  spots count).
- **Owner's own Avboka** (detail page) stays a hard delete — no reason form,
  no Avbokad state for self-removal.
- A cancelled booking is **terminal for the booker**: they cannot book the
  activity again while the cancelled row exists (server-enforced 409 +
  client gate). A role holder can **Återställ** (restore, subject to a
  capacity re-check) or **Ta bort** it; Ändra and a second Avboka are not
  offered on a cancelled card.

### Current state (anchors, on top of `4ea6ba7`)

- **DB**: `booking` has no status column; `delete_booking.sql` hard-deletes.
  Spots counts sum `participant_count` over *all* rows:
  `get_activity_spots.sql`, `list_activity_spots.sql`,
  `list_recurring_bookings_overview.sql`.
- **Server**: `server/src/server/web/booking.gleam` — `create` (locking
  transaction: `lock_activity` → `ensure_not_called_off` → `ensure_bookable`
  → capacity → insert), `update` (same locking shape, `ensure_may_manage`),
  `delete` (load-first 403, then delete), `may_manage` at line 83. Routes in
  `router.gleam:79-82`. `/statuses/me` (`web/status.gleam`) embeds the user's
  full bookings per activity — shape needs no change.
- **Shared**: `Booking` (`shared/model.gleam:451`) has no cancel field.
  Precedent to mirror: `Activity.cancellation: Option(String)` (the call-off).
  `ActivityStatus.Booked(bookings)` carries the embedded list; client helpers
  `is_booked`/`bookings_of`/`self_booking_of` at `client.gleam:441-464`.
- **Client** (`client/src/client.gleam`):
  - Bookings page: `view_activity_bookings` (5878), `view_booking_card`
    (6238), `view_booking_card_actions` (6341) — in-place confirm state
    machine over `BookingFormState` (578-588: `UnbookConfirming` /
    `UnbookSubmitting` drive today's "Avboka"-as-delete buttons).
  - Chip: `card_status` (4570) maps `is_booked` → `StatusBooked` (green);
    `component.CardStatus` already has `StatusCancelled(label)` → red badge
    (`component.gleam:445, 559`), currently only used for activity call-offs.
  - Detail page: description at 5200-5204; the call-off warning uses
    `component.warning_banner` at 5105-5110 — the exact pattern for the new
    callout. Book/manage actions in `view_detail_actions` (5260) +
    `book_action` (5336); `UserClickedBook` handler ~2960.
  - API effects: `delete_booking` (3665), `update_booking` (3562); status
    dict helpers `replace_status_booking` (469) / `remove_status_booking`
    (498). `ApiDeletedBooking`/`ApiUpdatedBooking` refetch bookings + spots.
  - Translations: sv (207) **and** en (45) blocks — every new key needs both.

## Design decisions

- **Representation: `cancellation_reason TEXT NULL`** on `booking`; shared
  `Booking.cancellation: Option(String)` mirroring `Activity.cancellation`.
  `NULL` = active, non-null = cancelled — a reason-less cancel or a reason on
  an active booking is unrepresentable. No separate status enum.
- **Endpoints, not PUT overloading**: `POST /api/bookings/:id/cancel`
  (`{"reason": "..."}`) and `POST /api/bookings/:id/restore`. Both require
  `bookings:others:create` explicitly (`web.require_role`) — deliberately
  *stricter* than `may_manage`: an owner without the role hard-deletes via
  the existing DELETE but cannot soft-cancel.
- **Cancel is cheap, restore is guarded.** Cancel only writes the reason (it
  frees capacity, so no capacity check; 409 if already cancelled — the UI
  never offers a second Avboka). Restore runs the same locking transaction
  shape as create: lock activity → not called off → capacity check with the
  booking's `participant_count` → clear the reason. Restore does **not**
  re-check the booking-window opens-at (the booking predates it); a passed
  activity can still be restored (harmless, keeps the rule simple).
- **Cancelled bookings are invisible to capacity**: every spots aggregate
  gains `cancellation_reason IS NULL`. They stay visible in booking lists
  (`get_bookings_by_activity`, `/statuses/me`) — that's the point.
- **Edit of a cancelled booking is rejected** (409): the card doesn't offer
  Ändra, and the server enforces it inside `update`'s transaction.
- **Create blocks on an existing cancelled booking**: inside `create`'s
  transaction, a cancelled booking by the calling user on the activity rolls
  back to 409 `{"error": "Cancelled booking exists"}`. The client mirrors the
  gate (no Boka button while a cancelled booking exists — the callout
  explains why).
- **`/statuses/me` shape unchanged**: entries stay `"booked"` with the full
  embedded bookings list; each booking now carries `cancellation`. The client
  derives the chip: any active booking → green Bokad; bookings all cancelled
  → red Avbokad. (Server-side the "booked dominates favourited" merge is
  untouched.)
- **Reason form is a drawer of its own**: Avboka opens a second
  `component.scout_drawer` on the bookings page (heading "Avboka bokning",
  textarea + submit), alongside the existing edit drawer — the same
  open/close pattern, driven by new `BookingFormState` variants. Ta bort and
  Återställ keep the lightweight in-place card confirm.
- **Label shift on the bookings page**: "Avboka" (currently the hard delete
  on cards) becomes the soft-cancel; the hard delete is relabelled "Ta bort"
  and keeps the existing `Unbook*` confirm flow and messages. The owner's
  detail-page "Avboka" keeps its current delete semantics untouched.

## Changes

### 1. Migration

`gleam run -m cigogne new --name booking_cancellation_reason`, then:

```sql
--- migration:up
ALTER TABLE booking ADD COLUMN cancellation_reason TEXT;
--- migration:down
ALTER TABLE booking DROP COLUMN cancellation_reason;
--- migration:end
```

### 2. SQL (`server/src/server/sql/`) + regenerate squirrel

- Add `cancellation_reason` to the SELECT/RETURNING lists of: `get_booking`,
  `get_bookings_by_activity`, `get_bookings_by_user`, `update_booking`,
  `create_booking_with_group`, `create_booking_without_group`.
- Exclude cancelled rows from capacity: `get_activity_spots` (`AND
  cancellation_reason IS NULL`), `list_activity_spots` (join condition),
  `list_recurring_bookings_overview` (join condition).
- New `cancel_booking.sql`: `UPDATE booking SET cancellation_reason = $2
  WHERE id = $1 RETURNING <full row>`.
- New `restore_booking.sql`: `UPDATE booking SET cancellation_reason = NULL
  WHERE id = $1 RETURNING <full row>`.
- New `get_cancelled_booking_by_user_and_activity.sql`: `SELECT id FROM
  booking WHERE user_id = $1 AND activity_id = $2 AND cancellation_reason IS
  NOT NULL LIMIT 1` (create-block check).
- `gleam run -m squirrel`, `gleam format`.

### 3. Shared model (`shared/src/shared/model.gleam`)

- `Booking` gains `cancellation: Option(String)` (doc comment: set by a
  `bookings:others:create` holder cancelling the booking; the reason both
  sides see; `None` = active).
- `booking_decoder`: `decode.optional_field("cancellation", None,
  decode.optional(decode.string))` — same pattern as `booked_for_other`.

### 4. Server model (`server/src/server/model/booking.gleam`)

- Every `from_*_row` conversion maps the new column; the two create
  conversions set `cancellation: None` where the row lacks it (they won't —
  RETURNING includes it).
- `to_json` adds `#("cancellation", json.nullable(cancellation, json.string))`.

### 5. Server handlers (`server/src/server/web/booking.gleam`)

- **`cancel(req, id, ctx)`** (POST): `require_role(user,
  web.BookingsOthersCreate)`; decode `{"reason": String}`; reject
  empty/whitespace reason (400); load booking (404 if missing); 409
  `{"error": "Booking already cancelled"}` if `cancellation` is `Some`;
  `sql.cancel_booking`; 200 with the booking JSON. Plain queries — no
  transaction needed (cancelling only frees capacity).
- **`restore(req, id, ctx)`** (POST): same role guard; locking transaction:
  `load_booking` (404) → must be cancelled (else 409) → `lock_activity` →
  `ensure_not_called_off` → capacity check (`spots_booked` now excludes this
  cancelled row, so check `spots_booked + participant_count` against the cap
  via `web.exceeds_capacity`) → `sql.restore_booking`; 200 with booking.
  New `BookingError` variants: `BookingAlreadyCancelled`,
  `BookingNotCancelled` (mapped to 409s).
- **`update`**: inside the transaction, after `ensure_may_manage`, roll back
  with `BookingAlreadyCancelled` (409) when the loaded booking is cancelled.
- **`create`**: inside the transaction (after `lock_activity`), new step
  `ensure_no_cancelled_booking(conn, user_id, activity_id)` using the new
  query → rolls back to 409 `{"error": "Cancelled booking exists"}`.
- **`delete`**: unchanged (Ta bort).
- **Router** (`server/src/server/router.gleam`): `Post, ["bookings", id,
  "cancel"]` and `Post, ["bookings", id, "restore"]` + method-not-allowed
  arms.

### 6. Server tests (`server/test/server/web/booking_test.gleam`)

- Extend the `a_booking` fixture with `cancellation:` (parameter or a second
  fixture `a_cancelled_booking`).
- `may_manage` tests: unchanged (field is inert there) — just fix the
  constructor calls.
- Add pure tests for whatever validation helpers emerge (e.g. reason
  non-empty normalisation, the cancelled-state checks) — handler round-trips
  are covered live (§10).

### 7. Client (`client/src/client.gleam` + `client/src/component.gleam`)

- **Status helpers** (~441-464): add `has_active_booking(status) -> Bool`
  (any embedded booking with `cancellation == None`) and
  `cancelled_bookings_of(status) -> List(Booking)`. `self_booking_of` gains a
  companion or filter so the detail page distinguishes an active self-booking
  from a cancelled one.
- **Chip** (`card_status`, 4570): activity call-off keeps precedence (caller
  4530); then `Booked` with an active booking → green `StatusBooked`
  ("Bokad"); `Booked` with only cancelled bookings → red
  `StatusCancelled(t("booking.cancelled_badge"))` ("Avbokad"). Shows on
  favourites/browse cards for the booker automatically (statuses feed them).
- **Bookings-page card** (`view_booking_card`, 6238): cancelled booking →
  red "Avbokad" badge (`component.badge(component.BadgeRed, ...)`) in the
  card header area.
- **Card actions** (`view_booking_card_actions`, 6341):
  - Active card: **Ändra bokning** (unchanged msg) · **Avboka** (new soft
    cancel) · **Ta bort** (existing `UserClickedUnbookCard` confirm flow,
    relabelled; confirm button "Ja, ta bort").
  - Cancelled card: **Återställ** (with in-place confirm) · **Ta bort**.
  - New `BookingFormState` variants alongside `UnbookConfirming`/
    `UnbookSubmitting`:
    `CancelReasonEditing(booking_id: Uuid, reason: String)`,
    `CancelSubmitting(booking_id: Uuid, reason: String)`,
    `RestoreConfirming(booking_id: Uuid)`,
    `RestoreSubmitting(booking_id: Uuid)`.
    Restore keeps the in-place card confirm (like Ta bort).
- **Cancel-reason drawer**: a second `component.scout_drawer` on the
  bookings page (next to the edit drawer at 5902), open while the form state
  is `CancelReasonEditing`/`CancelSubmitting`, heading
  `t("booking.cancel_heading")`. Body: `component.scout_textarea_field` for
  the reason + Avbryt / "Avboka" actions — submit disabled while the trimmed
  reason is empty, loader while `CancelSubmitting`. Close (drawer dismiss or
  Avbryt) → `BookingClosed`, mirroring the edit drawer's close wiring
  (5903-5908).
- **Messages + handlers**: `UserClickedCancelBookingCard(Uuid)`,
  `UserEditedCancelReason(String)`, `UserClickedConfirmCancelBooking`,
  `UserClickedRestoreBookingCard(Uuid)`, `UserClickedConfirmRestore`, and
  the shared abort reuses `UserClickedCancelUnbook` (→ `BookingClosed`).
  Api side: `ApiCancelledBooking(activity_id, Result(Booking, HttpError))`,
  `ApiRestoredBooking(activity_id, Result(Booking, HttpError))` — on Ok:
  `replace_status_booking`, close form, `effect.batch([fetch_activity_spots,
  fetch_bookings])` (both flows change spots), mirroring `ApiUpdatedBooking`
  (3176).
- **Effects**: `cancel_booking(activity_id, booking_id, reason)` → POST
  `/api/bookings/{id}/cancel`; `restore_booking(activity_id, booking_id)` →
  POST `/api/bookings/{id}/restore`, modelled on `update_booking` (3562).
- **Detail page**:
  - Warning callout above the description (5200): when the viewer's status
    for this activity has cancelled bookings, render
    `component.warning_banner(t("booking.cancelled_notice"), reason)` per
    cancelled booking (in practice one).
  - `view_detail_actions` (5260) + `UserClickedBook` (~2960): with a
    cancelled self-status and no active booking, offer **no** Boka button
    (callout explains) and no Ändra/Avboka pair; `self_booked` must key off
    *active* bookings only.
- **AppError**: `CancelBookingFailed` / `RestoreBookingFailed` + keys.
- **Translations** (sv 207 / en 45 — both):
  `booking.cancelled_badge` "Avbokad"/"Cancelled" ·
  `booking.remove` "Ta bort"/"Remove" ·
  `booking.confirm_remove` "Ja, ta bort"/"Yes, remove" ·
  `booking.cancel_heading` "Avboka bokning"/"Cancel booking" ·
  `booking.cancel_reason` "Anledning"/"Reason" ·
  `booking.confirm_cancel_booking` "Avboka"/"Cancel booking" ·
  `booking.restore` "Återställ"/"Restore" ·
  `booking.confirm_restore` "Ja, återställ"/"Yes, restore" ·
  `booking.cancelled_notice` "Bokningen är avbokad"/"Booking cancelled" ·
  `error.cancel_booking` / `error.restore_booking`.
  (`booking.unbook` "Avboka" stays for the owner's detail-page delete and
  the card's new soft-cancel button.)

### 8. Client tests (`client/test/client_test.gleam`)

- Fixture `a_booking` gains `cancellation: None`; add `a_cancelled_booking`.
- New: cancel flow (click Avboka → `CancelReasonEditing` opens the drawer;
  empty reason can't submit; typed reason → confirm dispatches the cancel
  effect and `CancelSubmitting`; dismiss closes to `BookingClosed`); restore
  flow (confirm → restore effect);
  `ApiCancelledBooking` folds the returned booking into statuses and
  refetches; chip derivation (`card_status` red when all bookings
  cancelled, green when one active remains); detail page hides Boka when a
  cancelled booking exists; callout renders the reason.
- Existing unbook tests keep passing (only labels changed).

### 9. OpenAPI (`server/priv/openapi.yaml`)

- `Booking` schema/examples: nullable `cancellation` string.
- New paths `/bookings/{id}/cancel` and `/bookings/{id}/restore` (role,
  request/response bodies, 400/403/404/409 cases; restore's capacity 409).
- `POST /activities/{id}/bookings`: document the 409 "Cancelled booking
  exists" case. `PUT /bookings/{id}`: document the 409 on cancelled.

### 10. Verification

- `gleam test` in `server/` and `client/`; `gleam format` everywhere.
- Live (`./seed.sh`, `./start.sh`):
  1. As `DEV_AUTH_ROLES=bookings:others:create`: `POST
     /api/bookings/dd000002-.../cancel` with a reason → 200, row keeps
     existing fields + reason; the activity's spots (`/api/activities/:id/spots`)
     drop by its `participant_count`; second cancel → 409; `PUT` on it → 409;
     `POST .../restore` → 200 and spots return; restore when the activity is
     full → 409 capacity.
  2. As the seeded dev user with `bookings:self:create` only: cancel/restore
     → 403; booking an activity where they have a cancelled booking → 409.
  3. UI as `admin` on the bookings page: active card shows Ändra/Avboka/Ta
     bort; Avboka opens the reason form and submits; card flips to red
     Avbokad with Återställ/Ta bort; favourites list shows red Avbokad chip
     for the booker; the activity detail page shows the warning callout with
     the reason above the description and no Boka button; Återställ brings
     everything back to green.

## Handoff notes

- Read plans 16 + 17 first — the bookings page, the status-dict helpers, and
  `may_manage` all come from them; this plan layers a *stricter* role gate
  (`require_role(BookingsOthersCreate)`) for cancel/restore on top of
  `may_manage`, which still governs update/delete.
- The label shuffle is the subtle UX bit: card "Avboka" changes meaning
  (delete → soft-cancel) while the owner's detail-page "Avboka" still
  deletes. Don't unify them.
- Spots invalidation matters on cancel *and* restore — both change capacity;
  copy `ApiUpdatedBooking`'s refetch batch.
- The ETag'd endpoints (`list_activity_spots`, recurring overviews) pick up
  the exclusions automatically since the body changes; no cache handling
  needed.
- Work lives in worktree branch `worktree-issue-43-booking-cancellation`
  (issue #49 is in flight on `main` in parallel — expect a `client.gleam`
  merge, keep the new code in self-contained functions where possible).
- Commit should include `Closes #43`.

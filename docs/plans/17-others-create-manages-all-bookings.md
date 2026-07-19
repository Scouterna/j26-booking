# 17. `bookings:others:create` manages every booking

> **Status: ✅ Done 2026-07-19** (commit `990370a`; shipped as planned —
> server rule, client gate, drawer identity, card caption, tests, and
> OpenAPI all match §1–§5, verified live per the plan's four scenarios)

## Context

Plan 16 (commit `13834ee`) made on-behalf bookings (`booked_for_other = true`)
**team-managed**: any `bookings:others:create` holder can edit/unbook them from
the per-activity "Visa bokningar" page. But other users' **self-bookings**
remained view-only — the manage rule was:

- for-other booking → requires `bookings:others:create`
- self-booking → owner only
- `admin` overrides both

This plan widens that: info-tent staff (`bookings:others:create`, or `admin`)
should be able to **edit and unbook (avboka) *any* booking** — including other
users' self-bookings — from the bookings list. Regular users keep owner-only
rights over their own booking.

### Current state (anchors, at `1cd7f2b`)

- **Server rule:** `may_manage` in `server/src/server/web/booking.gleam:76`
  branches on `booking.booked_for_other`. It is `pub` (tests exercise it
  directly) and enforced by both `update` (in-transaction, rolls back
  `NotBookingManager` → 403) and `delete` (load-first, then 403).
- **Client gate:** `view_activity_bookings` (`client/src/client.gleam:5591`)
  receives `can_manage_for_other` and marks a card manageable with
  `can_manage_for_other && booking.booked_for_other` (`client.gleam:5659`).
  Manageable cards render `view_booking_card_actions` (`client.gleam:6036`) —
  Ändra/Avboka with in-place confirm.
- **Edit-drawer identity block:** `view_booking_form_section` computes
  `edited_for_other` (`client.gleam:5196`) — when the edited booking is found
  in `bookings_in_scope` **and** is `booked_for_other`, the drawer shows the
  booking's kår + "Bokad av \<booker\>" read-only
  (`view_edited_for_other_identity`, `client.gleam:5346`) instead of the
  editor's own Scoutnet identity. Editing another user's *self*-booking would
  currently fall through to the editor's own identity block — wrong for this
  feature (see §3).
- **Server tests:** `server/test/server/web/booking_test.gleam` pins the old
  rule — `self_booking_not_managed_by_role_holder_test` (line 48) asserts the
  exact behaviour this plan removes.
- Status-dict robustness is already in place from plan 16: the client's
  `replace_status_booking`/`remove_status_booking` tolerate booking ids not in
  my statuses, so editing/deleting *any* foreign booking needs no new client
  state handling.

## Design decisions

- **New rule (simpler than the old one):**

  ```gleam
  fn may_manage(user: web.User, booking: Booking) -> Bool {
    booking.user_id == user.id || web.has_role(user, web.BookingsOthersCreate)
  }
  ```

  Owner, or any `bookings:others:create` holder (which `has_role` already
  grants to `Admin`). `booked_for_other` no longer affects authorization —
  it stays purely informational (the badge, the identity block).
- **Consequence accepted:** the owner of a *for-other* booking can now manage
  it even if the role has since been revoked (`user_id == user.id`). Under
  plan 16 they could not. This is the price of the simpler rule and is
  considered fine — they created the booking while holding the role.
- **Client gate follows the server:** a card is manageable exactly when the
  user holds `bookings:others:create` (`can_book_others(model)`), for every
  booking. No per-card owner check is needed client-side — a role holder may
  manage everything on the list, and non-holders never see the page's actions
  (their own self-booking is managed from the detail page, unchanged).
- **Edit-drawer identity generalises:** editing *any* booking from the
  bookings page shows that booking's stored identity (kår + "Bokad av") — not
  just for-other ones. Detail-page self-edits keep today's Scoutnet identity
  block. Discriminate with an explicit flag rather than guessing from the
  booking (the client has no user id to compare against — deliberately, see
  plan 16's "no identity check" decision).
- **Show the booker on every card:** with all cards editable, staff need to
  see whose booking each one is. Extend the existing caption ("Bokad åt annan
  kår · Bokad av X") so self-booking cards also get a "Bokad av X" line when
  the viewer can manage bookings (avoid noise for `bookings:read`-only
  viewers, who see the same list).

## Changes

### 1. Server — the rule (`server/src/server/web/booking.gleam`)
- Replace the `may_manage` body (line ~76) with
  `booking.user_id == user.id || web.has_role(user, web.BookingsOthersCreate)`
  and rewrite its doc comment: any `bookings:others:create` holder (or admin,
  via `has_role`) manages every booking; everyone else only their own.
- `update`/`delete`/`ensure_may_manage` need no changes — they already call
  `may_manage`.

### 2. Server tests (`server/test/server/web/booking_test.gleam`)
- `self_booking_managed_by_owner_test` (line 41): still holds, keep.
- `self_booking_not_managed_by_role_holder_test` (line 48): **invert** — a
  role holder now *may* manage another user's self-booking; a role-less user
  still may not. Rename accordingly (e.g.
  `self_booking_managed_by_role_holder_test`).
- `for_other_booking_managed_by_any_role_holder_test` (line 59): the second
  assertion (`!may_manage(owner-without-role, own for-other booking)`) flips —
  the owner may now manage it. Update assertion + doc comment.
- `admin_manages_everything_test` (line 69): still holds, keep.

### 3. Client (`client/src/client.gleam`)
- **Gate:** in `view_activity_bookings` (~5591) rename the param
  `can_manage_for_other` → `can_manage_bookings` (still fed by
  `can_book_others(model)` at the call site, ~3706) and change the card call
  (~5659) to pass `manageable: can_manage_bookings` — dropping the
  `&& booking.booked_for_other` term.
- **Edit-drawer identity:** in `view_booking_form_section`, replace the
  `edited_for_other` guard (`Ok(b) if b.booked_for_other`, ~5196) with a new
  explicit parameter, e.g. `show_stored_identity_on_edit: Bool`:
  - bookings page passes `True` → any `BookingEdit` whose booking is found in
    `bookings_in_scope` renders `view_edited_for_other_identity` (rename to
    `view_edited_booking_identity`; for a self-booking with no
    `booker_group_name` skip the kår row rather than showing an empty field —
    today's `option.unwrap(_, "")` would render one).
  - detail page passes `False` → self-edits keep the Scoutnet block exactly
    as today.
- **Card caption (~5947 `view_booking_card`):** the "Bokad av {name}" line
  currently renders only with the for-other badge. Split it: for-other cards
  keep badge + name; self-booking cards show just "Bokad av {name}" when
  `manageable`. (Pass `manageable` in — it already is.)
- No update-arm changes: `UserClickedEditBookingCard`/`UserClickedUnbookCard`
  and the Api handlers already work for any card booking (plan 16 made the
  status folds tolerate unheld ids).

### 4. Client tests (`client/test/client_test.gleam`)
- The bookings-page flow tests (`edit_booking_card_opens_drawer_...`,
  `submitting_edit_on_bookings_page_...`, `unbook_card_confirms_...`) use a
  `booked_for_other: True` fixture — add a variant exercising another user's
  *self*-booking (plain `a_booking` with a foreign `user_id`) through the same
  edit flow, proving the gate no longer depends on the flag.
- `deleting_unheld_booking_leaves_statuses_test` /
  `updating_unheld_booking_leaves_statuses_test` already cover the status
  robustness — keep.

### 5. OpenAPI (`server/priv/static/openapi.yaml`)
- `PUT /bookings/{id}` and `DELETE /bookings/{id}` descriptions: replace the
  flag-based rule text with: editable/deletable by its owner or by any
  `bookings:others:create` holder (`admin` implies the role); 403 otherwise.
  (The `booked_for_other` mentions in the `Booking` schema stay — the flag
  still exists, it just no longer gates authorization.)

### 6. Docs
- Plan 16's "Design decisions" describes the flag-based rule as current —
  no edit needed (plans are point-in-time), but this plan supersedes that
  rule; keep the index row order (17 after 16).

## Verification

- `gleam test` in `server/` and `client/`; `gleam format` everywhere.
- Live (seeded DB — `./seed.sh` provides other-user self-bookings
  `dd000002`/`dd000004` and for-other rows `dd000006`/`dd000007`):
  1. As `DEV_AUTH_ROLES=bookings:others:create`:
     `PUT /api/bookings/dd000002-...` (another user's **self**-booking) →
     **200** (was 403); `DELETE` → **204**. For-other rows keep working.
  2. As a role-less user (`DEV_AUTH_ROLES=bookings:self:create`): the same
     PUT/DELETE → still **403**; own booking → 200/204.
  3. UI as `admin` on `activities/6f5e1d46-.../bookings`: **every** card now
     carries Ändra/Avboka; self-booking cards show "Bokad av \<name\>";
     editing another user's self-booking shows the booking's stored identity
     (their kår + name), not yours; edit + unbook round-trip refreshes the
     list and header count.
  4. Detail page as a regular user: own booking edit unchanged (Scoutnet
     identity block still shown).

## Handoff notes

- **Everything here is additive on top of `13834ee`** (plan 16); read that
  plan first — this one only widens its authorization rule and gate.
- The one subtle spot is §3's identity block: don't be tempted to derive
  "is this my booking" client-side — the client deliberately has no own-user
  id (plan 16 removed the need); use the explicit page flag.
- `may_manage` and the card gate must stay in lockstep — if they diverge, the
  UI offers buttons the server 403s (or hides ones it would allow). The
  server rule is the source of truth; mirror it exactly.
- Run `./start.sh` with `DEV_AUTH_ROLES=<roles>` to impersonate each role
  locally (tokenless requests authenticate as the seeded dev user
  `a1b2c3d4-...`); re-run `./seed.sh` if the dd-prefixed bookings are missing.
- Deploys are automatic: merge to `main` → image build → ArgoCD image updater
  rolls dev. No migration is needed for this plan (no schema change).

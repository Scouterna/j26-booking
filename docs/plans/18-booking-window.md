# 18. Booking window: opens-at date & no booking after the end (issues #35 + #36)

> **Status: ✅ Done 2026-07-19** (commit `93cf499`; shipped as planned with
> one divergence: `BOOKING_OPENS_AT` unset no longer means "open immediately"
> — it defaults to the start of the camp, `2026-07-25T00:00:00+02:00`
> (Markus's call during implementation), so the global gate is always `Some`.
> Verified live per §Verification: all six scenarios pass, plus the UI gate
> and form field checked in the browser.)

## Context

Two High-priority issues, one concept — a **booking window** per activity:

- **#35 — You should not be able to book activities in the past.** Decision
  (Markus, 2026-07-19): an activity is bookable **until its end time if it has
  one**, otherwise until its start time. Today `end_time` is `NOT NULL`
  (initial migration), so the cutoff is always the end time — but issue #39
  plans to make the end time optional, so the rule must be written end-ready.
- **#36 — The possibility to book activities should open a certain day.**
  Decision (Markus, 2026-07-19): **global default date + per-activity
  override** — one configured date before which nothing can be booked, and an
  optional per-activity `booking_opens_at` that overrides it (needed for e.g.
  Badbuss/Klättervägg slots that may open on their own schedule).

So the window is: `effective_opens_at ≤ now ≤ cutoff`, where
`effective_opens_at = activity.booking_opens_at ?? global BOOKING_OPENS_AT ??
always-open`, and `cutoff = end_time ?? start_time`.

### Current state (anchors, at `36182d0`)

- **Booking create:** `create` in `server/src/server/web/booking.gleam:91` runs
  a locking transaction: `lock_activity` (line 196, via
  `sql/lock_activity_max_attendees.sql` — returns only `max_attendees`) →
  `ensure_not_called_off` (line 183) → capacity check → insert. Rollback
  reasons are the `BookingError` type (line 59), each mapped to an HTTP status
  in the `case` at line 141 (called-off → 409 with `{"error": ...}`).
- **Activity schema:** `activity` table has `start_time`/`end_time`
  `TIMESTAMP NOT NULL` (`server/priv/migrations/20250905210402-initial.sql`).
  No opens-at column anywhere; the original MVP issue #2 listed "when the
  event should open for booking" but it was never built.
- **Activity input:** `ActivityInput`/`activity_input_decoder` in
  `server/src/server/web/activities.gleam:411/426` — timestamps arrive as unix
  seconds. Create/update use paired SQL variants
  (`create_activity_with/without_max_attendees.sql`, same for update) because
  Squirrel parameters are non-optional; the repo's pattern for an optional
  column set after the fact is `set_activity_location.sql` /
  `clear_activity_location.sql`.
- **Shared types:** `Activity` and `ActivitySummary` in
  `shared/src/shared/model.gleam:10/204` both carry `start_time`/`end_time`
  as required `Timestamp`s; JSON uses unix seconds via optional-tolerant
  decoders.
- **Client booking CTA:** `book_action` (`client/src/client.gleam:5090`) is
  the single place the "Boka" button renders; both call sites (booked-user
  stacking at ~5057, not-booked at ~5080) already gate on
  `activity.cancellation` — the window gate slots in the same way. The client
  reads the clock with `timestamp.system_time()` (already used at ~4178).
- **Activity form:** `start_time`/`end_time` fields parse at
  `client.gleam:1536` (`form.parse_date_time`) and render at ~4578.
- **Server clock:** `timestamp.system_time()` already used in
  `server/src/server/web.gleam:459`.

## Design decisions

- **One pure shared function, used by both sides.** In
  `shared/src/shared/model.gleam`:

  ```gleam
  pub type BookingWindow {
    /// Booking has not opened yet; carries when it will.
    BookingNotYetOpen(opens_at: Timestamp)
    BookingOpen
    /// The activity's cutoff (end time, else start time) has passed.
    BookingClosed
  }

  pub fn booking_window(
    now now: Timestamp,
    opens_at opens_at: Option(Timestamp),
    start_time start_time: Timestamp,
    end_time end_time: Option(Timestamp),
  ) -> BookingWindow
  ```

  `end_time` is `Option` **in the function signature only** (end-ready for
  #39); callers pass `Some(activity.end_time)` today. Cutoff =
  `end_time ?? start_time`. Server enforces with it; client renders with it.
  Server is the source of truth — the client check is cosmetic (clock skew is
  acceptable there, the server rejects regardless).
- **Global default via env var `BOOKING_OPENS_AT`** (RFC 3339, e.g.
  `2026-06-01T08:00:00Z`), parsed once at startup with
  `timestamp.parse_rfc3339` into a new `web.Context` field
  `booking_opens_at: Option(Timestamp)`. Unset → bookings open (today's
  behaviour). **Invalid value → fail startup** (a typo must not silently open
  booking early).
- **Per-activity override column** `booking_opens_at TIMESTAMP NULL` on
  `activity`. Persisted with the existing set/clear-query pattern (like
  `set_activity_location`) so the with/without-max_attendees create/update
  variants don't multiply.
- **The API serialises the *effective* opens-at** so the client never needs
  the env value: `booking_opens_at` (unix seconds, optional) on both the
  summary and detail JSON = `coalesce(row.booking_opens_at, global)`. The
  **detail** JSON additionally carries `booking_opens_at_override` (the stored
  column, optional) — that is what the manager edit form round-trips;
  otherwise saving an activity would freeze the global default into an
  override.
- **Enforced on booking *create* only.** Update/delete stay allowed after the
  window closes: managers must be able to remove past bookings (issue #43),
  and a leader fixing a participant count on-site is fine. Capacity is still
  checked on update, so nothing can overbook. Cheap to revisit.
- **New rollback reasons → 409s**, matching the called-off pattern:
  - `BookingNotYetOpen(opens_at)` → 409
    `{"error": "Booking is not open yet", "booking_opens_at": <unix seconds>}`
  - `ActivityHasPassed` → 409 `{"error": "Activity has passed"}`
- **Client UX mirrors the cancellation gate:** window state replaces the
  "Boka" button — `BookingNotYetOpen` renders a disabled button/callout
  "Bokningen öppnar {datetime}" (new translation keys, sv + en);
  `BookingClosed` renders no booking action (like a called-off activity).
  Applies to both `book_action` call sites, so on-behalf stacking is gated
  identically. Existing bookings keep their Ändra/Avboka actions.
- **Out of scope:** greying out passed activities on list cards, hiding them
  from the list, or a countdown. The list keeps showing everything; only the
  booking CTA is gated. (Day-windowed lists already keep old days reachable
  deliberately.)

## Changes

### 1. Migration
- `gleam run -m cigogne new --name add_activity_booking_opens_at`; up:
  `ALTER TABLE activity ADD COLUMN booking_opens_at TIMESTAMP;` down: drop it.

### 2. SQL + Squirrel (`server/src/server/sql/`)
- **Rename** `lock_activity_max_attendees.sql` → `lock_activity_for_booking.sql`
  returning `max_attendees, start_time, end_time, booking_opens_at` (still
  `FOR UPDATE`). Update the doc comment: it now feeds capacity *and* window
  checks.
- New `set_activity_booking_opens_at.sql` / `clear_activity_booking_opens_at.sql`
  (mirror the `set/clear_activity_location` pair).
- `get_activity.sql` is `SELECT *` — picks the column up automatically; the
  summary/list queries (`list_activities_by_start_time`,
  `get_activities_by_start_time`, `list_activities_by_title`,
  `get_activities_by_title`, `list_favourited_activities`,
  `list_beach_bus_activities`, `list_climbing_wall_activities`) each add
  `booking_opens_at` to their select list.
- `gleam run -m squirrel`, then fix `server/src/server/model/activity.gleam`
  row converters: each `from_*_row` gains a
  `default_booking_opens_at: Option(Timestamp)` argument and stores the
  coalesced (`option.or(row.booking_opens_at, default)`) value on the shared
  type; the detail conversion also keeps the raw override for
  `booking_opens_at_override`.

### 3. Server config (`server/src/server/utils.gleam`, `server.gleam`, `web.gleam`)
- Env helper to read an optional RFC 3339 timestamp; **crash startup on a
  present-but-unparseable value** with a clear message.
- `web.Context` gains `booking_opens_at: Option(Timestamp)`; `server.gleam`
  threads it in. Handlers pass it to the model converters (§2) as the
  default.

### 4. Booking create (`server/src/server/web/booking.gleam`)
- `lock_activity` returns the full locked row info (cap + times + opens-at).
- New transaction step after `ensure_not_called_off`:
  `ensure_bookable(now, opens_at, start_time, end_time)` calling the shared
  `booking_window`; `BookingNotYetOpen`/`BookingClosed` roll back with the new
  `BookingError` variants. `now = timestamp.system_time()` taken once in the
  handler, outside the transaction closure.
- Map the new variants to the 409 bodies (§ design). `update` untouched.

### 5. Activity create/update (`server/src/server/web/activities.gleam`)
- `ActivityInput` + decoder gain optional `booking_opens_at` (unix seconds).
- After the insert/update, run the set/clear query per the input value (same
  transaction/flow as the location set/clear handling).

### 6. Shared (`shared/src/shared/model.gleam`)
- `Activity`: add `booking_opens_at: Option(Timestamp)` (effective) and
  `booking_opens_at_override: Option(Timestamp)`; `ActivitySummary`: add
  `booking_opens_at: Option(Timestamp)`. Decoders: `optional_field` with unix
  seconds, defaulting `None` — old cached/ETag payloads without the field must
  keep decoding.
- Add `BookingWindow` + `booking_window` (§ design) with doc comments.

### 7. Client (`client/src/client.gleam`)
- `book_action` (5090): compute
  `model.booking_window(now:, opens_at: activity.booking_opens_at,
  start_time: activity.start_time, end_time: Some(activity.end_time))` and
  render per state; get `now` via `timestamp.system_time()` at view time (fine
  — every re-render re-evaluates, no stored clock).
- Both call sites (~5057, ~5080) need no change beyond what `book_action`
  returns; verify the booked-user stacking branch hides "Boka" but keeps
  Ändra/Avboka when closed.
- Manager form: optional "Bokning öppnar" date-time field — parse at ~1536
  (optional variant of `form.parse_date_time`; empty → `None`), render near
  the start/end inputs (~4578), seed from `booking_opens_at_override` (NOT the
  effective value), submit as unix seconds when set.
- Translations (sv + en): `activity.booking_opens` ("Bokningen öppnar {date}"),
  `activity.booking_closed` (if a passed-state hint is rendered),
  `edit.booking_opens_at` (form label).

### 8. OpenAPI (`server/priv/static/openapi.yaml`)
- Activity summary/detail schemas: `booking_opens_at` (+ `_override` on
  detail); activity create/update request: optional `booking_opens_at`;
  `POST /activities/{id}/bookings`: document both new 409 bodies alongside
  the called-off one.

### 9. Docs
- Root `CLAUDE.md` env-var table: add `BOOKING_OPENS_AT` (unset ⇒ booking
  open; RFC 3339; invalid ⇒ startup failure).
- Index row in `docs/plans/CLAUDE.md` (done when this plan lands).

### 10. Tests
- **`booking_window` unit tests** (this is where the value is — the function
  is pure): before open, exactly at open, open, between start and end, after
  end with `Some(end)`, after start with `end: None` (the #39-ready branch),
  no opens-at at all. Server test dir hosts them (shared has no test setup);
  `server/test/shared/model_test.gleam` or alongside the booking tests.
- Server: extend `booking_test.gleam`-style coverage if a pure seam exists
  for `ensure_bookable`; otherwise the live checks below carry it.
- Client: form round-trip test — editing an activity with no override leaves
  `booking_opens_at` absent from the submitted JSON.

## Verification

- `gleam test` + `gleam format` in `server/` and `client/`.
- Live (`./seed.sh`, then `./start.sh` with `DEV_AUTH_ROLES=admin`):
  1. `BOOKING_OPENS_AT=2027-01-01T00:00:00Z` → booking any activity via UI and
     `POST /api/activities/<id>/bookings` → 409 "not open yet" with the
     timestamp; button shows "Bokningen öppnar …".
  2. `BOOKING_OPENS_AT` unset → seeded future activity books normally (200 →
     201); a seeded activity whose `end_time` has passed → 409 "has passed",
     no Boka button on its detail page.
  3. Set a per-activity override in the manage form to a past date while the
     global is in the future → that activity books; others still 409. Re-open
     the form: the field shows the override, not the global.
  4. Clear the override in the form → activity falls back to the global gate.
  5. Existing booking on a passed activity: Ändra/Avboka still work
     (update/delete unaffected).
  6. `BOOKING_OPENS_AT=nonsense ./start.sh` → server refuses to start with a
     clear error.

## Handoff notes

- The window rule and its 409s live server-side; the client rendering is
  cosmetic. If the two ever disagree, trust the server and fix the client.
- The `end_time: Option` parameter of `booking_window` is deliberate
  future-proofing for issue #39 (optional end time) — do not "simplify" it to
  a required `Timestamp`, and when implementing #39, the cutoff logic is
  already done.
- The effective-vs-override JSON split (§ design) is the subtle spot: the
  gating value and the form value are different fields. Seeding the form from
  the effective value silently converts the global default into per-activity
  overrides.
- Timestamps in the DB are `TIMESTAMP` (no tz) like `start_time`/`end_time` —
  the app treats everything as UTC end to end; keep the new column consistent
  with the existing two.
- Commit message should carry `Closes #35` and `Closes #36`.

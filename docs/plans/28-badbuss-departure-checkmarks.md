# 28. Badbuss departure check-offs per kår

> **Status: 🚧 In progress** (as of 2026-07-29)

## Why

The badbuss staff need to account for every kår twice per slot: once when the
kår has left the campsite, and again when it has left the beach. Today the
slot's bookings view lists each kår but offers nowhere to record that, so the
tally is kept on paper.

Two checkmarks per group on the slot's bookings view, **badbuss only** —
klättervägg and ordinary activities must look exactly as they do now.

## Shape

The check-offs hang off the **booking** (one booking = one kår on one slot), so
they are two new columns on `booking` rather than a new table: there is exactly
one row per kår per slot already, and the flags have no history to keep.

### Database

`server/priv/migrations/20260729075614-booking_beach_bus_departures.sql`:

```sql
ALTER TABLE booking ADD COLUMN left_campsite BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE booking ADD COLUMN left_beach BOOLEAN NOT NULL DEFAULT FALSE;
```

Chosen to be safe for the live bookings: both columns are new, and `NOT NULL`
with a *constant* default is a catalog-only change in PostgreSQL 11+ — no table
rewrite, no row is read or moved, and every existing booking keeps all of its
current values. `migration:down` drops the two columns and nothing else.

Booleans rather than `TIMESTAMPTZ`: the ask is a checkmark, and "has this kår
left?" is the whole truth being recorded. Should staff later want *when*, that
is a follow-up migration, not a reason to store a timestamp nobody displays.

### API

Two endpoints, one per stage:

| Method | Path | Body |
| ------ | ---- | ---- |
| PUT | `/api/bookings/:id/left-campsite` | `{"checked": true｜false}` |
| PUT | `/api/bookings/:id/left-beach` | `{"checked": true｜false}` |

Both answer `200` with the whole updated booking.

- **One column per write.** Deliberately *not* one endpoint taking both flags:
  two staff members at the bus, each with a phone holding a slightly stale list,
  would otherwise clobber each other — the second write would carry a stale
  value for the first's flag. Each endpoint writes only its own column, so both
  ticks survive regardless of order.
- **Idempotent**, so a mistaken tick is undone by sending `false`.
- **Badbuss only.** The handler loads the booking's activity and refuses with
  `409 Booking is not on a beach bus slot` unless
  `recurring_activity_kind = 'beach-bus'`. A cancelled booking is refused too
  (`409 Booking is cancelled`) — that kår is not boarding. Both facts are
  stable (a booking never moves activity, an activity never changes kind), so
  the check needs no transaction around it.
- **Roles:** `bookings:read`, `activities:manage` or `bookings:others:create`
  (`admin` implies all three) — the same set that may *read* the badbuss
  booking lists, since whoever runs the bus is who ticks the boxes. Notably
  *not* the booker, who cannot read the slot's list at all.

`Booking` JSON gains `left_campsite` / `left_beach` (always present; always
`false` on a non-badbuss booking). Both decode with a `False` default, so a
payload predating the columns still decodes.

### Telling badbuss apart, client-side

The bookings view had no way to know which kind of activity it was showing:
`recurring_activity_kind` existed only inside the server. So:

- `RecurringKind` (`BeachBus` | `ClimbingWall`) moves into `shared/model`, and
  the client's and `web/activities.gleam`'s private duplicates are deleted in
  favour of it.
- `Activity` gains `recurring_kind: Option(RecurringKind)`, encoded by
  `activity.to_json` and carried on the client's `ActivityDetail`.
  **Detail-only** — `summary_to_json` and `ActivitySummary` deliberately do not
  carry it, so no list payload or ETag changes.
- The four activity create/update queries now return
  `recurring_activity_kind` as well, so editing a badbuss slot can't hand back
  a row claiming it has no kind.

### Client

`view_booking_card` renders the two `scout-checkbox`es under a small
"Avfärd" heading when — and only when — `activity.recurring_kind ==
Some(BeachBus)` and the booking is active. New `component.scout_checkbox` binds
`checked` through the JS **property**, not a presence attribute: the component
owns its checked state after a click, and only a property write pushes the
model's value back in.

Ticking is **optimistic** — a checkbox that waits for the network reads as
broken, and the model has to move in step with the component's own state. The
response replaces the card wholesale (so a tick someone else made on the other
stage lands too); a failure rolls the tick back to the value it had and shows
`error.set_departure` above the list. `ActivityBookingsPage` gained a
`departure_error: Option(AppError)` field for that, cleared by the next
successful tick or list refetch.

## Verification

- `gleam test` in all three packages (`shared` 19, `server` 72, `client` 155).
- New coverage: recurring-kind round trip and the tolerant decoders
  (`shared`), the endpoint's auth/role/id/body/method guards (`server`), and
  the optimistic tick, per-stage independence, replace-on-success,
  rollback-on-failure and clear-on-refetch flows (`client`).
- Live against the running app with a seeded database: tick both stages on a
  badbuss booking, confirm the columns, and confirm the `409` for a booking on
  an ordinary activity.

## Follow-ups (not in scope)

- A per-slot progress figure ("12 / 18 kårer avfärdade") on the badbuss
  overview cards. The overview query would need to aggregate the two flags.
- Recording *when* each stage was ticked, and by whom.

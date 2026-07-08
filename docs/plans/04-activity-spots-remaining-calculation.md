# 04. Real "spots remaining" via a dedicated activity-spots API

> **Status: ✅ Done 2026-07-03** (commit `2d46ced`; re-verified 2026-07-08)
>
> Shipped via the `activity-spots` endpoint (commit `2d46ced`): server has
> `list_activity_spots.sql` + `get_activity_spots.sql`, the `["activity-spots"]`
> route, and `spots.get_all`. Client replaced `mock_spots_remaining` with real
> data via `ApiReturnedActivitySpots` / `ApiReturnedActivitySpotsOne`.

## Context

"Spots remaining" on an activity is **not calculated** today — everything shown is placeholder:

- **List cards** (`client/src/client.gleam:1829`) call `mock_spots_remaining` (`client/src/client.gleam:2450`), which derives a fake "taken" count from a hash of the activity id. Nothing to do with real bookings.
- **Detail view** (`client/src/client.gleam:2054`) passes the raw `max_attendees` straight into the `activity.spots_remaining` plural label, with an explicit `// TODO: do real calculation based on bookings`. So it shows *total capacity* labelled as *remaining*.
- **Server** exposes `max_attendees` but never a booked count; no SQL aggregates `participant_count`.

The data model already supports the real thing:

- `activity.max_attendees : INT` (nullable — `NULL`/`None` = unlimited).
- `booking.participant_count : INT NOT NULL` — bookings are **party-based**, one row per booking group, each carrying how many people it represents. So booked people = `SUM(participant_count)` over all bookings for the activity, **not** a row count.

Correct value: **`spots_remaining = max(0, max_attendees − SUM(participant_count))`**, *unlimited* (no number) when `max_attendees` is `None`, and **unknown** when we have no fresh count in hand.

## Approach — split the hot data out

Booked counts are **volatile** (change on every booking, potentially by other users) while activity metadata (title, times, capacity) is effectively **static**. So the count gets its **own endpoint**, `/api/activity-spots`, fetched independently and far more often than the activity catalogue. The activity read shapes stay untouched and cacheable.

- Serve **raw `spots_booked`** from the spots endpoint (not a pre-computed `spots_remaining`) — the "unlimited" semantics (`max_attendees` is `None`) stay expressed in exactly one place, the activity. The spots endpoint is a pure single fact: "how many people are booked."
- The client holds counts in a separate `spots: Dict(Uuid, Int)`. **A missing entry means `Unknown`, not `0`.** So if activities are cached but the spots fetch never succeeded (e.g. offline cold start), cards render "unknown" rather than falsely claiming full availability.
- Refresh policy for now: **on load + after the current user's own booking mutations** (mutations refetch the single affected activity's count, catching concurrent bookings by others). No interval polling yet, but the endpoint is shaped so adding a poll later is a one-effect change (see *Polling readiness*).

### Why separate rather than a field on the activity

- Keeps the volatile number out of the cacheable activity payload — activities can get long-lived caching, spots `no-store`.
- **Zero changes to the 13 activity queries.** Only one new aggregate query, instead of bolting a subquery onto every activity SELECT/RETURNING.
- One source of truth for the count instead of it riding on summaries + detail + create/update responses.
- Trade-off accepted: two data sources to join client-side (a card needs summary + count), and a small consistency window. The `Unknown` default handles the "count for an as-yet-uncached activity / activity with no count yet" cases cleanly.

## Server

### New SQL — `server/src/server/sql/list_activity_spots.sql`

One row **per activity** (LEFT JOIN so zero-booking activities return `0`, not absent — the client needs to distinguish *known-zero* from *unknown*):

```sql
SELECT activity.id AS activity_id,
       COALESCE(SUM(booking.participant_count), 0) AS spots_booked
FROM activity
LEFT JOIN booking ON booking.activity_id = activity.id
GROUP BY activity.id
```

`COALESCE(..., 0)` over the nullable `bigint` sum makes `spots_booked` **non-null** → Squirrel generates `spots_booked: Int`.

### New SQL — `server/src/server/sql/get_activity_spots.sql`

Single activity, for the detail view and post-mutation refetch. An aggregate with no `GROUP BY` always returns exactly one row (`0` when there are no bookings):

```sql
SELECT COALESCE(SUM(participant_count), 0) AS spots_booked
FROM booking
WHERE activity_id = $1
```

Then, from `server/`: `gleam run -m squirrel` (regenerates `sql.gleam` — do not hand-edit) and `gleam format`.

### New handler — `server/src/server/web/spots.gleam`

No auth needed (counts aren't user-specific; mirrors `get_page`/`get_beach_bus` which don't call `with_authenticated_user`):

```gleam
pub fn get_all(req: Request, ctx: web.Context) -> Response {
  use <- wisp.require_method(req, Get)
  // -> { "spots": [ { "activity_id": <uuid>, "spots_booked": <int> }, ... ] }
}

pub fn get_one(req: Request, id: String, ctx: web.Context) -> Response {
  use <- wisp.require_method(req, Get)
  // parse uuid (bad_request on failure); run get_activity_spots
  // -> { "spots_booked": <int> }
}
```

Build the JSON inline from the rows (like `response_from_db_activity_summaries` does for activities). No new `server/model/` type needed.

### Router — `server/src/server/router.gleam`

- `Get, ["activity-spots"]` → `spots.get_all`; `_, ["activity-spots"]` → `method_not_allowed([Get])`.
- `Get, ["activities", id, "spots"]` → `spots.get_one(req, id, ctx)` — nested under the activity, idiomatic alongside the existing `["activities", id, "bookings"]`.

### `server/priv/static/openapi.yaml`

Add the two paths: `GET /api/activity-spots` → `{ spots: [ActivitySpots] }` and `GET /api/activities/{id}/spots` → `{ spots_booked }`. Define an `ActivitySpots` schema (`activity_id`, `spots_booked`, both required). Note `spots_booked` = summed `participant_count` of all bookings. (Required by `server/CLAUDE.md`.)

### Activity queries / shapes — unchanged

`Activity`/`ActivitySummary` and all their SQL queries stay exactly as they are. `spots_booked` is **not** a field on them.

## Shared (`shared/src/shared/model.gleam`)

### Spots response types + decoders (mirror `ActivityStatusEntry`)

```gleam
pub type ActivitySpots {
  ActivitySpots(activity_id: Uuid, spots_booked: Int)
}

pub fn activity_spots_decoder() -> decode.Decoder(ActivitySpots) { … }        // activity_id (uuid str), spots_booked (int)
pub fn activity_spots_list_decoder() -> decode.Decoder(List(ActivitySpots))   // field "spots"
pub fn spots_booked_decoder() -> decode.Decoder(Int)                          // { "spots_booked": n } for the single endpoint
```

### `SpotsRemaining` type + helper — make `Unknown` a first-class state

```gleam
pub type SpotsRemaining {
  Unlimited          // max_attendees is None
  Remaining(Int)     // known cap and known count, clamped at 0
  UnknownSpots       // capped, but we have no count in hand
}

/// `spots_booked` is `None` when the count is unknown (not fetched / offline).
pub fn spots_remaining(max_attendees: Option(Int), spots_booked: Option(Int)) -> SpotsRemaining {
  case max_attendees, spots_booked {
    None, _ -> Unlimited
    Some(_), None -> UnknownSpots
    Some(max), Some(booked) -> Remaining(int.max(0, max - booked))
  }
}
```

## Client (`client/src/client.gleam`)

### 1. Model: a separate spots cache

Add `spots: Dict(Uuid, Int)` to `Model` (init `dict.new()` at `client/src/client.gleam:631`). **Missing key = `Unknown`** — no `RemoteData` wrapper needed; an empty/stale dict naturally yields `Unknown` for anything not present.

### 2. Fetch spots on load and after mutations

- `init` fires a full `/api/activity-spots` fetch (alongside the existing statuses + default-tab fetches) → `ApiReturnedActivitySpots(Result(List(ActivitySpots), rsvp.Error))`. On success, **replace** the dict (`list.fold` into a fresh `dict`) so server-side deletions drop out. On error, leave the dict as-is (missing → `Unknown`; stale-but-known values stay shown).
- The single-activity endpoint `GET /api/activities/:id/spots` → `ApiReturnedActivitySpotsOne(Uuid, Result(Int, rsvp.Error))` (id carried in the message since the body is only the number). On success `dict.insert(spots, id, n)`; on error leave the dict untouched. This reads the **live total**, so it reflects bookings other users made concurrently. It fires in two situations:
  - **On opening the detail page.** In `OnRouteChange` → `uri_to_page` (`client/src/client.gleam:708`), the target `ActivityDetailPage(id, _)` (and `ActivityEditPage(id, _)`) already emits a lazy detail-fetch `page_effect`; `effect.batch` the single-activity spots fetch alongside it so the detail view always shows a fresh count on open — even if the activity was never in a browse list (so it's absent from the bulk `spots` dict) or the bulk fetch is stale. Fire it every open (the count is cheap and volatile); don't gate on "already in the dict".
  - **After a booking mutation**, refetch the affected activity's count, batched alongside each handler's existing `statuses`/`page` update:
    - `ApiCreatedBooking(Ok(b))` (`client/src/client.gleam:1136`) → refetch `b.activity_id`.
    - `ApiUpdatedBooking(Ok(b))` (`client/src/client.gleam:1173`) → refetch `b.activity_id`.
    - `ApiDeletedBooking(activity_id, _, Ok(_))` (`client/src/client.gleam:1206`) → refetch `activity_id`.

### 3. Render via the helper (replace the placeholders)

At each render site, look up the count and default missing to `None`:
`model.spots_remaining(max_attendees, dict.get(model.spots, id) |> option.from_result)`.

- **List card** (`client/src/client.gleam:1829`): replace the `mock_spots_remaining` branch. Map the `SpotsRemaining` result: `Unlimited` → no text (unchanged), `Remaining(n)` → the existing `activity.spots_remaining` plural label, `UnknownSpots` → a new `activity.spots_unknown` label.
- **Detail view** (`client/src/client.gleam:2054`): same mapping; drop the `// TODO`.
- Thread the count to the card renderer either by looking it up from `model.spots` in the view, or by resolving to `Option(Int)` when building `CardItem`s — whichever keeps signatures cleanest.
- **Delete `mock_spots_remaining`** (`client/src/client.gleam:2450`). Keep `id_seed` — still used by `mock_locations` / tag mocks.

### 4. Translations

Add `activity.spots_unknown` (sv: e.g. "Platser: okänt", en: "Spots: unknown") next to the existing `activity.spots_remaining.one/other` entries.

## Polling readiness (not built now)

The full-load path (`ApiReturnedActivitySpots`, dict-replace) is idempotent, so background polling later is just: a timer effect re-firing the same `/api/activity-spots` fetch on an interval. No shape changes needed — this plan only avoids designing anything that would block it. A scoped `GET /api/activity-spots?ids=a,b,c` (SQL `WHERE activity_id = ANY($1)`) is the natural next step if payload size ever matters; start with fetch-all.

## Files to modify

- `server/src/server/sql/list_activity_spots.sql` (new), `server/src/server/sql/get_activity_spots.sql` (new)
- `server/src/server/sql.gleam` (regenerated — do not hand-edit)
- `server/src/server/web/spots.gleam` (new)
- `server/src/server/router.gleam`
- `server/priv/static/openapi.yaml`
- `shared/src/shared/model.gleam`
- `client/src/client.gleam`

## Out of scope

- Booking-time capacity enforcement (rejecting an over-capacity booking server-side) — display only; a race can still oversell. Worth a follow-up.
- Interval / live polling (see *Polling readiness*) — enabled but not wired up.
- Per-user "your booked seats" vs. "total booked" — only the aggregate is shown.

## Verification

1. `cd server && gleam run -m squirrel` regenerates cleanly; `gleam format`; `gleam test` passes. `cd shared && gleam test` (helper). `cd client && gleam build && gleam format`.
2. `./seed.sh`, then `./start.sh`:
   - `GET /api/activity-spots` returns one entry **per activity** (including `spots_booked: 0` for activities with no bookings); a capped activity with bookings summing to `B` shows `max − B` on both its card and detail page, matching `SELECT SUM(participant_count) FROM booking WHERE activity_id = …`.
   - An activity with `max_attendees = NULL` shows no spots text (unlimited).
   - Booking more people than remain clamps to `0`, never negative.
   - Opening any activity's detail page fires exactly one `GET /api/activities/:id/spots` and shows a fresh count — including for an activity reached by direct URL that was never in a browse list.
   - Creating / editing / cancelling a booking updates the displayed count without a full reload, via the single-activity refetch.
   - **Unknown:** block the `/api/activity-spots` request (or start offline with activities cached) → capped cards render the "unknown" label, **not** "0 booked / full". A known-zero-booking activity (endpoint succeeded) still shows full availability, not unknown.
   - Two sessions: book the same activity in one, then mutate a booking in the other → the second session's count reflects **both** users' bookings.
   - `GET /api/docs` shows both new paths and the `ActivitySpots` schema.

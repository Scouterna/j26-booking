# 02. Normalized activity store + favourites endpoint

> **Status: ✅ Done** (verified 2026-07-02)
>
> Both server and client are implemented. Server: `list_favourited_activities.sql`,
> `activity.from_list_favourited_activities_row`, `activities.get_favourited`, and
> the `["favourited-activities"]` route all exist. Client: `RemoteData` gained
> `NotAsked`, the single `summaries` field was replaced by the entity `Dict` +
> per-tab id lists (`activities_ids`/`swim_bus_ids`/`climbing_wall_ids`/
> `favourited`), plus `ActivityListSource`, `ApiReturnedActivityList`, `hydrate`,
> and lazy per-tab fetching.

## Context

Today the client holds a single `summaries: RemoteData(List(ActivitySummary))` that is **swapped out** on every tab switch (`fetch_for_tab` refetches `/api/activities`, `/api/swim-bus-activities`, or `/api/climbing-wall-activities` and replaces the list). The Favourites tab refetches the full catalogue and filters client-side by `is_favourited`.

Two upcoming requirements break that model:

1. **Lazy loading** — tabs should load on first open and stay cached, not refetch on every switch.
2. **Date pagination of activities** — once the browse lists are paginated, the client only ever holds a *window*, so "Favourites = filter the loaded list" silently misses favourites outside the loaded pages.

The chosen architecture is a **normalized entity cache**: one `Dict(Uuid, ActivitySummary)` hydrated (overwrite-on-overlap) by *every* response, plus per-browse-tab **ordered id lists** that define each tab's membership/order. Favourites is **derived**, not stored: `/api/statuses/me` already returns the user's *complete* favourited∪booked id set at init, so the only missing piece is summary data for favourites the user hasn't browsed to — supplied by a new `GET /api/favourited-activities`.

This removes the two weaknesses of per-tab summary lists: duplication of overlapping items (a swim-bus slot appears in the Activities and Swim bus tabs) and N places to keep in sync on mutation.

### Load-bearing assumption

`/api/statuses/me` returns the **complete, unpaginated** set of the user's booked/favourited activity ids (confirmed in `server/src/server/web/status.gleam` — it folds all bookings + favourites into one list). Favourites correctness depends on this. If statuses is ever paginated, Favourites would need its own paginated list again. Document this with a comment at the favourites derivation site.

## Server

### New query `server/src/server/sql/list_favourited_activities.sql`

Activity rows for the current user's favourited **or** booked activities (matches the Favourites tab's favourited∪booked semantics; mirrors the union in `status.get_mine`):

```sql
SELECT DISTINCT activity.*
FROM activity
WHERE activity.id IN (SELECT activity_id FROM favourite WHERE user_id = $1)
   OR activity.id IN (SELECT activity_id FROM booking WHERE user_id = $1)
ORDER BY activity.start_time ASC;
```

Run `gleam run -m squirrel` then `gleam format`. Generates `ListFavouritedActivitiesRow` (carries `recurring_activity_kind`, ignored by the converter, same as the other `SELECT *` lists).

### `server/src/server/model/activity.gleam`

Add `from_list_favourited_activities_row(row: sql.ListFavouritedActivitiesRow) -> Activity`, mirroring `from_list_activities_by_start_time_row`.

### `server/src/server/web/activities.gleam`

Add `get_favourited`, resolving the user with the existing `web.with_authenticated_user(ctx)` helper (same pattern as `status.get_mine`), then returning slim summaries via the existing `response_from_db_activity_summaries` helper:

```gleam
pub fn get_favourited(req: Request, ctx: web.Context) -> Response {
  use <- wisp.require_method(req, Get)
  use user_id <- web.with_authenticated_user(ctx)
  response_from_db_activity_summaries(
    sql.list_favourited_activities(ctx.db_connection, user_id),
    activity.from_list_favourited_activities_row,
  )
}
```

### `server/src/server/router.gleam`

Top-level route (no collision with `["activities", id]`, consistent with the swim-bus/climbing-wall endpoints):

```gleam
Get, ["favourited-activities"] -> activities.get_favourited(req, ctx)
_, ["favourited-activities"] -> wisp.method_not_allowed([Get])
```

### `server/priv/static/openapi.yaml`

Add `GET /api/favourited-activities` → `200` with `{ "activities": [ActivitySummary] }` (reuse `ActivitySummary`; auth-scoped, no params). Required by `server/CLAUDE.md`.

## Client (`client/src/client.gleam`)

### 1. `RemoteData` gains `NotAsked`

Lazy loading needs to distinguish "never fetched" from "in flight":

```gleam
type RemoteData(a) {
  NotAsked
  Loading
  Loaded(a)
  Failed(String)
}
```

Update the few exhaustive matches: `map_loaded` (treat `NotAsked` like `Loading`/`Failed` — return unchanged) and `view_activities_list` (render `NotAsked` with the same spinner as `Loading`).

### 2. Model: entity cache + per-browse-tab id lists

Replace the single `summaries` field:

```gleam
type Model {
  Model(
    page: Page,
    translator: Translator,
    // Entity cache: one copy per activity, hydrated/overwritten by EVERY
    // response (browse pages, swim-bus, climbing-wall, favourited, detail fetches).
    activities: Dict(Uuid, ActivitySummary),
    // Ordered id windows per browse tab — define membership + order.
    activities_ids: RemoteData(List(Uuid)),
    swim_bus_ids: RemoteData(List(Uuid)),
    climbing_wall_ids: RemoteData(List(Uuid)),
    // Drives the Favourites tab's /api/favourited-activities fetch state +
    // hydration. Membership is derived from `statuses`, not from this list.
    favourited: RemoteData(List(Uuid)),
    // Full per-user status map, fetched whole at init (complete, unpaginated).
    statuses: Dict(Uuid, ActivityStatus),
    details: Dict(Uuid, RemoteData(Activity)),
  )
}
```

Add a hydrate helper used by every list response:

```gleam
fn hydrate(store: Dict(Uuid, ActivitySummary), items: List(ActivitySummary)) -> Dict(Uuid, ActivitySummary) {
  list.fold(items, store, fn(acc, s) { dict.insert(acc, s.id, s) })
}
```

### 3. Tagged fetch message + source enum

Replace the ambiguous `ApiReturnedSummaries(Result(...))`:

```gleam
type ActivityListSource { SourceActivities SourceSwimBus SourceClimbingWall SourceFavourites }

// Msg
ApiReturnedActivityList(ActivityListSource, Result(List(ActivitySummary), rsvp.Error))
```

`fetch_list(source)` maps source → URL (`/api/activities`, `/api/swim-bus-activities`, `/api/climbing-wall-activities`, `/api/favourited-activities`) and tags the response. On success: `hydrate` the dict with the items **and** set that source's id-list `RemoteData` to `Loaded(ids)`; on error, `Failed`.

### 4. Lazy fetch on tab select

`UserSelectedTab` (currently sets `summaries: Loading` + `fetch_for_tab`) becomes: update `filters.tab`; if the target source's `RemoteData` is `NotAsked`, set it `Loading` and fire `fetch_list(source)`; otherwise no I/O (instant, cache-backed). `UserClickedRetryLoad` refetches the current tab's source.

`init` fetches `statuses` (as today) and the `SourceActivities` list (default tab). The other sources start `NotAsked` and load on first open.

### 5. Favourites derivation

- **Membership = `statuses` filtered to favourited/booked** (`is_favourited`) — complete and live; an unfavourite flips the status and the item drops instantly.
- `favourited` (the `/api/favourited-activities` fetch) exists to **hydrate the dict** with summaries the user hasn't browsed to, and to drive the **loading/error state** of the tab.
- Render set = favourited/booked ids from `statuses`, looked up in the `activities` dict, sorted by start_time (or just hand to `group_by_date_bucket`, which re-sorts). **Skip ids whose summary isn't in the dict yet**, and show the spinner while `favourited` is `Loading`/`NotAsked`.
- **Invalidate on favourite/booking add:** when a favourite is added or a booking is created, reset `favourited` to `NotAsked` so the next Favourites open lazily refetches and hydrates the newly-relevant summary. Removals need no refetch (the status filter drops them).

### 6. View

- `view` passes the **resolved summaries for the current tab** into `view_activities_list`: for browse tabs, map the tab's id-list through the `activities` dict (dropping any missing id); for Favourites, the derived set from step 5. Carry the tab's `RemoteData` state through for the spinner/error/empty rendering.
- `to_card_items(items, statuses)`, `apply_filters`, `camp_dates`, `group_by_date_bucket` are reused. `camp_dates` now runs over the current tab's resolved summaries (same as today).
- **`apply_filters` drops the `is_favourited` branch** (line ~2374): status/membership is handled by the source selection now, so every tab is pass-through on status; search + day filters remain client-side. `is_favourited` stays (used for badges / favourites membership) but leaves the list filter.

### 7. Mutations → one update point

`upsert_summary`/`remove_summary` on the single list (create/update/delete handlers) become operations on the `activities` dict:

- **create / update**: `dict.insert(activities, a.id, to_summary(a))`; for **create**, also append the id to `activities_ids` (the all-list window) so it shows immediately. Special-tab id-lists can't be classified client-side (kind is server-internal) → reset `swim_bus_ids`/`climbing_wall_ids` to `NotAsked` on create so they refetch on next open.
- **delete**: `dict.delete` from `activities`; remove the id from every id-list; `dict.delete` from `statuses` and `details`.
- **favourite toggle / booking change**: update `statuses` (as today) — Favourites re-derives automatically; reset `favourited` to `NotAsked` on *add* (step 5).

### 8. Keyed day-select stays

Switching tabs still changes the rendered list, so the existing `keyed.div` around `scout-select` (keyed by date set) remains necessary and unchanged.

## Files to modify

- `server/src/server/sql/list_favourited_activities.sql` (new)
- `server/src/server/sql.gleam` (regenerated — do not hand-edit)
- `server/src/server/model/activity.gleam`
- `server/src/server/web/activities.gleam`
- `server/src/server/router.gleam`
- `server/priv/static/openapi.yaml`
- `client/src/client.gleam`

## Out of scope / deferred

- **Date pagination** itself — this plan only makes the store *ready* for it (entity dict + per-tab id windows); appending pages is a later change.
- **Exposing `recurring_activity_kind`** — stays server-internal; the special tabs still rely on their dedicated endpoints.
- **Unifying `details` into the entity cache** — possible follow-up (a detail is a richer entity for the same id), not needed now.

## Verification

1. `cd server && gleam run -m squirrel` regenerates cleanly; `gleam format`; `gleam test` passes (existing converters unaffected by the new `SELECT *` column).
2. `GET /api/favourited-activities` returns the current user's favourited∪booked slots as summaries; `GET /api/docs` shows the new path.
3. `cd client && gleam build` + `gleam format`.
4. `./dev.sh` (or `./start.sh`): 
   - First open of each tab triggers exactly one fetch; switching back is instant (no network).
   - Swim bus / Climbing wall show only their slots; Activities shows the full list.
   - Favourites shows all favourited **and** booked items across all three kinds — including a favourited swim-bus slot that was never browsed (proves `/api/favourited-activities` hydration + statuses membership).
   - Unfavouriting an item on the Favourites tab drops it immediately (no refetch); favouriting a new item elsewhere then opening Favourites shows it (lazy refetch).
   - No console reconciler errors; day dropdown has no duplicate options.

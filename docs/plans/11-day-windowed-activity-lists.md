# 11. Day-windowed activity lists

> **Status: ✅ Done 2026-07-17** (branch `feat/activity-list-etag`; see
> "Divergences from the plan" below)

## Divergences from the plan

- **Shared:** added a dedicated `shared/event.gleam` (the option the plan
  offered) rather than growing `model.gleam`. It also owns the ISO date
  `date_to_iso`/`date_from_iso` helpers so client and server share one `?day=`
  format.
- **Timezone (the load-bearing risk):** confirmed `activity.start_time` stores
  **UTC wall-clock** (the API round-trips it through unix instants; a naive
  `2026-07-26 08:00` reads back as that instant in UTC). The whole event window
  sits in CEST, so the server uses a **fixed +2h** Stockholm offset (no tz
  database, no DST edge) in one `day_bounds` helper, unit-tested around 25/7
  (`server/test/server/web/activities_test.gleam`). The client already buckets
  and displays by the browser's local offset, which is this same offset on-site,
  so server windows and client display agree.
- **Server `?day=`:** a valid but out-of-range date is **clamped** into the
  event range (the client only ever offers in-range dates); only a *malformed*
  value is a `400`.
- **Client window store:** `windows: Dict(WindowKey, RemoteData(List(Uuid)))` +
  `etags: Dict(WindowKey, String)` with `WindowKey = #(source, Option(day),
  include_call_offs)`, plus a new `Model.today` (clamped) for the browse default.
  `default_filters().day` stays `None`; browse resolves the effective day as
  `filters.day |> unwrap(today)` (so `today` isn't threaded into
  `default_filters`). `today` is read once at init via the existing
  `timestamp.system_time()` (no new FFI needed).
- **Shared `filters.day` across tabs:** a tab switch resets the day to that
  tab's default — Favourites → all-days (`None`), browse↔browse keeps the picked
  day, leaving Favourites → today.
- **`apply_filters` day branch:** kept but scoped to **Favourites only** (its
  optional day pick filters client-side); browse tabs rely on the server window.
- **`ApiCreatedActivity`:** drops all browse windows (can't map a new activity's
  day/kind to one window); the dead `prepend_id` helper + its tests were removed.
- **Seed data:** the seed activities were dated 2025-07-11…16, a year+ before
  the event window, so browse lists were empty. Remapped them `+379 days` to
  2026-07-25…30 (`server/priv/seeding/activities.sql`) and shifted the existing
  dev-DB rows to match.

Verified end-to-end (server curl + Playwright): static 25/7–1/8 dropdown with no
"all days" on browse (defaults to clamped-today 25/7), per-day fetch with `304`
on revisit, Favourites defaults to "all days" and spans days, called-off rows
hidden by default and shown with the manager superset, Stockholm-local times and
cross-midnight grouping intact. Tests: shared 5, server 35, client 76.

## Original plan

## Context

Today the browse lists are fetched **whole** and sliced by day **client-side**:
`filters.day: Option(calendar.Date)` (`client.gleam:529`, `None` = "all days"),
the day dropdown is built from `camp_dates(items)` — dates **derived from the
loaded data** (`client.gleam:2871`, `4537`) — and `apply_filters` filters the
loaded list (`client.gleam:4509`). The server returns every activity in one
response.

This plan moves to **day windows**: each browse fetch returns a single day, the
day is chosen from a **fixed** set of event dates, and the client defaults to
today clamped into the event range. It builds directly on plan 09 (ETag
revalidation) — the day becomes part of the fetch identity, so each day's
window is cached and revalidated independently.

### Fixed event dates

The Jamboree runs **25 Jul – 1 Aug 2026** (Fri 25/7 … Fri 1/8), **8 days**.
These are hard-coded, not derived from data.

### Requirements settled with the user

- The day dropdown shows a **static** list of the 8 event dates (25/7–1/8), not
  a data-derived set.
- **No "all days" option** on the Activities / Beach bus / Climbing wall tabs —
  each always shows exactly one day, defaulting to the clamped "today".
- **Favourites keeps "all days", and "all days" is its default** — the
  favourites view shows everything by default; picking a day is optional there.

### Decisions carried over (from the earlier design discussion)

- **Scope:** Activities + the two recurring tabs are day-windowed; Favourites is
  all-days.
- **Default day:** clamp today into `[25/7, 1/8]` (before the event → 25/7;
  after → 1/8; during → today). "Now" is before the event, so the default is
  **25/7**.
- **Timezone:** day boundaries are computed in **`Europe/Stockholm`** (see the
  risk note — `activity.start_time` is a naive `TIMESTAMP`).

---

## 1. Shared — one source of truth for the event dates

Add to `shared/src/shared/model.gleam` (or a small `shared/event.gleam`):

- `event_first_day` / `event_last_day` constants (`2026-07-25`, `2026-08-01`).
- `event_days() -> List(calendar.Date)` — the 8 dates in order.
- `clamp_to_event(date) -> calendar.Date` — clamp any date into the range.

Both client (dropdown, default, clamp) and server (param validation) use these,
so the range is defined once. Keep them in `shared` because both targets need
them.

---

## 2. Server — window each browse query by day

### SQL (`server/src/server/sql/`)
Add a day window to `list_activities_by_start_time`, `list_activities_by_title`,
`list_beach_bus_activities`, `list_climbing_wall_activities` alongside the
existing `include_call_offs` param (plan 09):

```sql
WHERE recurring_activity_kind IS NULL
  AND ($1 = TRUE OR NOT EXISTS (SELECT 1 FROM call_off c WHERE c.activity_id = activity.id))
  AND start_time >= $2 AND start_time < $3
ORDER BY start_time ASC;
```

`$2`/`$3` are the `[day_start, day_end)` **instants** for the requested date.
`list_favourited_activities` is **unchanged** (all days). Regenerate `sql.gleam`.

### Handler (`server/src/server/web/activities.gleam`)
- Add a `with_day` helper mirroring `with_include_call_offs`: parse `?day=YYYY-MM-DD`,
  **default to `clamp_to_event(today)`**, reject a malformed value with 400, and
  clamp/validate against the event range. Hand the handler the resolved date.
- Compute `[day_start, day_end)` from the date **in `Europe/Stockholm`** and pass
  the two instants to the query. Compose with `include_call_offs` and route the
  response through `web.json_response_with_etag` (plan 09) — the ETag now covers
  a single day, so it changes only when that day changes.
- `get_favourited` takes **no** day param.

> **⚠️ Timezone — the load-bearing risk.** `activity.start_time` is a naive
> `TIMESTAMP` (migration `20250905210402-initial.sql`), but the API writes it
> from an absolute unix instant (`timestamp.from_unix_seconds`). **Before
> writing the query, confirm what the stored value represents** (UTC wall-clock
> vs local): a quick `SELECT start_time FROM activity WHERE id = <known>` against
> a known unix time tells you. Then compute `day_start`/`day_end` as the instants
> for Stockholm **local** midnight of the date, expressed in whatever the column
> stores, so an activity at 23:30 local lands on the right day and "today" flips
> at local — not UTC — midnight. Put this conversion in one helper and unit-test
> it around a DST-agnostic summer date (Stockholm is UTC+2 in late July).

### No distinct-days endpoint needed
Because the dates are fixed, the client already knows the full day set — so,
unlike the earlier sketch, **no `SELECT DISTINCT day` query/endpoint is
required**. Empty days simply return `{"activities": []}` (still ETag-cacheable).

### OpenAPI (`server/priv/static/openapi.yaml`)
Add the `day` query parameter (date, defaults to clamped-today, 400 on malformed)
to the three day-windowed list endpoints; note favourited ignores it.

---

## 3. Client — static dropdown, per-day windows, favourites default

### Fetch identity gains the day
Plan 09 keys the ETag store by `#(source, include_call_offs)` and the id-window
by `source`. Both now gain the day. Recommended: a single window store

```gleam
windows: Dict(WindowKey, RemoteData(List(Uuid)))
etags:   Dict(WindowKey, String)
// WindowKey = #(ActivityListSource, Option(calendar.Date), Bool)
//   day = Some(date) for the day-windowed tabs, None for Favourites (all days)
//   Bool = include_call_offs (plan 09)
```

Replacing the flat per-source fields (`activities_ids`, `beach_bus_ids`, …) with
this dict is the **main refactor** — update `source_remote`/`set_source_remote`
(and their view/`update` call sites) to take the full key. `fetch_list` appends
`?day=` (and keeps `?include_call_offs=`), and `load_or_revalidate` runs per key,
so switching **days** revalidates exactly like switching tabs does today (cheap
`304` on revisit).

### Day dropdown (`view_day_select`, `client.gleam:2950`)
- Feed it `shared.event_days()` instead of `camp_dates(items)` — the list is
  static, so drop `camp_dates` and the data-derived `dates`.
- **Activities / Beach bus / Climbing wall:** render **no** "all days" option;
  the selection defaults to `clamp_to_event(today)`.
- **Favourites:** render the "all days" option and default the selection to it.
- Because the option set is now fixed, the content-derived `keyed` wrapper
  (`client.gleam:2905-2909`) can key on the tab/day instead of the date set.

### Filters & default (`ListFilters.day`, `default_filters`)
- `default_filters()` should yield the browse default day
  (`Some(clamp_to_event(today))`). Favourites presents "all" (None) — since
  `filters.day` is shared across tabs, resolve the **effective** day per tab at
  fetch/render time: day-windowed tabs use `filters.day` (falling back to the
  clamped default if None); Favourites always fetches all days regardless of
  `filters.day`.
- `UserSelectedDay(day)` (`client.gleam:1835`) now also triggers a fetch of the
  newly selected `(source, day, include_call_offs)` window via
  `load_or_revalidate`, not just a filter update.

### Drop client-side day filtering
With the server scoping to one day, remove the day branch from `apply_filters`
(`client.gleam:4509`) for the day-windowed tabs — the response already contains
only that day. Keep the **within-day** grouping (morning/afternoon/evening
sections, cross-day intervals) — that still applies to a single day's list.

### Getting the "today" date
`calendar` needs the current date from the runtime. Add a tiny effect/FFI to
read today's date once at init (or reuse whatever already provides the clock),
clamp it, and seed `default_filters`. Note this is the one impure input — keep
it at the edge.

---

## Verification

1. **Server:** `gleam format && gleam test`. `curl` a day-windowed endpoint:
   `?day=2026-07-26` returns only that day; a called-off activity on that day is
   absent by default and present with `include_call_offs=true` (manager);
   `?day=bogus` → 400; the ETag differs per day and `If-None-Match` → 304.
   Verify the **timezone**: an activity seeded at 23:30 Stockholm on 25/7 shows
   under `day=2026-07-25`, not 26.
2. **Client:** `gleam test`; build the bundle **to `server/priv/static`**
   (`gleam run -m lustre/dev build --minify --outdir=../server/priv/static`, per
   `start.sh`).
3. **Browser (`./start.sh`-style run):**
   - Activities/Beach bus/Climbing wall show a static 25/7–1/8 dropdown with **no
     "all days"**, defaulting to 25/7 (clamped); changing day fetches that day
     (200 first time, 304 on revisit).
   - Favourites shows "all days" **selected by default** and lists across days.
   - A manager sees called-off activities in the manage list for the chosen day.

## Notes / risks

- **Timezone (see §2)** is the highest risk — get the boundary math and the
  column's meaning right, with a unit test.
- **Window-store refactor (§3)** touches every `source_remote`/`set_source_remote`
  call site; mechanical but wide — grep for both plus the flat window fields.
- **Shared `filters.day` across tabs:** resolving the effective day per tab (and
  Favourites ignoring it) avoids adding per-tab day state; revisit if it gets
  fiddly.
- **Composes with plan 09:** day is added to the existing `(source,
  include_call_offs)` key, not a parallel mechanism — one fetch path, one ETag
  per `(source, day, include_call_offs)`.
- **Deep links / bookmarks:** consider whether `?day=` should live in the client
  URL so a shared link opens the right day. Out of scope unless wanted.
```

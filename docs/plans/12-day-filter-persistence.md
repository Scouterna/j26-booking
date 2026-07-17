# 12. Persist the day filter across navigation + independent Favourites day

> **Status: ✅ Done 2026-07-17** (branch `feat/day-windowed-activity-lists`;
> implemented as designed — the day is lifted onto `Model` as
> `browse_day_filter` / `favourites_day_filter`, `window_key_for` drops its
> `filters` param, and `apply_filters` takes an explicit client-side day. Both
> Playwright repros pass; client 80 / shared 5 / server 35 tests green.)

## Context

Issue [#40](https://github.com/Scouterna/j26-booking/issues/40): "The date filter
is reset after navigating away from the list page." Two asks:

1. The selected **day** is lost when you leave the list page (to an activity
   detail, or any non-list page) and come back — you must reselect it.
2. **Favourites** should have its **own** day state, so it can sit on "all days"
   while the browse tabs stay on a specific day.

Reproduced with Playwright on top of plan 11:

- Pick day 26/7 on Aktiviteter → open an activity → browser Back → the day is
  back to 25/7 ("No activities yet").
- Pick day 27/7 on Aktiviteter → switch to Favoriter (shows "all days") → switch
  back to Aktiviteter → the day is back to 25/7.

**Root cause** (introduced in plan 11): the list filters, including `day`, live
inside `ActivitiesListPage(filters: ListFilters, mode)` (`client.gleam:625`).
`uri_to_page` (`:2988`) rebuilds every list page from `default_filters()`
(`:2994`, `:3005`), so any navigation discards the day. And `day` is a single
shared field, so browse and Favourites can't hold different days — the current
code papers over this with a reset-on-tab-switch in `UserSelectedTab`
(`:1868`), which is exactly what loses the browse day when visiting Favourites.

## Approach — lift the day out of the page into the Model, split per view

Keep the rest of `ListFilters` (search, tab, tags, target groups, more_open) in
the page as-is; move **only the day** to the `Model` as **two** fields, so it
survives page rebuilds and each view remembers its own day. This is the minimal
change that satisfies both asks.

### Model (`client/src/client.gleam`)
- Add to `Model` (near the existing `today`, `:~671`):
  - `browse_day_filter: Option(calendar.Date)` — the day shared by Aktiviteter /
    Badbuss / Klättervägg. `None` resolves to `today` (browse has no "all days").
  - `favourites_day_filter: Option(calendar.Date)` — Favourites' own day. `None`
    = "all days" (its default).
- Remove `day` from `ListFilters` (`:543`) and from `default_filters()` (`:564`).
- Init (`:1287`): seed both new fields to `None`. `Model.today` already exists.

### Effective-day resolution
- Add a helper `effective_day(model, tab) -> Option(calendar.Date)`:
  - Favourites → `model.favourites_day_filter`
  - browse tabs → `Some(option.unwrap(model.browse_day_filter, model.today))`
- `window_key_for` (`:~795`) currently reads `filters.day`; derive the day from
  the Model fields via the source instead (Favourites → `favourites_key()`
  all-days; browse → the resolved browse day). It no longer needs `filters` —
  update its call sites: OnRouteChange (`:1425`), `ApiReturnedMe` (`:1527`),
  `UserClickedRetryLoad` (`:2105`), `UserSelectedTab`/`UserSelectedDay`.

### Update handlers (`client/src/client.gleam`)
- `UserSelectedDay(d)` (`:~1895`): write `d` to `browse_day_filter` **or**
  `favourites_day_filter` depending on the current tab (from the page's
  `filters.tab`), then `load_or_revalidate` the resolved window key. (Replaces
  the current `update_filters(day:)`.)
- `UserSelectedTab` (`:1868`): **remove** the day-reset block added in plan 11 —
  each tab now reads its own persistent day, so switching tabs just changes the
  tab and revalidates the resolved window.
- No change to `uri_to_page` / `OnRouteChange` for persistence: with the day out
  of the page, rebuilding the page no longer touches it.

### View (`client/src/client.gleam`)
- `view_list_top_bar` (`:~3196`): compute `show_any` (Favourites only) and the
  dropdown's `selected_day` from the Model fields via `effective_day`, instead of
  `filters.day`. It already receives `today`; pass the two day fields (or the
  whole model) through the `view_activities_list` (`:3072`) call chain.
- Client-side Favourites day filter: `apply_filters` (`:5054`) currently reads
  `f.day`. Thread the effective client-side day (`favourites_day_filter` when the
  tab is Favourites, else `None`) from `view_grouped_activities` (`:3517`, called
  `:3175`) into `apply_filters` as an explicit `Option(Date)` arg. Browse tabs
  stay server-windowed (pass `None`).

### Tests (`client/test/client_test.gleam`)
- Update `base_model` (`:~136`): drop `day` from filters, add
  `browse_day_filter`/`favourites_day_filter`; fix the day-related tests
  (`apply_filters`, `UserSelectedDay`, tab-switch).
- Add regressions for the issue:
  - `UserSelectedDay` on a browse tab sets `browse_day_filter` and leaves
    `favourites_day_filter` untouched (and vice versa).
  - The day survives a page rebuild: set `browse_day_filter`, dispatch
    `OnRouteChange` to a detail page and back to the list, assert the resolved
    browse window / dropdown still uses the chosen day.
  - Effective day: Favourites resolves to `favourites_day_filter` (all-days by
    default) while browse resolves to `browse_day_filter`/today, independently.

## Out of scope

- Persisting tab / search / tag / target-group filters across navigation (the
  issue is specifically about the date filter; today they reset on navigation and
  will continue to).
- Putting `?day=` in the client URL for deep links (a plan 11 "future idea").

## Verification

1. `cd client && gleam test` (incl. new regressions); `cd shared && gleam test`;
   `cd server && gleam test` (no server change; confirm green). `gleam format`
   each package.
2. Rebuild the bundle to the server dir (per `start.sh`):
   `cd client && gleam run -m lustre/dev build --minify --outdir=../server/priv/static`.
3. Run the app (server on :8000 with `DATABASE_URL=…5433`, `DEV_AUTH_ROLES=admin`)
   and re-run the Playwright repro:
   - Aktiviteter → pick 26/7 → open an activity → Back → **still 26/7** with its
     activities.
   - Pick 27/7 on Aktiviteter → Favoriter shows **"all days"** → back to
     Aktiviteter → **still 27/7**. Changing the Favourites day doesn't change the
     browse day, and vice versa.
   - Confirm per-day `304` revalidation still fires on revisit (network panel).

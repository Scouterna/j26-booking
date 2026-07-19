# 20. "Alla dagar" on the browse tabs — search across the whole week

> **Status: ✅ Done 2026-07-19** (commit `7517bc7`; solution B of three
> candidates — a comparison implementation of solution A was built on a
> temporary branch and discarded. Late scope refinement: "Alla dagar" is
> offered only on Aktiviteter + Favourites; Badbuss/Klättervägg stay
> single-day and snap the shared day to today.)

## Context

Issue [#49](https://github.com/Scouterna/j26-booking/issues/49): search only
matches within the selected day, so you must already know when an activity
happens to find it. Fix: reintroduce the "Alla dagar" option on the browse
tabs (Aktiviteter / Badbuss / Klättervägg — and the manage list, which shares
them), **not** as the default selection. Search is client-side over the loaded
window (`apply_filters`), so once the view spans the whole event, search does
too.

Builds on plans 11 (day-windowed lists) and 12 (day lifted onto the Model as
`browse_day_filter` / `favourites_day_filter`).

## Design — chosen from three candidates

Three shapes were considered (see also the comparison branch
`feat/all-days-solution-a`, built for evaluation):

- **A** — server accepts "no day" = whole event range; client seeds the eight
  per-day windows from the one all-days response (needs client-side Stockholm
  day-bucketing; seeded windows lack ETags).
- **B (chosen)** — **the API stays per-day only; the client fans out the eight
  per-day window fetches and unions them.** Every window is a real per-day
  window with its own ETag, so the all-days view composes perfectly with the
  existing cache (days already visited render from cache; revisits are eight
  cheap 304s), and the server remains the only authority on day boundaries.
- **C** — server all-days window, no seeding (simplest; one extra fetch when
  narrowing to a day).

Decisions settled with the user:

1. **Partial failure** (some of the eight fail): render the days that loaded
   **plus a warning banner** ("some days could not be loaded") with a retry —
   never a silent gap, since that would hide search matches, the very bug this
   issue is about. Only when *nothing* loaded does the whole view show the
   error state.
2. **Loading**: one spinner until **all eight windows settle** (Loaded or
   Failed) — search must not run over a half-loaded week. Fully-cached
   revisits render instantly and revalidate in the background as usual.
3. **Retry** refetches **all eight**: failed/unloaded windows flip to Loading
   and fetch; loaded windows revalidate conditionally (mostly 304s).
4. **"Alla dagar" is transient**: re-entering a list page (route change)
   resets the browse day to today, so users don't unknowingly stay in the
   eight-request mode. A picked concrete day still persists (issue #40).
5. **Only Aktiviteter (and Favourites) get "Alla dagar"** — the recurring
   tabs (Badbuss / Klättervägg) stay strictly single-day. Because the browse
   day is shared across tabs, switching to a recurring tab while on all-days
   snaps the day to today (consistent with decision 4). This also brings back
   the keyed `scout-select` replacement across tab boundaries (the option set
   differs again).

## Changes (client only — no server/API change)

All in `client/src/client.gleam` (+ tests):

- `browse_day_filter` semantics: `None` now means "Alla dagar"; `init` seeds
  it `Some(today)` so the default stays today. The `Model.today` field's only
  job was the lazy default — removed (route-change reset recomputes today via
  the existing `today()` helper, clamped).
- `window_key_for` → **`window_keys_for`** returning a list: Favourites → its
  one all-days key; browse → one per-day key, or all eight on "Alla dagar".
  `load_or_revalidate_all` / `fold_windows` / `retry_window` run per-window
  steps over a view's keys.
- `tab_summaries` now returns a dedicated **`ListLoad`** type (`ListLoading` /
  `ListFailed` / `ListLoaded(summaries, failed_days)`) instead of
  `RemoteData`, implementing decisions 1–2; `view_activities_list` renders the
  partial-failure banner (`list.partial_days_failed`, sv+en) above the list
  when `failed_days` is non-empty.
- Dropdown: `view_day_select` always renders "Alla dagar" (`list.day.any`);
  the `keyed.div` hack that replaced the select when the option set flipped
  across the Favourites boundary is obsolete (the set is constant now).
- `OnRouteChange`: entering a list page with `browse_day_filter == None`
  resets it to `Some(clamp_to_event(today()))` (decision 4).
- Favourites behavior unchanged (its day pick still narrows client-side; a
  concrete pick still moves the browse day along).

## Verification

1. `gleam test` + `gleam format` in server, client, shared — all green
   (client 109 / shared 11 / server 63).
2. `./start.sh`, then in the browser: browse tab defaults to today; picking
   "Alla dagar" fires the eight per-day requests and renders the grouped
   whole week; search matches activities on other days; picking a day narrows
   instantly (cached window); leaving to a detail page and back resets to
   today; Favourites unchanged.

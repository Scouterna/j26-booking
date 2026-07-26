# 26. Activity-list filters live in the URL (Back restores them)

> **Status: ✅ Done 2026-07-26** (on `main`; implemented as designed. Client 146
> tests green, plus a jsdom harness driving the real mounted app: day / tab /
> search land in the URL, add no history entries, and Back restores the filtered
> list and the Badbuss overview day. Closes issue #45 — the remembered tab is one
> of the filters this puts in the URL.)

## Context

Filter the list (tab, day, search, målgrupp, tags, locations), open an activity,
press browser Back — every filter is gone. Same on the Badbuss / Klättervägg
overview pages: pick Sunday, open a slot, Back, and you're on today again.

Cause: only the **day** survives navigation (plan 12 lifted
`browse_day_filter` / `favourites_day_filter` onto `Model`). Everything else
lives in `ActivitiesListPage(filters)` / `ManageActivitiesPage(filters, _)`, and
`uri_to_page` rebuilds those from `default_filters()` on every route change —
so a route change is a filter reset. The overview day lives in
`RecurringBookingsPage(kind, day)` and is likewise rebuilt as "today".

Back can only restore what the history entry carries, so the fix is to put the
filters **in the URL** and treat the URL as their source of truth.

## Approach — filters are query params, written with `modem.replace`

```
/_services/booking/activities?tab=beach-bus&day=2026-08-02&q=kanot
                             &audience=scout&tags=<uuid>,<uuid>&locations=<uuid>
/_services/booking/activities/manage?…            (same params)
/_services/booking/beach-bus?day=2026-08-02       (overview: day only)
```

- **`replace`, not `push`.** A filter tweak overwrites the current history entry
  instead of adding one, so Back still leaves the list in one press — it just
  finds the entry stamped with the filters that were on screen.
- **One direction of data flow.** Filter messages *only* emit
  `modem.replace(path, query)`. `modem` dispatches `OnRouteChange` for its own
  replaces, so the existing route handler applies the new filters and fires the
  usual `revalidate_current_list` / `revalidate_current_overview`. No dual
  write, no state that can drift from the URL.
- **Day stays on the `Model` too.** The URL pins it for Back; the `Model` field
  keeps plan 12's behaviour that a *paramless* navigation (a nav-bar link back
  to the list) still remembers the picked day. URL wins when the param is there.

### Parameters

| Param | Value | Omitted when |
| ----- | ----- | ------------ |
| `tab` | `activities` \| `beach-bus` \| `climbing-wall` \| `favourites` | never (list pages) |
| `day` | `YYYY-MM-DD` \| `all` | never (list + overview pages) |
| `q` | free-text search | empty |
| `audience` | comma-joined `target_group_to_string` | empty |
| `tags` | comma-joined tag uuids | empty |
| `locations` | comma-joined location uuids | empty |

`day` is always written because its default ("today") moves with the clock —
pinning it keeps a restored view identical. Unparseable values fall back to the
default rather than 404-ing (a hand-edited URL should still show a list).

### View state stays out of the URL

`more_open` (advanced-filter panel) and the manage page's `activity_form` drawer
are pure view state. `inherit_view_state` carries them across a URL-driven
rebuild of the *same* list page, so a filter change doesn't slam the panel or
the drawer shut; a real navigation to another screen still drops both. On a
fresh entry (Back from a detail page), `more_open` is derived: the panel opens
itself when the restored URL has advanced filters active, so the user can see
why the list is narrowed.

`list_warning_dismissed` likewise survives a filter-only update, and resets when
the tab or day changes (a fresh fetch is a fresh attempt).

## Changes (`client/src/client.gleam`)

1. **Encode/decode** (ROUTING section): `DayQuery` (`DayUnset` / `DayAll` /
   `DayOn`), `list_query`, `overview_query`, `filters_from_query`,
   `day_from_query`, `tab_to_slug` / `tab_from_slug`, `filterable_path` /
   `recurring_path`.
2. **`uri_to_page`**: list pages parse `filters_from_query(uri)` instead of
   `default_filters()`; the overview pages parse the day (default: today
   clamped into the event).
3. **`OnRouteChange`**: `inherit_view_state`, `apply_day_query` (replacing the
   inline "Alla dagar is transient" snap, which now only applies when the URL
   carries no `day`), conditional `list_warning_dismissed` reset.
4. **Handlers → `modem.replace`**: `UserSearchedActivities`, `UserSelectedTab`,
   `UserSelectedDay`, `UserToggledTargetGroup`/`UserToggledTag` (list branch),
   `UserToggledLocationFilter`, `UserSelectedOverviewDay`. Their model
   mutations and fetch calls move into the route handler.
   `UserToggledMoreFilters` keeps writing the `Model` directly (it is view
   state, and a same-URL replace couldn't toggle it).
5. **`init`**: seed the day fields from the URL via `apply_day_query` and load
   the active tab's windows with `revalidate_current_list` instead of the
   hardcoded `#(SourceActivities, Some(today), False)` key — so a deep link like
   `?tab=beach-bus&day=…` fetches the right window on a cold load.

## Risks / notes

- **Shell mirroring.** The iframe posts `j26:navigate` on every route change,
  including these replaces; j26-app's `IframeRouter` mirrors it with
  `navigate({ replace: true })`, so no extra shell history entries. The query
  string rides through TanStack's `_splat` param, which may percent-encode `?`
  in the *shell's* address bar — cosmetic, but verify in the shell.
- **`replaceState` rate limits.** One replace per keystroke in the search field.
  Safari throttles at ~100 history writes / 30 s; normal typing stays well
  under, so no debounce for now.

## Out of scope

- Sharing/deep-linking as a feature (it falls out of this, but no UI for it).
- Persisting the booking/edit drawers or pagination in the URL.

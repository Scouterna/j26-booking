# 25. Filter the activity list by location

> **Status: ✅ Done 2026-07-26** (implemented as designed. No migration or write
> path touched — `location_id` is now emitted on the activity summary and the
> client filters client-side via a searchable multi-select in the "More filters"
> panel. Verified in a Gleam 1.16.0 container: shared 11 tests pass, client 131
> tests pass (incl. 3 new `apply_filters` location cases), server type-checks
> clean. Not yet committed — `gleam format` normalization pending on commit.)

## Context

The "More filters" panel already filters the activity list by **tags** and
**målgrupp** (target groups) — see plan 08. There is no way to narrow the list
to a **location**, even though every activity already links to one and the
detail page renders it.

This plan adds a **location** filter to the same panel, mirroring the existing
tag filter end-to-end. Filtering runs **client-side** over already-loaded
summaries in [`apply_filters`](../../client/src/client.gleam) — exactly like the
tag / target-group filters.

## Why this is safe for existing data

**No migration, no write path, no risk to existing activities.**

- Activities **already** store `location_id` (a nullable FK): the detail page
  fetches and renders the full `Location`. Nothing about how activities are
  stored, created, or updated changes.
- The client **already** fetches the full locations vocabulary once on init
  (`Model.locations: Dict(Uuid, Location)`, from `/api/locations`) and uses it
  for the activity-form location picker — so the filter UI needs no new fetch.
- The only server change is **read-only**: the slim list summary
  (`summary_to_json`) currently emits `location_name` but not `location_id`;
  we add the id so the client can filter by it. This is purely additive JSON.

The entire feature is additive read + display. It touches no SQL, no migration,
no create/update/delete handler.

## Design

Mirror the tag filter (ids on the summary → client filters by id via
`lists_intersect`-style membership → resolve id to a label via the already-
fetched vocabulary), with **one deliberate difference in the UI**: with ~70
locations a flat chip row (as tags/målgrupp use) is unusable, so the location
filter is a **searchable multi-select** (decided with the user). It reuses the
form's combobox pattern (`view_location_picker`) but toggles membership and
renders the selected locations as removable chips above the field.

## Changes

### 1. Server — expose `location_id` on the summary (read-only)

`server/src/server/model/activity.gleam`, `summary_to_json` (~line 512):
add one field next to the existing `location_name` (both derive from the
`location` already destructured in scope):

```gleam
#(
  "location_id",
  json.nullable(location |> option.map(fn(l) { l.id }), uuid_to_json),
),
```

`server/priv/openapi.yaml`: add `location_id` (nullable UUID) to the
`ActivitySummary` response schema, per the server API-changes convention.

### 2. Shared — carry it on the type

`shared/src/shared/model.gleam`, `ActivitySummary` (line 238) and
`activity_summary_decoder` (line 265):

- Add field `location_id: Option(Uuid)` (keep `location_name` for card display).
- Decode with
  `decode.optional_field("location_id", None, decode.optional(uuid_decoder()))`.
- Add `location_id:` to **both** the `decode.success` and the `decode.failure`
  fallback `ActivitySummary(...)` constructors.

### 3. Client — filter state + logic (`client/src/client.gleam`)

- `ListFilters` (line 893): add `locations: List(Uuid)`. Seed `[]` in
  `default_filters` (line 903). Add it to the recurring-tab reset inside
  `apply_filters` (line 7430):
  `ListFilters(..f, search: "", target_groups: [], tags: [], locations: [])`.
- New message `UserToggledLocation(Uuid)` with a handler mirroring
  `UserToggledTag` (line 2976) — **list-filter branch only**. Unlike
  target-groups/tags, there is **no** activity-form branch: the form's location
  picker is a separate single-select (`UserSelectedLocation`). Handler:
  `update_filters(model, fn(f) { ListFilters(..f, locations: toggle_member(f.locations, id)) })`.
- Transient picker UI state (search query + open/closed) is UI-only, so it lives
  on the `Model`, not in `ListFilters` (which persists per page). Add a small
  record — e.g. `location_filter_ui: LocationPickerUi(query: String, open: Bool)`
  — initialised in `init`, mirroring how the form keeps its picker state in
  `edit_ui` (`location_query` / `location_open`). Add messages
  `UserSearchedLocationFilter(String)`, `UserOpenedLocationFilter`,
  `UserClosedLocationFilter` with handlers copied from the form's
  `UserSearchedLocation` / `UserOpenedLocationDropdown` /
  `UserClosedLocationDropdown` (lines 3022–3059) but writing to
  `location_filter_ui`.
- `apply_filters` (line 7421): add a `location_match` and `&&` it in:

  ```gleam
  let location_match = case f.locations {
    [] -> True
    selected ->
      summary.location_id
      |> option.map(list.contains(selected, _))
      |> option.unwrap(False)
  }
  ```

  (Activities with no location are excluded whenever a location filter is
  active — same intuition as the tag filter.)

### 4. Client — filter UI (searchable multi-select)

- `view_more_filters_panel` (line 4805) currently receives `activity_tags`; also
  pass the `locations` dict and the `location_filter_ui` state through from its
  call site (`view_activities_list`, line 4529, which already has `locations` in
  scope at line 4438). Add a third section under the tag chips.
- Add `view_location_multi_picker` next to `view_location_picker` (line 4886),
  reusing its `matches` (name-sorted, query-filtered) and `option_button`
  helpers. Differences from the single-select:
  - Options **toggle** membership (`UserToggledLocation(id)`) and the list stays
    open; the checked state is `list.contains(selected, id)`.
  - Selected locations render **above** the field as removable
    `component.filter_chip`s (click removes) so choices stay visible while the
    dropdown filters the full ~70.
  - No "no location" clear-entry (that concept is form-only); a "clear all"
    affordance is optional.
- Add `list.filter.location_label` translation keys (sv "Plats" / en "Location")
  near the existing `list.filter.tags_label` block.

### 5. Tests (`client/test/client_test.gleam`)

- `base_summary` (line 45) gains `location_id: None`.
- New `apply_filters` cases (pure, no DB):
  - a selected location keeps only activities whose `location_id` matches;
  - with a location filter active, an activity whose `location_id` is `None` is
    dropped;
  - empty `locations` keeps everything (regression: existing default test still
    passes once the field is added);
  - the recurring-tab reset clears an active location filter.

## Out of scope

- Server-side location filtering / a `?location=` query param — filtering stays
  client-side over the loaded window, consistent with tags and search.
- Persisting the location filter across navigation (tags/target-groups/search
  already reset on navigation; location matches that behaviour — see plan 12).
- Managing the location vocabulary from this screen (locations CRUD already
  exists at `/api/locations`).

## Verification

1. `gleam format` + `gleam test` in `shared/`, `server/`, `client/` — all green
   (new `apply_filters` regressions included).
2. `./start.sh` (server on :8000, `DEV_AUTH_ROLES=admin`), then in the browser:
   - `GET /api/activities?...` summaries now include `location_id`.
   - "More filters" → search a location, select two → the list narrows to
     activities at those locations; selected chips show above the field and
     remove on click; activities with no location disappear.
   - Switching to a recurring tab (Badbuss/Klättervägg) ignores the location
     filter (reset), consistent with search/tags.
3. Run `gleam-reviewer` on changed server/shared files and check the client
   against `lustre-guide` / `web-components` conventions.

## Notes / risks

- Because there is no migration and no write path, the risk to existing
  activities is effectively nil; the worst case is a display bug in the new
  panel section, isolated from booking/activity data.
- `summary_to_json` builds `location_id` from the `Activity.location` already in
  scope — no new query and no change to the row → `Activity` conversions.

# 27. Location filter offers only locations that have an activity

> **Status: 🚧 In progress** (as of 2026-07-27) — code complete on branch
> `feat/filter-locations-with-activities`; pending `gleam run -m squirrel`
> (regenerates `sql.gleam` for the new query param), `gleam format`, tests, and
> commit.

## Context

Plan [25](25-filter-activities-by-location.md) added the activity list's
location filter (a searchable multi-select in the "More filters" panel). It
populates its options from `Model.locations` — the **full** location vocabulary
fetched from `/api/locations`, the same dict the create/edit activity form's
location picker uses. That vocabulary includes facility-only locations (toilets,
info points, …) that no activity references. Offering those as **filter** options
is useless: filtering the list by a location with no activities can only ever
yield nothing.

Requirement (from the product owner): the **filter** should offer only
locations that have at least one activity, while the create/edit **form picker**
must still offer **every** location (so an activity can be assigned to any
location, including one that has none yet). The set of "locations with an
activity" should come from the database, not be computed in the frontend, and
should reflect **all** activities — not just the summaries currently loaded in
the browser.

## Design

Split the two consumers onto two vocabularies:

- **Form picker** → `Model.locations`, from `GET /api/locations` (all locations).
  Unchanged.
- **List filter** → new `Model.filter_locations`, from
  `GET /api/locations?has_activities=true` (only locations an activity
  references).

Filtering itself is unchanged (client-side over `summary.location_id`, per plan
25). Only the **option list** the filter offers changes. An already-selected
location that later loses its activities keeps filtering as before — it just
won't be offered again (decided with the user); filters reset on navigation
anyway (plan 12/26), so this is a negligible race.

## Changes

### Server — `has_activities` query param on `GET /api/locations` (read-only)

- `server/src/server/sql/list_locations.sql`: add a boolean param `$1`; return
  all rows when false, else only locations with a referencing activity via
  `WHERE NOT $1 OR EXISTS (SELECT 1 FROM activity WHERE activity.location_id = location.id)`.
  This is the DB equivalent of `SELECT DISTINCT a.location_id … FROM activity a
  JOIN location l …`, returning full `Location` rows so the combobox can render
  names. **Requires `gleam run -m squirrel`** to regenerate `sql.gleam`
  (`list_locations` gains a `Bool` argument).
- `server/src/server/model/location.gleam`: `fetch_all` gains
  `only_with_activities: Bool` and threads it into `sql.list_locations`.
  `fetch_all_dict` (embeds locations into activities) passes `False` — embedding
  must never drop a referenced location.
- `server/src/server/web/location.gleam`: `get_all` reads the optional
  `has_activities` query param (default `false`, 400 on a bad value) via the
  existing `web.ensure_valid_query_param` helper; added a local `parse_bool`.
- `server/priv/openapi.yaml`: document the new query parameter (per the server
  API-changes convention).

No migration, no write path, no schema change: `activity.location_id` (and its
index) already exist.

### Client — a second vocabulary for the filter (`client/src/client.gleam`)

- `Model`: add `filter_locations: Dict(Uuid, Location)`, initialised empty.
- `init`: dispatch a new `fetch_filter_locations()` effect
  (`GET /api/locations?has_activities=true`) alongside the existing
  `fetch_locations()`.
- New message `ApiReturnedFilterLocations(Result(List(Location), rsvp.Error))`
  with a handler folding rows into `filter_locations` (mirrors
  `ApiReturnedLocations`); failure keeps the empty vocabulary (filter offers no
  options).
- View plumbing: thread `filter_locations` from `view` → `view_activities_list`
  → `view_more_filters_panel` → `view_location_filter`. The form drawer
  (`view_activity_form_drawer`) keeps receiving the full `locations`.

## Verification

1. `cd server && gleam run -m squirrel` (needs `DATABASE_URL` up), then
   `gleam format` + `gleam test` in `shared/`, `server/`, `client/`.
2. `./start.sh`, then in the browser:
   - Create/edit an activity → the form's location picker still lists **every**
     location (toilets included).
   - "More filters" → the location filter lists **only** locations that have an
     activity; toilets etc. are absent.
   - `GET /api/locations` returns all; `GET /api/locations?has_activities=true`
     returns the reduced set; a bad value (`?has_activities=nope`) is a 400.

## Out of scope

- Server-side filtering of the activity list itself (still client-side, plan 25).
- Resolving a selected-but-now-empty location's chip label from the full
  vocabulary (negligible race; filters reset on navigation).

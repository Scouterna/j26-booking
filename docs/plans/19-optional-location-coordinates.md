# 19. Optional location coordinates (issue #26)

> **Status: ✅ Done 2026-07-19** (commit `1dfbacf`; implemented as planned after
> one correction: Squirrel cannot generate optional query parameters, so the
> create/update queries split into `_with_coordinates`/`_without_coordinates`
> variants instead of taking `Option(Float)` params)

## Problem

Issue #26: _"The locations api does not support locations without lat and
long. It should be supported."_ (Title: "Make sure activity heading does not
show map if location only has a name".)

Today `location.latitude` / `location.longitude` are `FLOAT8 NOT NULL` in the
DB, `Float` in the shared `Location` type, and required numbers in the API.
A location that only has a name cannot exist, and the activity detail page
unconditionally renders the map preview iframe whenever the activity has a
location.

## Goal

- Locations may exist with a name but no coordinates.
- Coordinates are all-or-nothing: latitude without longitude (or vice versa)
  must be impossible at every layer — DB, Gleam types, and API validation.
- The activity detail heading only shows the map iframe when the location
  actually has coordinates; otherwise the page renders without a map.

## Design decisions

1. **Gleam model: `coordinates: Option(Coordinates)`**, not two independent
   `Option(Float)` fields. A new shared type

   ```gleam
   pub type Coordinates {
     Coordinates(latitude: Float, longitude: Float)
   }
   ```

   replaces the `latitude`/`longitude` fields on `shared/model.Location`
   (and on the server's `LocationInput`). Two independent options would let
   lat-without-long exist in the model; one option of a pair cannot
   (make-invalid-states-impossible convention).

2. **JSON shape stays flat.** The API keeps top-level `latitude` and
   `longitude` fields — both numbers, or both `null`/absent. No nested
   `coordinates` object, so existing consumers (map service, notes, examples)
   keep working. Serialize with `json.nullable`; a request providing exactly
   one of the two fields is a 400.

3. **DB: drop `NOT NULL`, add a paired CHECK.** The database enforces the
   same invariant the types do:

   ```sql
   CHECK ((latitude IS NULL) = (longitude IS NULL))
   ```

4. **Query variants for writes, not `Option` parameters.** Squirrel makes
   nullable columns `Option(...)` in *row* types, but query *parameters* can
   never be optional: Postgres does not surface parameter nullability when
   preparing a query, so Squirrel has nothing to go on (upstream issues
   giacomocavalieri/squirrel#16/#78/#127, discussion #82 — the maintainer's
   recommended workaround is separate queries). This repo already follows
   that pattern (`create_activity_with_max_attendees` /
   `create_activity_without_max_attendees`), so `create_location` and
   `update_location` each split into `_with_coordinates` /
   `_without_coordinates` variants; the handler picks one by matching on
   `input.coordinates`.

## Steps

### 1. Migration (`server/`)

- `gleam run -m cigogne new --name optional_location_coordinates`, then fill:
  - **up**: `ALTER TABLE location` — `ALTER COLUMN latitude DROP NOT NULL`,
    `ALTER COLUMN longitude DROP NOT NULL`,
    `ADD CONSTRAINT location_coordinates_paired CHECK ((latitude IS NULL) = (longitude IS NULL))`.
  - **down**: drop the constraint, re-add `SET NOT NULL` on both columns
    (fails if coordinate-less rows exist — acceptable for a down migration).
- Apply with `gleam run -m cigogne up`.

### 2. SQL queries + regenerate Squirrel (`server/`)

- Replace `create_location.sql` with `create_location_with_coordinates.sql`
  (keeps the `$9`/`$10` coordinate params) and
  `create_location_without_coordinates.sql` (inserts `NULL, NULL`, no
  coordinate params); same split for `update_location.sql`. Read queries
  (`list_locations.sql`, `get_location.sql`) are unchanged.
- `gleam run -m squirrel` — the read/RETURNING row types gain
  `Option(Float)` coordinate fields automatically.

### 3. Shared model (`shared/src/shared/model.gleam`)

- Add `pub type Coordinates { Coordinates(latitude: Float, longitude: Float) }`.
- `Location`: replace `latitude: Float, longitude: Float` with
  `coordinates: Option(Coordinates)`.
- `location_decoder()`: decode `latitude`/`longitude` as
  `decode.optional_field(_, None, decode.optional(float_field))`, then
  combine — `Some, Some → Some(Coordinates(..))`, `None, None → None`,
  mixed → `decode.failure(None, "both latitude and longitude, or neither")`.

### 4. Server model (`server/src/server/model/location.gleam`)

- The `from_*_row` builders (now six: list, get, and the four write
  variants) zip the row's two `Option(Float)`s into `Option(Coordinates)`
  via one shared helper (`Some, Some → Some(..)`, otherwise `None` — the
  CHECK constraint guarantees pairing).
- `to_json`: emit `latitude`/`longitude` with
  `json.nullable(option.map(coordinates, ...), json.float)`.

### 5. Server handler (`server/src/server/web/location.gleam`)

- `LocationInput`: `coordinates: Option(model.Coordinates)`.
- `location_input_decoder()`: same both-or-neither combination as the shared
  decoder — a mixed payload fails decoding and the handler's existing
  `given.ok` turns that into 400 "Invalid JSON payload".
- `create`/`update`: match on `input.coordinates` and call the
  `_with_coordinates` or `_without_coordinates` query variant (mirrors the
  `max_attendees` handling in `web/activities.gleam`).

### 6. Client (`client/src/client.gleam`)

- `view_activity_detail_loaded` (~line 4871): the map block currently guards
  on `activity.location` only. Guard on location **and** coordinates, e.g.
  flatten to `Option(#(Location, Coordinates))` with `option.then`/
  `option.map`; render `element.none()` when either is missing.
- `map_preview_src` (~line 4815) takes the location plus its `Coordinates`
  (needs `icon_name`/`icon_variant` from the location and lat/lng from the
  pair).

### 7. OpenAPI spec (`server/priv/openapi.yaml`)

- `Location` schema: `latitude`/`longitude` become `nullable: true`; keep
  them in `required` (always present, possibly null). Document the paired
  rule in the descriptions.
- `LocationInput`: remove `latitude`/`longitude` from `required`, mark
  `nullable: true`, document both-or-neither → 400.

### 8. Seeds (`server/priv/seeding/locations.sql`)

- Add one name-only location (NULL coordinates) so the seeded dataset
  exercises the new path end-to-end.

### 9. Tests

- `shared/test/shared/model_test.gleam` (new): `location_decoder` accepts
  both-present, accepts both-null/absent, rejects lat-only and lng-only.
- Server: the input decoder is private and `create`/`update` need a live DB,
  so API-level coverage comes from live verification (below) rather than
  unit tests; the row→Location zip is covered indirectly by the decoder
  round-trip if we add a `location.to_json` test in
  `server/test/server/model/location_test.gleam` (new) — encode a
  coordinate-less `Location`, decode with the shared decoder, expect
  `coordinates: None`.

### 10. Verification

- `gleam format` + `gleam test` in `server/`, `shared/`, `client/`.
- `./start.sh`, then with `DEV_AUTH_ROLES=admin`:
  - `POST /api/locations` without coordinates → 201, `latitude: null`.
  - `POST /api/locations` with only `latitude` → 400.
  - `PUT` an existing location clearing coordinates → 200.
  - `GET /api/locations` → mixed list decodes in the client (activity page
    for an activity at a coordinate-less location shows no map iframe;
    one with coordinates still shows it).

## Notes

- The map service iframe (`/_services/map/preview.html`) is untouched — it
  simply never gets rendered without coordinates.
- `docs/location-notes.md` (untracked scratch notes) predates this and needs
  no update.

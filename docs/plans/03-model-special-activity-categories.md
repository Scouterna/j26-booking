# 03. Model badbuss & klättervägg as activity categories

> **Status: ✅ Done — but via a different design** (verified 2026-07-02)
>
> The *goal* (badbuss & klättervägg as special activities behind their own
> top-level filters) shipped, but **none of the architecture below was
> followed**. Instead of a generic `activity_category` table + `category_id` FK
> + `/api/activity-categories` + a single filtered list query, the actual
> implementation is simpler and hardcoded:
>
> - **Migration `20260629120000-add_recurring_activity_kind.sql`** adds a plain
>   nullable `recurring_activity_kind TEXT` column to `activity` (no separate
>   table, no display label/icon data, no `id`/`slug`/`name`/`name_en`).
> - **Dedicated endpoints** `GET /api/swim-bus-activities` and
>   `GET /api/climbing-wall-activities` (router.gleam:30-33) backed by dedicated
>   queries `list_swim_bus_activities.sql` / `list_climbing_wall_activities.sql`
>   that filter `WHERE recurring_activity_kind = 'swim-bus' | 'climbing-wall'`.
>   No `category` query param on `/api/activities`; no `/api/activity-categories`.
> - **Client** models the tabs as `SourceSwimBus` / `SourceClimbingWall`
>   (part of the `ActivityListSource` work from the normalized-store plan), not
>   from a fetched category list.
>
> Net effect: the two special categories are *fixed in code* rather than
> data-driven. Adding a third special activity would need a new column value,
> query, endpoint, and client source — the exact migration-free extensibility
> this plan aimed to avoid. Revisit only if organizers need to add categories
> without a deploy. The design details below are **superseded** and kept for
> reference.

## Context

Badbuss and klättervägg are special activities consisting of **many individual bookable slots** that share a title/description but vary in `max_attendees`, `start_time`, and `end_time`. They are **not** grouped into a single card — each slot is shown individually in its own filtered list.

The UI exposes top-level filters:
There 
- **Klättervägg** — all klättervägg slots
- **Badbuss** — all badbuss slots
- **Other activities** — everything that is *not* a special category
- **Favourited / Booked** — the current user's favourited/booked activities, including klättervägg/badbuss slots

Because browsing, favouriting (`favourite.activity_id`) and booking (`booking.activity_id`) all already happen at the **slot grain**, no series/occurrence split is needed. Each slot stays a plain `activity` row. The only new concept is a **category** that routes an activity into the right top-level filter.

Decision: store categories as **data** in a new `activity_category` table with a nullable `activity.category_id` FK (`NULL` = "Other"). A table (rather than a Postgres enum) is chosen because the filter tabs themselves need a display label + icon, and new special activities can be added without a migration. This matches the direction of the README's planned `location_category` (`name` / `name_en` / `icon_name`).

## Database

### 1. Migration `priv/migrations/<timestamp>-add_activity_category.sql`

```sql
--- migration:up
CREATE TABLE activity_category(
    id UUID PRIMARY KEY,
    slug TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    name_en TEXT NOT NULL,
    icon_name TEXT
);

ALTER TABLE activity
    ADD COLUMN category_id UUID REFERENCES activity_category(id);

CREATE INDEX activity_category_id_idx ON activity (category_id);
--- migration:down
ALTER TABLE activity DROP COLUMN category_id;
DROP TABLE activity_category;
--- migration:end
```

Apply with `gleam run -m cigogne last`. `NULL category_id` = "Other"; existing activities need no backfill.

### 2. Seed badbuss & klättervägg

Add the two category rows (and assign `category_id` on their slots) to `priv/seeding/activities.sql`.

## SQL / Squirrel (`server/src/server/sql/`)

After editing any `.sql`, run `gleam run -m squirrel` and `gleam format`. Never edit `sql.gleam` by hand.

### List queries — fold the category filter into the existing two sort queries

Replace `get_activities_by_start_time.sql` and `get_activities_by_title.sql` so all three list modes (all / specific category / uncategorized) collapse into one query per sort order. `$3` = "only uncategorized" bool, `$4` = optional category id:

```sql
-- get_activities_by_start_time.sql
SELECT *
FROM activity
WHERE
    CASE
        WHEN $3 THEN category_id IS NULL
        WHEN $4::uuid IS NOT NULL THEN category_id = $4
        ELSE TRUE
    END
ORDER BY start_time ASC
LIMIT $1 OFFSET $2;
```

(Mirror the same `WHERE` in the `by_title` query.) These already use `SELECT *`, so the new column is picked up automatically; the generated Row types will gain `category_id`.

### New query — categories for the tabs

```sql
-- get_activity_categories.sql
SELECT id, slug, name, name_en, icon_name
FROM activity_category
ORDER BY name;
```

### Existing explicit-column queries

`create_activity_with_max_attendees.sql`, `create_activity_without_max_attendees.sql`, the two `update_activity_*.sql`, and `get_activity.sql` list columns explicitly. Add `category_id`:

- **Create**: add a single nullable `category_id` param to **both** create variants (do not add a third with/without dimension — just pass `NULL` when absent) and to the `RETURNING` list.
- **Update**: add `category_id` to the `SET` and `RETURNING` lists.
- **get_activity**: add `category_id` to the `SELECT` list.

## Domain model

### `shared/src/shared/model.gleam`

- Add `category_id: Option(Uuid)` to `Activity`; update `activity_decoder` (`decode.optional_field("category_id", None, decode.optional(...))`, parsing the UUID string).
- Add an `ActivityCategory` type + `activity_category_decoder` / `activity_categories_decoder`, mirroring the existing `Favourite` decoders (string UUID → `uuid.from_string`, list under `{"categories": [...]}`).

### `server/src/server/model/activity.gleam`

- Add `category_id` to every `from_*_row` converter (the row types now carry it; `without_max_attendees` variants set `max_attendees: None` but still read `category_id`).
- Add `category_id` to `to_json` (`json.nullable(category_id, fn(id) { json.string(uuid.to_string(id)) })`).
- New `server/model/activity_category.gleam` (or a section in the same module) with `from_get_activity_categories_row` and `to_json`.

## API (`server/src/server/`)

### `web/activities.gleam`

- `get_page`: parse a `category` query param via the existing `web.ensure_valid_query_param` helper. Map it to the new `$3`/`$4` args:
  - absent → all (`only_uncategorized = False`, `category = None`)
  - `category=none` → Other (`only_uncategorized = True`)
  - `category=<uuid>` → that category (`category = Some(id)`)
- Thread the two new args through both `sql.get_activities_by_*` calls.
- `ActivityInput` + `activity_input_decoder`: add `category_id: Option(Uuid)` (decode optional string → UUID). Pass it into both create variants and the update call.

### New `web/activity_category.gleam`

- `get_all(req, ctx)` → `GET /api/activity-categories`, returns `{"categories": [...]}` (read-only is enough for now; categories are managed via seed/SQL).

### `router.gleam`

```gleam
Get, ["activity-categories"] -> activity_category.get_all(req, ctx)
_, ["activity-categories"] -> wisp.method_not_allowed([Get])
```

### `priv/static/openapi.yaml`

Per `server/CLAUDE.md`, update in the same change: add the `category` query param to `GET /api/activities`, the `category_id` field on the Activity schema and create/update bodies, and the new `GET /api/activity-categories` path + `ActivityCategory` schema.

## Client (`client/src/client.gleam`)

- Fetch categories on init (new effect, like `fetch_my_favourites`); store on the model to drive the tabs.
- Introduce a top-level filter as a `scout-segmented-control` / `scout-tabs` whose options are: **one tab per category** + **Other** + **Favourites/Booked**. This supersedes/absorbs the current `FavouriteFilter` (`AllActivities | FavouritesOnly`) as the primary selector.
- Changing to a category/Other tab triggers a **server-side refetch** with the `category` query param (category filtering must be server-side so pagination is correct when a special activity has many slots).
- **Favourites/Booked** tab keeps the current client-side behaviour over `my_favourite_ids` / `my_bookings`. Note the pre-existing limitation that this only reflects activities already loaded into the page — out of scope to fix here, but flag it.
- Add i18n keys for the new tab labels (`list.filter.badbuss`, `list.filter.klattervagg`, `list.filter.other`, …) in both `en` and `sv` translation blocks (around `client.gleam:66` / `:116`). Prefer driving label text from the category's `name`/`name_en` where possible.

## Files to modify

- `server/priv/migrations/<timestamp>-add_activity_category.sql` (new)
- `server/priv/seeding/activities.sql`
- `server/src/server/sql/get_activities_by_start_time.sql`, `get_activities_by_title.sql`
- `server/src/server/sql/get_activity_categories.sql` (new)
- `server/src/server/sql/create_activity_with_max_attendees.sql`, `create_activity_without_max_attendees.sql`, `update_activity_with_max_attendees.sql`, `update_activity_without_max_attendees.sql`, `get_activity.sql`
- `server/src/server/sql.gleam` (regenerated via squirrel — do not hand-edit)
- `shared/src/shared/model.gleam`
- `server/src/server/model/activity.gleam`, `server/src/server/model/activity_category.gleam` (new)
- `server/src/server/web/activities.gleam`, `server/src/server/web/activity_category.gleam` (new)
- `server/src/server/router.gleam`
- `server/priv/static/openapi.yaml`
- `client/src/client.gleam`
- `server/README.md` — add `activity_category` + `category_id` to the MVP schema diagram (also still missing the `favourite` table from a prior change).

## Out of scope / deferred

- **Shared-text editing**: each slot still carries its own duplicated title/description. A template/series table for single-source editing is only worth it if organizers re-edit shared text often — defer.
- **Per-slot capacity enforcement** (`COUNT(bookings) ≤ max_attendees` inside the create-booking transaction) is orthogonal but worth doing separately, since many-slot special activities make overbooking more likely.

## Verification

1. `gleam run -m cigogne last` (server/) applies the migration cleanly; `down` reverts.
2. `gleam run -m squirrel` regenerates `sql.gleam` without errors; `gleam format`.
3. `gleam test` (server/) passes.
4. `./seed.sh` seeds the two categories and their slots.
5. `GET /api/activity-categories` returns badbuss + klättervägg.
6. `GET /api/activities?category=<badbuss-id>` returns only badbuss slots; `?category=none` excludes them; no param returns all.
7. `GET /api/docs` (Scalar) reflects the new param/paths/schema.
8. `./dev.sh`: tabs render, switching category refetches the right slots, Favourites/Booked shows favourited/booked items, booking a slot still works.
9. `cd client && gleam format`.

# 08. Activity tags & målgrupp (real, not mocked)

> **Status: ✅ Done 2026-07-10** (committed on branch `feat/activity-tags-malgrupp`).
> Implemented end-to-end and verified: server 18 tests + client 60 tests pass;
> migrations applied, seeded, and smoke-tested via API + UI. Diverged slightly
> from the plan: målgrupp labels use a plain `target_group_label` helper (section
> names are proper nouns, identical in both languages) rather than g18n keys; the
> edit-form view remains a pre-existing `not_found` stub, so pickers were wired
> into the create form and the edit *state/handlers* (data-correct) but no new
> edit view was built. Squirrel bumped 4.6.0 → 4.7.0.

## Context

Activity **tags** ("Fysisk", "Badbuss", "Mat", …) and **målgrupp** (the five
Scouterna age sections: Spårare, Upptäckare, Äventyrare, Utmanare, Rover) are
currently **faked entirely in the client**. `client/src/client.gleam:2694-2722`
defines hardcoded option lists and `mock_audiences`/`mock_tags`, which
deterministically invent per-activity data from the activity UUID. These mocks
feed only the "More filters" panel (`apply_filters`, `client.gleam:2810-2818`) —
they are never shown on cards or the detail page. The backend has **no** concept
of activity tags or målgrupp.

We will replace the mock with a real end-to-end implementation:

- **Tags** → an admin-manageable entity table `activity_tag`, mirroring the
  existing mature `location_tag` pattern (bilingual name + icon, many-to-many
  join, `/api/activity-tags` CRUD).
- **Målgrupp** → a fixed, closed enum (`TargetGroup`) modelled as a shared Gleam
  custom type, persisted as text on a join table. Not admin-editable.

**Scope (confirmed with user):**
- Real data flows DB → API → client; mocks removed; filtering runs on real data.
- Both tags and målgrupp are **assignable in the activity create/edit form**.
- Both are **displayed on the activity detail page** (NOT on list cards).
- No client screen to manage the tag vocabulary itself (API CRUD exists though).

The `location_tag` feature (migration → SQL → squirrel → model grouping → JSON →
handler with transaction re-sync) is the template. Files to mirror:
`server/src/server/model/location.gleam`, `server/src/server/web/location.gleam`,
`server/src/server/sql/*location*`.

---

## 1. Shared types (`shared/src/shared/model.gleam`)

### `TargetGroup` custom type (new)
Add a closed enum + helpers (per gleam-conventions, model closed sets as custom
types, not strings):

```gleam
pub type TargetGroup {
  Sparare
  Upptackare
  Aventyrare
  Utmanare
  Rover
}
```
- `target_group_to_string` / `target_group_from_string` (String ↔ variant; the
  string is the DB/JSON wire value, e.g. `"sparare"`). `from_string` returns
  `Result` per conventions.
- `target_groups_all() -> List(TargetGroup)` in age order (drives client chips
  and ensures stable ordering the DB can't guarantee).
- `target_group_from_string` returns `Result` (used by the client JSON decoder,
  which can meet a malformed wire value) and `target_group_to_json` encodes the
  wire string. Note: bilingual *display labels* live in the client's g18n
  translations, not here — the type only carries the identity.

> **Two `TargetGroup` types, mapped (decision: "embrace both").** Squirrel
> **4.6.0 generates a Gleam custom type from a Postgres enum** (README:
> "user-defined enum → Gleam custom type") — so the real PG enum in Migration B
> produces `sql.TargetGroup` in `server/src/server/sql.gleam`. But that lives in
> the server-only `sql` module; the `shared` `Activity`/`ActivitySummary` fields
> need a type from the `shared` package, so `shared/model.gleam` defines its own
> `model.TargetGroup`. The server model layer maps `sql.TargetGroup` ↔
> `model.TargetGroup` with a **total, exhaustive `case`** (no `Result` — both
> are the same closed set). Payoff: if a value is ever added to the DB enum,
> Squirrel regenerates `sql.TargetGroup` and the mapping fails to compile until
> updated. (The project `squirrel-conventions` skill still says "custom enums →
> String" — that is **stale for 4.6.0** and should be corrected separately.)

> **Why `List`, not `Set`.** Tags/target-groups are stored as `List` (mirroring
> the existing `location.tags: List(Uuid)`), not `gleam/set`, because:
> (1) målgrupp has a meaningful age order for display that a `Set` can't
> preserve; (2) uniqueness is already guaranteed by the join-table `PRIMARY KEY`
> (and controlled form toggles); (3) the JSON boundary is an array regardless.
> Display and filtering iterate the **canonical** vocabulary
> (`target_groups_all()` / the fetched tag list) and check membership, which
> yields canonical order and dedupes for free.

### `ActivityTag` type (new — like `LocationTag` but **no icon**)
```gleam
pub type ActivityTag {
  ActivityTag(id: Uuid, name: BilingualString)
}
```
Unlike `LocationTag`, activity tags carry **no icon** (no `icon_name` /
`icon_variant`) — they render as plain text chips. Add `activity_tag_decoder()`
and `activity_tags_decoder()` (wrapping `{"activity_tags": [...]}`).
(`LocationTag` has no decoder today because the client never fetched it; the
activity client *will*, so decoders are required.)

### Extend `Activity` and `ActivitySummary`
Both need the new fields — **the list/filter uses `ActivitySummary`** and the
**detail page uses `Activity`**, so both must carry them:

```gleam
tags: List(Uuid),              // ids resolved via /api/activity-tags
target_groups: List(TargetGroup),
```
Update `activity_decoder`, `activity_summary_decoder` (decode `tags` via
`utils.decode_partial_list(of: uuid_decoder())` like `location_decoder`;
`target_groups` via `decode.list(target_group_decoder())`), and their
`decode.failure` fallbacks.

---

## 2. Database migrations (`server/priv/migrations/`)

Scaffold each with `gleam run -m cigogne new --name <name>` (never hand-create),
then apply with `gleam run -m cigogne up`.

**Migration A — `add_activity_tag`** (like `20260701120000-add_location.sql`
but the tag table has **no icon columns**):
```sql
CREATE TABLE activity_tag(
    id UUID PRIMARY KEY,
    name TEXT NOT NULL,
    name_en TEXT NOT NULL
);
CREATE TABLE activity_tag_activity(
    activity_tag_id UUID NOT NULL REFERENCES activity_tag(id),
    activity_id UUID NOT NULL REFERENCES activity(id),
    PRIMARY KEY (activity_tag_id, activity_id)
);
CREATE INDEX activity_tag_activity_activity_id_idx ON activity_tag_activity (activity_id);
```

**Migration B — `add_activity_target_group`**. Use a real Postgres enum for the
målgrupp column (DB-level integrity, matching the existing `user_role` enum
precedent). Squirrel still surfaces it as `String`, so the Gleam `TargetGroup`
mapping is unaffected:
```sql
CREATE TYPE target_group AS ENUM ('sparare', 'upptackare', 'aventyrare', 'utmanare', 'rover');
CREATE TABLE activity_target_group(
    activity_id UUID NOT NULL REFERENCES activity(id),
    target_group target_group NOT NULL,
    PRIMARY KEY (activity_id, target_group)
);
```
Provide matching `down` SQL (DROP table/index/type) in each.

---

## 3. Server SQL files (`server/src/server/sql/`) + squirrel

Mirror the `location_tag` query set. New `.sql` files (one query each):

**Tag vocabulary CRUD** (based on `*_location_tag.sql`, but **drop the
`icon_name`/`icon_variant` columns** — activity tags only have `id, name,
name_en`): `list_activity_tags.sql`, `create_activity_tag.sql`,
`get_activity_tag.sql`, `update_activity_tag.sql`, `delete_activity_tag.sql`.

**Tag links** (copy `*_location_tag_links.sql`):
`list_activity_tag_links.sql` (`SELECT activity_id, activity_tag_id FROM activity_tag_activity`),
`insert_activity_tag_links.sql` (`INSERT … SELECT $1, unnest($2::uuid[])`),
`delete_activity_tag_links.sql`, `delete_activity_links_by_tag.sql`.

**Target groups** — the `target_group` column is the PG enum, so Squirrel types
these against `sql.TargetGroup`:
`list_activity_target_groups.sql` (`SELECT activity_id, target_group FROM activity_target_group`)
→ Row has `target_group: sql.TargetGroup`.
`insert_activity_target_groups.sql` (`INSERT … SELECT $1, unnest($2::target_group[])`)
→ casting the array to the enum type makes Squirrel type `$2` as
`List(sql.TargetGroup)` (not `String`), keeping the whole write type-safe.
`delete_activity_target_groups.sql`.

Then `cd server && gleam run -m squirrel` to regenerate `sql.gleam`, and
`gleam format`. **Never edit `sql.gleam` by hand.**

---

## 4. Server model (`server/src/server/model/activity.gleam`)

The file has ~13 `from_*_row` constructors, all currently taking `locations:
Dict(Uuid, Location)`. Rather than add two more positional dicts to every
signature, introduce a small embed-context record and thread it through:

```gleam
pub type Embeds {
  Embeds(
    locations: Dict(Uuid, Location),
    tags_by_activity: Dict(Uuid, List(Uuid)),
    target_groups_by_activity: Dict(Uuid, List(model.TargetGroup)),
  )
}
```
- Replace the `locations` param in each `from_*_row` with `embeds: Embeds`;
  build `tags`/`target_groups` via `dict.get(...) |> result.unwrap([])` (same
  pattern `location.fetch_all` uses for tags).
- Add a **total** mapping between the Squirrel-generated `sql.TargetGroup` and
  the shared `model.TargetGroup`: `sql_target_group_to_model` and
  `model_target_group_to_sql`, each an exhaustive `case` (no `Result` — same
  closed set; the compiler enforces both stay in sync with the DB enum).
- Add grouping helpers mirroring `location.group_tags_by_location`:
  `group_tags_by_activity(List(ListActivityTagLinksRow)) -> Dict(Uuid, List(Uuid))`
  and `group_target_groups_by_activity(List(ListActivityTargetGroupsRow)) -> Dict(Uuid, List(model.TargetGroup))`
  (the latter maps each row's `target_group: sql.TargetGroup` via
  `sql_target_group_to_model` — no string parsing, no "unparseable" case).
- Add `activity_tag` row→`ActivityTag` converters (like
  `location.from_*_location_tag_row` but **without icon fields**) and
  `activity_tag_to_json` (emits only `id` + bilingual `name`).
- Extend `to_json` and `summary_to_json` with
  `#("tags", json.array(tags, uuid_to_json))` and
  `#("target_groups", json.array(target_groups, model.target_group_to_json))`.

---

## 5. Server handlers

### `server/src/server/web/activities.gleam`
- Add helpers mirroring `with_locations`: `with_activity_tag_links` and
  `with_target_group_links` (or one `with_embeds` that fetches all three link
  sets + locations and builds an `Embeds`). Fetch each link set with one query
  and group in memory — no per-activity queries.
- Update every conversion call site (`from_list_*`, `from_get_*`, `from_create_*`,
  `from_update_*`) to pass the `Embeds`.
- Extend `ActivityInput` + `activity_input_decoder` with
  `tags: List(Uuid)` and `target_groups: List(model.TargetGroup)` (decode via
  `utils.decode_partial_list` / `decode.list(model.target_group_decoder())`,
  defaulting to `[]`).
- In `create` and `update`, wrap the write in a `pog.transaction` (copy
  `location.create`/`location.update`): insert the activity row, then
  `delete_*` + `insert_*` the tag links and target groups so they re-sync to the
  request body. Map the input's `List(model.TargetGroup)` →
  `List(sql.TargetGroup)` (via `activity.model_target_group_to_sql`) before
  calling `insert_activity_target_groups`. `create` currently uses `dict.new()` for locations — after
  inserting links, build the `Embeds` from the just-written data (or re-fetch)
  so the JSON response reflects the new tags/målgrupp.

### `server/src/server/web/` — new tag vocabulary handlers
Add `get_activity_tags` / `create_activity_tag` / `get_activity_tag` /
`update_activity_tag` / `delete_activity_tag`, mirroring the `location.gleam`
tag handlers (guard writes with `web.require_role(user, web.ActivitiesManage)`;
`delete` must also `delete_activity_links_by_tag`). Put them in
`web/activities.gleam` (or a small `web/activity_tag.gleam` if that file grows
too large — prefer keeping in `activities.gleam` unless it's unwieldy, per the
"don't fragment prematurely" convention).

### `server/src/server/router.gleam`
Add routes mirroring the location-tags block:
`GET/POST /api/activity-tags`, `GET/PUT/DELETE /api/activity-tags/{id}`.

### `server/priv/static/openapi.yaml`
Per `server/CLAUDE.md`, update the spec in the same change: new `/api/activity-tags`
paths, the `tags`/`target_groups` fields on activity request/response schemas,
and a `TargetGroup` enum.

---

## 6. Seeding (`server/priv/seeding/activities.sql`)

- `INSERT INTO activity_tag (id, name, name_en)` rows for the real tag
  vocabulary (Fysisk, Badbuss, Mat, Skapande, Lugn — bilingual, **no icons**).
- `INSERT INTO activity_tag_activity (...)` linking tags to seeded activities.
- `INSERT INTO activity_target_group (activity_id, target_group)` assigning age
  sections to activities (wire strings, e.g. `'sparare'`).

---

## 7. Client (`client/src/client.gleam` + `component.gleam`)

### Remove the mock
Delete `audience_options`, `tag_options`, `mock_audiences`, `mock_tags`,
`id_seed`, `pick_at` (`client.gleam:2670-2722`) and the TODO comment.

### Model / data
- Add an activity-tag vocabulary cache to the `Model`:
  `activity_tags: RemoteData(Dict(Uuid, ActivityTag))` (or `List`), fetched from
  `/api/activity-tags` on init (new `Effect` + `Api...` message, following the
  existing fetch pattern). Needed to render tag id → label/icon.
- `ListFilters` (`client.gleam:345`): change `audiences: List(String)` →
  `target_groups: List(TargetGroup)` and `tags: List(String)` →
  `tags: List(Uuid)`. Update `default_filters`, `UserToggledAudience`/
  `UserToggledTag` messages and their update handlers.

### Filtering (`apply_filters`, ~`client.gleam:2793`)
Replace `mock_audiences(summary.id)` / `mock_tags(summary.id)` with
`summary.target_groups` / `summary.tags` (now real fields), intersecting against
the selected filters (`lists_intersect` stays).

### Filter panel (`view_more_filters_panel`, ~`client.gleam:1871`)
- Målgrupp chips: iterate `model.target_groups_all()`, label each via a g18n
  translation key (e.g. `target_group.sparare`), reuse `component.filter_chip`.
- Tag chips: iterate the fetched `activity_tags` vocabulary, label via
  `localized(translator, tag.name)`.

### Detail page display (`view_activity_detail_loaded`, ~`client.gleam:2232`)
Render two chip rows (tags + målgrupp) in the content area using
`component.badge` (already exists, `component.gleam:264`) or `filter_chip` in a
read-only style. `ActivityDetail` (`client.gleam:401`) currently holds only
`description` + `location`; add `tags` + `target_groups` and update `to_detail`
/ `to_activity` (`client.gleam:579-594`) to carry them. Resolve tag ids →
labels via the vocabulary cache.

### Create/edit form (assignment)
The form is built on `gleam/form` (string fields only), so multi-select
tag/målgrupp selection is held **outside** the `Form`:
- Extend `ActivityNewPage` and `ActivityEditPage`/`EditState`
  (`client.gleam:389-391`) to also carry `selected_tags: List(Uuid)` and
  `selected_target_groups: List(TargetGroup)`.
- Add toggle messages (reuse the `filter_chip` UI inside the form view
  `view_activity_new` ~`client.gleam:2086`, plus the edit view).
- On edit, prefill selections from the loaded activity.
- Extend `activity_form_to_json` (`client.gleam:1624`) to include `tags` and
  `target_groups`; thread the selected lists into `create_activity`/
  `update_activity` (they currently take only `ActivityForm`).

### Translations
Add g18n keys for the five målgrupp labels (sv + en) near the existing
`list.filter.*` block (`client.gleam:~78/141`). Tag labels come from the API
(bilingual), so no static keys needed for tags.

---

## Verification

1. **Migrate + seed:** `cd server && gleam run -m cigogne all`, then run the
   seeding SQL (`activities.sql`) per the README order. Confirm
   `activity_tag`, `activity_tag_activity`, `activity_target_group` populate.
2. **Server build/tests:** `cd server && gleam format && gleam test`.
3. **API smoke test:**
   - `GET /api/activity-tags` → returns seeded vocabulary.
   - `GET /api/activities?sort=start_time` → summaries include `tags` +
     `target_groups`.
   - `GET /api/activities/{id}` → detail includes both.
   - `POST`/`PUT /api/activities/{id}` with `tags`/`target_groups` in the body →
     persists and echoes them back; verify links re-sync on update.
4. **Client build:** `cd client && gleam run -m lustre/dev build` (or run the
   whole app with `./start.sh`).
5. **Manual (Playwright MCP or browser at :8000):**
   - List "More filters" panel shows real tags + målgrupp; selecting chips
     filters the list against real data.
   - Detail page shows the activity's tag + målgrupp chips.
   - Create/edit form lets you toggle tags + målgrupp; after save, reload the
     detail page and confirm they stuck.
6. **Review:** run `gleam-reviewer` on changed server/shared files and
   `web-components`/`lustre-guide` conventions on the client.

## Notes / risks
- The `Embeds` refactor touches every `from_*_row` call site in
  `web/activities.gleam` — mechanical but wide; grep for `_row(` to catch all.
- After `gleam run -m squirrel`, confirm `sql.gleam` contains the generated
  `pub type TargetGroup { Sparare Upptackare … }` and that the target-group
  Row/param types reference it. If Squirrel instead emitted `String`, the enum
  cast in the SQL is wrong — fix the query, don't hand-edit `sql.gleam`.
- The stale `squirrel-conventions` skill ("custom enums → String") should be
  corrected to "user-defined enum → generated Gleam custom type" in a follow-up.
- `create` builds its response `Embeds` from freshly-written data; make sure the
  transaction returns enough to populate tags/target_groups (or re-fetch links
  after commit) so the 201 body isn't missing them.
- Keep the målgrupp wire strings stable between `target_group_to_string`, the
  seed SQL, and the openapi enum.

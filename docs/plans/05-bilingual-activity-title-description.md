# 05. Handoff: bilingual `title` & `description` for activities

> **Status: ✅ Done 2026-07-08** (implemented as planned)
>
> `Activity.title`/`.description` and `ActivitySummary.title` are now
> `BilingualString` end-to-end (migration `20260708113115`, SQL, server model +
> web, shared decoders, client card/detail/search/form, OpenAPI, seed data).
> Verified: `gleam test` (server + client) green, seed inserts satisfy the new
> NOT NULL columns, and a live POST/PUT/GET round-trip carries nested `{sv,en}`.
> One divergence from the plan: the client edit-form view (`ActivityEditPage`)
> renders `view_not_found()` today, so the English inputs only surface on the
> **create** form — `ActivityForm`/`form_from_activity` still carry the English
> fields, so wiring the edit view up later needs no further model changes.

## Goal

Make an activity's `title` and `description` bilingual (Swedish + English) using
the existing `BilingualString` type, so the client renders the right language via
the existing `localized(translator, value)` helper — exactly like locations now
work.

## Reference implementation (mirror this)

This was just done for locations. **Study commit `b37634a`**
(`refactor(shared): model location name/description as BilingualString`) and the
commit before it (`35d8f28 feat(api): add location to activities`). The activity
change is the same shape. These already exist and are reused as-is:

- `shared/model.gleam`: `pub type BilingualString { BilingualString(sv:, en:) }`,
  `bilingual_string_decoder()`, `bilingual_string_to_json()`.
- `client/src/client.gleam`: `localized(translator, value: BilingualString) -> String`
  and `current_language(translator)`.
- OpenAPI: a `BilingualString` schema (`components/schemas/BilingualString`).

## The one big difference from the location work

The `activity` table has **only** `title` and `description` (both `NOT NULL`) —
there are **no** `title_en`/`description_en` columns (locations already had
`name_en`/`description_en`, so that work needed no migration). **This feature
requires a migration.** Also, activities have a client **create/edit form** and a
**search box**, which locations did not — those are extra surfaces to update.

## Decisions (pick sensible defaults; confirm with user if unsure)

1. **Column nullability** — recommend `NOT NULL`, backfilling existing rows with
   the Swedish value (`title_en = title`, `description_en = description`). Matches
   `location.name_en`/`description_en` (NOT NULL).
2. **Client create/edit form** — recommend adding English inputs (`title_en`,
   `description_en`) so admins can set both. This is the largest new piece and the
   main thing locations didn't have. If deferred, the form would only set Swedish
   and English would fall back to blank — decide explicitly.
3. **Search** — recommend matching the query against both `.sv` and `.en`
   (see `client.gleam` search filter, ~line 2710). Currently matches `summary.title`
   (a plain String); it becomes a `BilingualString`.

## Steps

### 1. Migration (scaffold with cigogne — never hand-create; see root CLAUDE.md)

```sh
cd server && gleam run -m cigogne new --name add_activity_title_en_description_en
```

Fill in:
- up: `ALTER TABLE activity ADD COLUMN title_en TEXT; ADD COLUMN description_en TEXT;`
  then backfill `UPDATE activity SET title_en = title, description_en = description;`
  then `ALTER TABLE activity ALTER COLUMN title_en SET NOT NULL, ALTER COLUMN description_en SET NOT NULL;`
- down: drop both columns.
- Apply: `gleam run -m cigogne up` (needs DB up — `.env.sh` points at `:5433`, the
  `j26booking-db` docker container).

### 2. SQL + regenerate (`server/src/server/sql/`)

- Read queries use `SELECT *` (`get_activity.sql`, `list_activities_by_*`,
  `get_activities_by_*`, `search_activities.sql`, beach-bus/climbing-wall/favourited)
  → they pick up the new columns automatically. Verify each.
- The **4 create/update** files (`create_activity_with/without_max_attendees.sql`,
  `update_activity_with/without_max_attendees.sql`): add `title_en`, `description_en`
  to the INSERT column list / `SET` clause **and** to `RETURNING` (RETURNING already
  lists columns explicitly), and add the new `$n` params.
- Regenerate: `gleam run -m squirrel`. Do not edit `sql.gleam` by hand.

### 3. Shared types (`shared/src/shared/model.gleam`)

- `Activity.title` and `Activity.description` → `BilingualString`.
- `ActivitySummary.title` → `BilingualString` (summary still **omits** description).
- Update `activity_decoder()` and `activity_summary_decoder()` to decode `title`
  (and `description` for the full one) via `bilingual_string_decoder()` instead of
  `decode.string`. Keep the id/timestamp handling as-is.

### 4. Server model (`server/src/server/model/activity.gleam`)

- All 13 `from_*_row` conversions:
  `title: model.BilingualString(sv: row.title, en: row.title_en)` and
  `description: model.BilingualString(sv: row.description, en: row.description_en)`.
  (Tip: the location commit did these with a `replace_all` on the shared field block.)
- `to_json`: emit `title`/`description` via `model.bilingual_string_to_json`.
- `summary_to_json`: emit `title` via `model.bilingual_string_to_json` (still drops
  description). Note: `location_name` there is already the `BilingualString` pattern —
  copy it.

### 5. Server web (`server/src/server/web/activities.gleam`)

- `ActivityInput.title`/`description` → `BilingualString`; the decoder reads them via
  `model.bilingual_string_decoder()`. (Add `import shared/model.{type BilingualString}`
  as needed — see how `web/location.gleam` does it.)
- `create`/`update` handlers: pass `input.title.sv`, `input.title.en`,
  `input.description.sv`, `input.description.en` into the `sql.create_activity_*` /
  `sql.update_activity_*` calls (both max_attendees branches).

### 6. Client (`client/src/client.gleam`) — largest surface

- **Card** (`view_activity_card`, ~line 1990): title becomes
  `localized(translator, summary.title)`.
- **Detail** h1 (~2209): `localized(translator, activity.title)`; description
  paragraph (~2292): `localized(translator, activity.description)`.
- **Search filter** (~2710): match `needle` against both
  `localized`-independent variants, e.g. lowercased `summary.title.sv` **and**
  `summary.title.en`.
- **`to_summary`** (~529): `title: a.title` (both are `BilingualString` now — no
  reconstruction, like `location_name` after b37634a).
- **Create/edit form** — this is the new work vs locations:
  - `ActivityForm` type and its form fields currently carry flat `title`/`description`
    strings (see `form.add_string("title", …)` ~630-631, the form-to-JSON encoder
    ~1581-1582, and `view_activity_new` / the edit view). Add `title_en` and
    `description_en` inputs; the submit payload must send nested
    `{ "title": {"sv":…, "en":…}, "description": {"sv":…, "en":…} }` to match
    `ActivityInput`.
  - Prefill for edit: `form.add_string("title", activity.title.sv)` +
    `"title_en"` from `activity.title.en`, etc.
- **Tests** (`client/test/client_test.gleam`): `an_activity` / `a_summary` build
  `title` as `model.BilingualString(sv:, en:)` now.

### 7. OpenAPI (`server/priv/static/openapi.yaml`)

- `Activity` schema: `title` and `description` → `$ref: '#/components/schemas/BilingualString'`.
- `ActivitySummary` schema: `title` → `$ref BilingualString`.
- `ActivityInput` schema: `title`/`description` → `$ref BilingualString`.
- The `BilingualString` schema already exists — just reference it. Update the inline
  request/response **examples** in the `/activities` paths (they currently show flat
  string titles).

### 8. Seed data (`server/priv/seeding/activities.sql`)

If `title_en`/`description_en` are `NOT NULL`, fresh-DB seed INSERTs (~31 activities)
will fail unless they provide the new columns. Add English values (or at minimum
`title_en`/`description_en` mirroring the Swedish) to the seed INSERTs so `./seed.sh`
works on a clean DB. (The migration backfill only covers rows already present.)

## Verification

1. `gleam run -m cigogne up`; `gleam run -m squirrel`.
2. `gleam format` in `server/`, `client/`, `shared/`.
3. `cd server && gleam test`; `cd client && gleam test`.
4. Reseed a clean DB via `./seed.sh` (confirm NOT NULL columns don't break inserts).
5. `./start.sh`, then in the browser: card + detail titles/description switch when
   `<html lang>` flips sv↔en; the create/edit form saves both languages; search finds
   an activity by its English title.
6. `curl` a detail + summary response → `title`/`description` are `{sv,en}`; POST/PUT
   an activity with a nested body round-trips; `/api/docs` reflects the new shapes.

## Gotchas

- Migrations **must** be scaffolded with `gleam run -m cigogne new` (root CLAUDE.md).
- `sql.gleam` is generated — never hand-edit; regenerate with squirrel.
- Keep the API contract in `openapi.yaml` in sync in the same change (server CLAUDE.md).
- The DB columns stay flat (`title`, `title_en`, …); only the API/domain shape nests
  into `{sv,en}` — same split as locations.

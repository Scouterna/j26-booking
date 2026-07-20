# 24. Bulk edit beach bus & climbing wall shared fields (issue #31)

> **Status: ✅ Done 2026-07-20** (implemented as planned; verified end-to-end —
> API set/clear/403/404 paths curl-tested, UI flow driven in the browser)

## Context

Beach bus (badbuss) and climbing wall (klättervägg) are stored as many
individual `activity` rows marked with `recurring_activity_kind`
(`'beach-bus'` / `'climbing-wall'`). Every slot duplicates the shared
title/description and points at the same location; slots differ only in
start/end time and capacity. Plan 03 deferred "shared-text editing" — today a
manager must open each slot one at a time in the edit drawer to fix a typo in
the description, once per slot.

Issue #31 asks for an interface + backend to bulk edit these. Scope decided
with the user (2026-07-20):

- **Fields**: title (sv/en), description (sv/en), location — the shared,
  duplicated fields only. Per-slot times/capacity, slot generation, and bulk
  delete are out of scope for now.
- **UI**: an edit control on the Badbuss/Klättervägg tabs of the *management*
  list (`/activities/manage`), opening the existing drawer pattern.
- **Permissions**: same as single-activity editing (`activities:manage`,
  admin implies).
- **API**: kind-scoped endpoint — one `UPDATE … WHERE recurring_activity_kind
  = $1`, not an id-list endpoint.

## Server

### SQL (`server/src/server/sql/`, then `gleam run -m squirrel`)

- `update_recurring_activities.sql` — set `title`, `title_en`, `description`,
  `description_en` on every row `WHERE recurring_activity_kind = $1`,
  `RETURNING id` (the row count feeds the response).
- `set_recurring_activities_location.sql` / 
  `clear_recurring_activities_location.sql` — location written separately,
  mirroring the per-activity `set_activity_location` / `clear_activity_location`
  convention (squirrel params can't be optional).

### Handler (`server/src/server/web/activities.gleam`)

`pub fn update_recurring(req, kind_segment, ctx)`:

- `Put` + `with_authenticated_user` + `require_role(ActivitiesManage)`.
- Parse the path segment into a small `RecurringActivityKind` custom type
  (`BeachBus | ClimbingWall`); unknown kind ⇒ 404.
- Decode `{title: {sv,en}, description: {sv,en}, location_id?: uuid|null}`
  (subset of `ActivityInput`); validate `location_id` via the existing
  `with_locations` + `require_valid_location`.
- One transaction: bulk UPDATE + set/clear location by kind.
- Respond `200 {"updated": <row count>}` (0 is fine — idempotent, no 404).

### Router

```gleam
Put, ["recurring-activities", kind] -> activities.update_recurring(req, kind, ctx)
_, ["recurring-activities", _] -> wisp.method_not_allowed([Put])
```

### OpenAPI (`server/priv/openapi.yaml`)

Add `PUT /api/recurring-activities/{kind}` (kind enum `beach-bus` |
`climbing-wall`), request body schema, `{"updated": int}` response, 400/401/
403/404 errors.

## Client (`client/src/client.gleam`)

- New `ActivityFormState` variant:
  `ActivityFormBulkEdit(kind: RecurringKind, state: BulkEditState)` with
  `BulkEditState = BulkEditLoading(seed: Uuid) | BulkEditReady(form: Form(BulkEditForm), submit_error: Option(AppError))`
  and `BulkEditForm(title, title_en, description, description_en)`.
- **Open**: on the manage page with TabBeachBus/TabClimbingWall active and a
  non-empty loaded list, show a "Redigera alla pass" button. It carries the
  first listed slot's id as the seed:
  `UserClickedBulkEditRecurring(kind, seed_id)` → `BulkEditLoading(seed)` +
  `fetch_activity(seed)`. The existing `ApiReturnedActivity` handler grows a
  case that seeds the bulk form (and `edit_ui.location_id`) when the bulk
  state is waiting on that id — the slots share these fields, so any slot
  seeds correctly.
- **Form view**: rendered inside `view_activity_form_drawer` — the sv/en
  segmented toggle (reusing `edit_ui.language` + `language_needing_attention`,
  generalized to `Form(a)`), title/description fields, the existing location
  picker, a callout noting the change applies to *every* slot of the kind,
  and a save button.
- **Submit**: `UserSubmittedBulkEditForm(Result(BulkEditForm, Form(BulkEditForm)))`
  → `PUT /api/recurring-activities/:kind` with
  `{title, description, location_id}`; response decoded as `{"updated": int}`.
- **On success**: drop the `details` cache entries for every id cached in that
  source's windows (their description/location changed), then
  `close_form_and_refresh` (summaries revalidate via ETags). On failure: keep
  the drawer open with `BulkUpdateActivitiesFailed` shown.
- **i18n** (en + sv): bulk-edit button/heading, applies-to-all note,
  `error.bulk_update`.

## Files to modify

- `server/src/server/sql/update_recurring_activities.sql` (new)
- `server/src/server/sql/set_recurring_activities_location.sql`, `clear_recurring_activities_location.sql` (new)
- `server/src/server/sql.gleam` (regenerated)
- `server/src/server/web/activities.gleam`
- `server/src/server/router.gleam`
- `server/priv/openapi.yaml`
- `client/src/client.gleam`

## Verification

1. `gleam run -m squirrel` regenerates cleanly; `gleam format` both packages.
2. `gleam test` (server/) passes.
3. `./start.sh` with `DEV_AUTH_ROLES=admin`: on `/activities/manage`, Badbuss
   tab → "Redigera alla pass" opens the drawer pre-filled; saving a new
   description updates every badbuss slot (check another day + a slot detail
   page); klättervägg slots untouched.
4. Location change propagates to all slots; clearing it works.
5. Non-manager gets 403 from the endpoint; unknown kind 404s.

# 14. Show group free-text on recurring-booking slot cards

> **Status: 🔲 Not started** (as of 2026-07-18)

## Context

On the Badbuss/Klättervägg recurring-bookings overview, each slot card lists the
groups that booked it — currently just the kår name (`group_name`, or "Okänd
grupp" when there's no kår) with a participant count. Each row should also show
the booking's **group free text** (the patrol/group the booker typed), formatted
as `group_name | free_text`, and truncated with an ellipsis when it overflows the
card width. When the free text is an empty string, show no divider (just the
name).

Today the free text never reaches the client for this view: the overview
aggregates bookings into `GroupCount` rows keyed by `(group_id, group_name)`, and
`GroupCount` has no free-text field. So this change plumbs `group_free_text`
through the whole stack (SQL → row → `GroupCount` → JSON → client) and renders it.

**Aggregation consequence (intended):** adding `group_free_text` to the overview
`GROUP BY` means each distinct `(kår, free_text)` becomes its own row. Two
bookings from the same kår with different patrols — previously merged into one
summed row — will now appear as two rows. `total_booked` per slot is unchanged.
This is the correct granularity for a "who booked this slot" view and is what
makes per-row free text meaningful.

## Changes

### 1. Shared model — carry the field (`shared/src/shared/model.gleam`)
- Add `group_free_text: String` to the `GroupCount` type (~line 447), mirroring
  `Booking.group_free_text` (non-optional String).
- `group_count_decoder()` (~451): `use group_free_text <- decode.field("group_free_text", decode.string)`.
- `group_count_to_json()` (~533): add `#("group_free_text", json.string(group_free_text))`.
  This is the single encode/decode path used by both the server response
  (`booking_slot_to_json` → `group_count_to_json`) and the client decoder.

### 2. SQL — surface & group by free text (`server/src/server/sql/list_recurring_bookings_overview.sql`)
- Add `b.group_free_text` to the `SELECT` list and to the `GROUP BY`.
- Add `b.group_free_text` as a final `ORDER BY` tie-breaker (after
  `booker_group_name`) for stable row order.
- Update the leading comment to note rows are now per `(group, free_text)`.
- Regenerate: `cd server && gleam run -m squirrel`. Because of the `LEFT JOIN`,
  `ListRecurringBookingsOverviewRow.group_free_text` will be generated as
  `Option(String)` (nullable), even though the base column is `NOT NULL`.

### 3. Server model — map row → GroupCount (`server/src/server/model/booking.gleam`)
- In `overview_chunk_to_slot` (~128), add
  `group_free_text: option.unwrap(row.group_free_text, "")` to the `GroupCount`
  construction. Rows reaching this map already have `booking_count > 0`, so the
  value is present; the `unwrap` just satisfies the `Option` from the LEFT JOIN.
- Uses the already-imported `gleam/option` (currently `import gleam/option.{None}`;
  call as `option.unwrap`).

### 4. Server tests (`server/test/server/model/booking_test.gleam`)
- `row` helper (~13): add a `group_free_text: option.Option(String)` parameter and
  pass it into `ListRecurringBookingsOverviewRow`.
- Update the three `model.GroupCount(...)` literals (lines ~51, 52, 86) to include
  the new positional field, and update `row(...)` call sites to pass a free text.
  Add/adjust an assertion so a booking's free text carries through.

### 5. Client — render `name | free_text`, truncated (`client/src/client.gleam`)
In `view_slot_card` (~5089), where each group row renders the name span:
- Build the label:
  ```gleam
  let label = case group.group_free_text {
    "" -> group_display_name(translator, group)
    free_text -> group_display_name(translator, group) <> " | " <> free_text
  }
  ```
- Render it in the existing name span, changing its class from
  `text-body-l break-words` to `text-body-l truncate min-w-0` so it ellipsizes
  instead of wrapping. `min-w-0` lets the flex child shrink below its content
  width; the count span stays `shrink-0`, so the label truncates to fit.
- `group_display_name` (~5117) is unchanged (still name-only); the free text is
  appended only here.

### 6. OpenAPI (`server/priv/static/openapi.yaml`)
- In the `GroupCount` schema (~1830) add a `group_free_text` property:
  `type: string`, description "Free-text patrol/group the booker entered; empty
  string when none." Add it to `required` (it's always present in responses).
  The inline `examples` already show `group_free_text` on booking objects; no
  other schema edits needed.

## Verification

1. `cd server && gleam run -m squirrel` (regen), then `gleam format` in `server`,
   `shared`, and `client`.
2. `cd server && gleam test` — the updated `booking_test` aggregation tests pass,
   confirming free text carries through and empty groups still yield no rows.
3. Run the real app with dev auth + Docker Postgres (data already seeded on
   26 Jul: e.g. `Kår 1386 / Testpatrull34`, no-kår `/ Testpatrull`):
   ```sh
   ./start.sh   # or: set -a && . ./.env.sh && set +a && export DEV_AUTH_ROLES=admin && cd server && gleam run
   ```
   (client bundle must be built — `./start.sh` does it.)
4. Drive with the Playwright MCP browser to
   `http://localhost:8000/_services/booking/beach-bus`, select **söndag 26/7**
   (dispatch `scoutInputChange` with `detail.value = "2026-07-26"` on
   `scout-select[name="day"]`), and confirm each slot row shows
   `Kår 1386 | Testpatrull34`, `Okänd grupp | Testpatrull`, etc., with the count
   still right-aligned. Verify a long free text truncates with an ellipsis rather
   than wrapping or pushing the count off-card (temporarily widen a seeded
   `group_free_text` via `psql` if needed to force overflow). Confirm a booking
   with empty `group_free_text` shows just the name and no `|`.

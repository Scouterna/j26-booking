# 09. ETag revalidation for per-day activity lists

> **Status: 🔲 Not started** (as of 2026-07-16)

## Context

We are moving the browse lists from "load everything at once" to **day
windows** (see the day-windowing direction: Activities + recurring tabs are
day-paged and default to the clamped-to-event-range "today"; Favourites stays
"all"). Once a tab shows one day at a time, the client revisits the same day
repeatedly (tab switches, back-and-forth day navigation). We want those
revisits to be cheap: the client holds the day it already fetched and only
re-downloads it **if it changed**.

This is exactly HTTP conditional requests:

- The server returns an `ETag` header identifying the exact bytes of a day's
  response.
- The client stores that `ETag` per window and sends it back as
  `If-None-Match` on the next fetch.
- If nothing changed, the server replies **`304 Not Modified`** with no body;
  the client keeps its cached window and skips re-parsing/re-deriving.

### The enabling change: make the browse lists user-independent

Today the browse queries (`list_activities_by_start_time`,
`list_activities_by_title`, `list_beach_bus_activities`,
`list_climbing_wall_activities`) filter **call-off visibility by the requesting
user** — a called-off activity is hidden from everyone except managers and the
users who booked/favourited it
(`server/src/server/sql/list_activities_by_start_time.sql:4-11`). That makes the
same day return different bytes to different users, which weakens caching (an
ETag can only be shared between users who happen to get identical output).

**We are changing the model so the regular browse endpoints exclude called-off
activities entirely** (§1). The response then depends only on the data, not on
the caller, so a body-hash ETag is genuinely **shared across all users** — the
strongest possible caching. Personal data was never in the payload
(`summary_to_json` emits only activity fields — `id`, `title`, times,
`max_attendees`, `location_name`, `tags`, `target_groups`, `cancellation`);
removing the per-user *row filtering* is the last thing making it vary.

Two carve-outs preserve today's "you still see your called-off activity"
behavior:

- **Managers** need to see called-off activities on the manage page. An optional
  `include_call_offs=true` query parameter (manager-only) returns them. That
  response is still user-independent (it returns *everything* the same way for
  every manager), so it is also cacheable — just under a different URL.
- **The favourites endpoint always includes call-offs.** It already does — it
  selects the user's favourited + booked activities with no call-off filter
  (`list_favourited_activities.sql`). This is where a user sees that an activity
  they booked or favourited has been called off. It is inherently per-user, so
  its ETag is per-user too — correct via body-hash, and expected.

> **UX consequence (intentional).** A called-off activity you booked/favourited
> no longer appears in the main browse list; it appears under the **Favourites**
> tab (with its cancellation reason), and its detail page
> (`GET /api/activities/{id}`) still resolves. Confirm this is the desired flow
> before implementing — it is a deliberate behavior change, not just a caching
> tweak.

### Why a body-hash (strong) ETag

- After §1 the default browse response is identical for all users, so the
  hash is a shared validator with no bookkeeping.
- It captures **every** input to the payload (activity rows, tags,
  target-groups, resolved locations, and — in the manager view — call-offs)
  without tracking each one: any change that alters the output changes the hash.
- The cheap alternative (a `MAX(updated_at)` version column) is unnecessary now
  that the default response is user-independent, and there is no `updated_at`
  column today anyway.

Trade-off to accept explicitly: a body-hash still runs the query and serializes
JSON server-side — it saves **network bandwidth and client CPU** (re-parse +
re-derive), not server DB work. Given the dataset is a few hundred activities
that is the right call.

> **Dependency.** This plan is written against the day-windowed list endpoints
> (`?day=YYYY-MM-DD`). The §1 visibility change and the §2 ETag helper are
> independent of day-windowing and can land first; day-windowing then composes
> (its `day` param sits alongside `include_call_offs`).

---

## 1. Server — exclude call-offs from browse lists; add `include_call_offs`

### SQL (`server/src/server/sql/`)
Rewrite the three browse queries so call-offs are excluded by default and a
single boolean parameter opts them back in. Drop the per-user `user_id`
parameter and the favourite/booking `OR` clauses entirely — they are no longer
needed.

`list_activities_by_start_time.sql` (and identically `list_activities_by_title.sql`):
```sql
SELECT *
FROM activity
WHERE recurring_activity_kind IS NULL
    AND (
        $1 = TRUE
        OR NOT EXISTS (SELECT 1 FROM call_off c WHERE c.activity_id = activity.id)
    )
ORDER BY start_time ASC;   -- (title variant: ORDER BY title ASC)
```
`$1` is `include_call_offs`: `FALSE` → only non-called-off (the cacheable,
user-independent default); `TRUE` → all rows (manager view). Apply the same
shape to `list_beach_bus_activities.sql` and `list_climbing_wall_activities.sql`
(keeping their `recurring_activity_kind = '…'` predicate).

> **Assumption to confirm:** this applies to **all three** browse lists
> (Activities, beach bus, climbing wall), since the manage page covers all
> three tabs. If only the main Activities list should change, say so.

`list_favourited_activities.sql` — **unchanged** (already includes call-offs).

Then `cd server && gleam run -m squirrel` to regenerate `sql.gleam`, and
`gleam format`. The generated functions now take a single `Bool`
(`include_call_offs`) instead of `(can_manage, user_id)`.

### Handlers (`server/src/server/web/activities.gleam`)
`get_page`, `get_beach_bus`, `get_climbing_wall`:
- Keep `web.with_authenticated_user` (the API requires auth generally), but the
  call-off filtering no longer reads the user.
- Parse an optional `include_call_offs` query param (default `False`). Reuse the
  existing `web.ensure_valid_query_param` helper or a small bool parse.
- **Gate it:** if `include_call_offs=true`, require
  `web.require_role(user, web.ActivitiesManage)` (403 otherwise). A non-manager
  asking for call-offs is rejected rather than silently downgraded, so a cached
  default response is never mistaken for a manager view.
- Pass the resulting bool to the regenerated SQL function (replacing the old
  `can_manage, user.id` arguments).

`get_favourited` — unchanged behavior (still per-user, still includes
call-offs).

### OpenAPI (`server/priv/static/openapi.yaml`)
- Add the `include_call_offs` query parameter (boolean, default false,
  manager-only → document the `403`) to the browse list endpoints.
- Note the new default: browse lists **exclude** called-off activities;
  favourites include them.

---

## 2. Server — reusable ETag helper (`server/src/server/web.gleam`)

Add one helper that turns an already-serialized JSON body into either a
`200` + `ETag` or a `304`, based on the request's `If-None-Match`:

```gleam
import gleam/bit_array
import gleam/crypto
import gleam/http/request

/// Serve `body` as JSON with a strong ETag, or `304 Not Modified` if the
/// client's `If-None-Match` already matches.
pub fn json_response_with_etag(
  req: Request,
  body: String,
  status: Int,
  cache_control: String,
) -> Response {
  let etag = strong_etag(body)
  let response = case request.get_header(req, "if-none-match") {
    Ok(client_etag) if client_etag == etag -> wisp.response(304)
    _ -> wisp.json_response(body, status)
  }
  response
  |> wisp.set_header("etag", etag)
  |> wisp.set_header("cache-control", cache_control)
}

fn strong_etag(body: String) -> String {
  let digest =
    body
    |> bit_array.from_string
    |> crypto.hash(crypto.Sha256, _)
    |> bit_array.base16_encode
  "\"" <> digest <> "\""
}
```

Notes:
- `gleam_crypto` and `gleam/bit_array` are already dependencies (both targets).
- `wisp.response(304)` yields an empty-body response; a `304` must not carry a
  body.
- **Cache-Control differs by endpoint** (passed in by the caller):
  - Default browse list (user-independent, no personal data) → it is now
    *eligible* for shared caching. Recommended: `no-cache` (revalidate always)
    — or `private, no-cache` if you'd rather not let any proxy store it. Since
    the list still requires auth to fetch, keep `private, no-cache` unless there
    is a concrete shared cache to leverage; the client-side revalidation win is
    identical either way, and you can relax it later.
  - `include_call_offs=true` and favourites (per-user or manager-scoped) →
    `private, no-cache`, plus `Vary: Cookie`.
- Keep the `If-None-Match` comparison as an exact match against our single
  strong tag; fall through to `200` on anything else (the `_` arm).

Keep this generic (named for "JSON + ETag") so `GET /api/activities/{id}` and
other cacheable GETs can adopt it later.

## 3. Server — route the browse responses through the helper

In `activities.gleam`, `response_from_db_activity_summaries`
(`activities.gleam:118-135`) builds the JSON string then calls
`wisp.json_response`. Thread `req` (and the chosen cache-control) in and swap
that final call for `web.json_response_with_etag(...)`. Apply to `get_page`,
`get_beach_bus`, `get_climbing_wall`, and `get_favourited`. No further SQL or
model changes — the ETag is computed from the bytes the handlers already
produce.

## 4. Client — store an ETag per window and revalidate

The client already keeps a per-tab id window through the shared entity cache and
"shows the cache, then lets a refetch reconcile" (`client.gleam:725`). We add an
ETag beside each window and issue **conditional** fetches.

### Model
- Add `etags: Dict(WindowKey, String)` to the `Model` (or store the ETag
  alongside each existing window entry). Key by the fetch identity —
  `(source, day, include_call_offs)` for the browse tabs, `source` for
  favourites. Reuse whatever key type day-windowing introduces so the two align.
- Browse (`BrowseList`) fetches with `include_call_offs=false` (the default,
  cacheable). The manage view (`ManageList`) fetches with
  `include_call_offs=true`.

### Fetch (replace `fetch_list` for the cacheable sources)
`rsvp.get` + `expect_json` can't set a request header or observe a `304`, so
build the request explicitly and use the low-level handler:

```gleam
import gleam/http/request
import gleam/http/response.{type Response}
import rsvp

fn fetch_day(key: WindowKey, etag: Option(String)) -> Effect(Msg) {
  // rsvp.send loses the convenience helpers' automatic relative-URL
  // resolution, so resolve against the iframe base ourselves.
  case rsvp.parse_relative_uri(window_path(key)) {
    Error(_) -> effect.none()
    Ok(uri) ->
      case request.from_uri(uri) {
        Error(_) -> effect.none()
        Ok(base) ->
          base
          |> request.set_method(http.Get)
          |> set_if_none_match(etag)
          |> rsvp.send(rsvp.expect_any_response(fn(result) {
            ApiReturnedActivityWindow(key, result)
          }))
      }
  }
}

fn set_if_none_match(
  req: request.Request(String),
  etag: Option(String),
) -> request.Request(String) {
  case etag {
    Some(tag) -> request.set_header(req, "if-none-match", tag)
    None -> req
  }
}
```

`expect_any_response` hands us the raw `Response(String)` for **any** status,
which is what we need to read the `ETag` on `200` and recognize `304`.

### Message + update
Add `ApiReturnedActivityWindow(WindowKey, Result(Response(String), rsvp.Error))`.
In `update`, branch on the response:

- **`Ok(resp)`, `resp.status == 200`** — changed / first fetch:
  1. read the new tag: `response.get_header(resp, "etag")`;
  2. decode the body ourselves (`expect_any_response` does not check
     content-type or decode) via
     `json.parse(resp.body, model.activity_summaries_decoder())`;
  3. on success: merge summaries into the entity cache, set the window, store
     the ETag under the key. On a decode error, surface it like today's
     list-decode failures.
- **`Ok(resp)`, `resp.status == 304`** — unchanged: keep the cached window,
  clear its loading state; nothing to merge or re-derive.
- **`Error(_)`** — reuse existing list-fetch error handling.

### When to revalidate / invalidate
- When a window is shown, render the cached data immediately (if present) and
  still issue the conditional fetch — with a warm ETag that is a tiny `304`,
  so it stays fresh (stale-while-revalidate), consistent with the current
  show-cache-then-reconcile behavior.
- After a create/update/cancel/delete the body genuinely changes, so the next
  conditional request naturally returns `200` with a new ETag; no manual
  cache-busting needed. Double-check mutation handlers still trigger the
  refetch.

---

## Verification

1. **Server build/tests:** `cd server && gleam format && gleam test`.
2. **Visibility change (`curl`, against `./start.sh` on :8000):**
   - Seed/create an activity, then `POST` a call-off for it.
   - `GET /api/activities` (no param) → the called-off activity is **absent**,
     for a manager *and* a regular user (identical bytes → identical `ETag`).
   - `GET /api/activities?include_call_offs=true` as a **manager** → present;
     as a **non-manager** → `403`.
   - `GET /api/favourited-activities` as the user who favourited/booked it →
     present (with `cancellation`).
   - `GET /api/activities/{id}` → still resolves.
3. **Conditional round-trip:** capture the `ETag` from a browse `GET`; re-`GET`
   with `-H 'If-None-Match: <etag>'` → `304`, empty body. Change an activity in
   that set → re-`GET` with the old tag → `200` with a new `ETag`.
4. **Shared ETag:** confirm two different (non-manager) users get the **same**
   `ETag` for the same browse day.
5. **Client build:** `cd client && gleam run -m lustre/dev build`, or `./start.sh`.
6. **Manual (devtools / Playwright MCP at :8000):**
   - Navigate days/tabs; repeat visits show `304` in the Network panel and
     cards render instantly with no flicker.
   - A called-off activity you booked no longer shows in the main list but
     appears under Favourites.
   - Edit an activity, return to its day → the change appears (a `200`).
   - The manage view (include_call_offs) shows called-off activities.
7. **Review:** `gleam-reviewer` on changed server/client files; check
   `lustre-guide` (effects/messages) and `squirrel-conventions` (regenerated
   `sql.gleam`).

## Notes / risks

- **Behavior change, not just caching.** §1 removes called-off activities from
  the main browse lists for the users who booked/favourited them. Favourites is
  the compensating surface. Get explicit sign-off (the callout above).
- **`search_activities.sql`** is out of scope here — decide separately whether
  search should also exclude call-offs (likely yes, for consistency).
- **`rsvp.send` + relative URLs.** `send` does not auto-resolve relative URLs;
  use `parse_relative_uri` → `request.from_uri` and **verify it resolves inside
  the `/_services/booking` iframe**. Validate on one endpoint before converting
  all of them. Fallback: build from an absolute path.
- **`expect_any_response` gives up rsvp's guardrails** (2xx / content-type /
  decode). We take those on manually; wrap the 200/304/error branching in one
  small client helper, tested once.
- **304 must be bodyless** and still carry `ETag` + `Cache-Control`; don't route
  it through `wisp.json_response`.
- **Hashing cost is negligible** (SHA-256 over a few KB). `phash2` is faster but
  risks collisions and buys nothing here.
- **Deferred:** the default browse response is now eligible for genuinely
  *shared* (proxy) caching since it is user-independent and personal-data-free.
  We keep `private, no-cache` for now (access still requires auth); relaxing to
  a shared cache is a later, separate decision.
- **Keep the ETag helper generic** so the detail endpoint and others can adopt
  it later.
```

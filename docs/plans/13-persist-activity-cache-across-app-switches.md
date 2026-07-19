# 13. Persist the activity cache across app switches (instant reopen)

> **Status: 🔲 Not started** (as of 2026-07-17)

## Context

The booking SPA lives in an iframe inside the `j26-app` shell. Its whole cache —
the entity cache, the per-window id lists, and the revalidation ETags — lives in
the in-memory Lustre `Model`. When the user navigates to another sub-app the
iframe unmounts and that `Model` is gone; on the next open the app starts from
`init` with empty dicts, shows a loader, and refetches. The user's complaint:
"every time I reopen the booking app it reloads all activities."

We investigated this end-to-end (Playwright + server logs) and it produced two
findings worth recording, because they shape this plan:

1. **The bytes on reopen are already cheap.** Plan 09's ETag revalidation works:
   a reopen sends `If-None-Match` and the server returns `304` for the activity
   list. The list is *not* re-downloaded. (We also confirmed `Vary: Cookie` is
   inert for these `private, no-cache` responses — the browser revalidates on
   every use and the `304` decision is ETag-only, cookie-independent — so it is
   not the cause. Plan 09 already made the browse list user-independent, and a
   follow-up made `Vary: Cookie` conditional — set only on the per-user/manager
   variants, dropped on the shared list.)
2. **The pain is latency and paint, not bandwidth.** Two things still cost the
   user on reopen:
   - The shell service worker fronts `/_services/booking/api/*` with a
     **NetworkFirst** strategy, so it blocks the first paint on the revalidation
     round-trip (even a `304` is an RTT).
   - The SPA lost its in-memory `Model`, so it has nothing to paint *until* that
     round-trip returns — hence the loader/flicker.

This plan removes the loader on reopen by **persisting the browse cache to the
browser and hydrating the `Model` from it in `init`**, so the SPA paints
last-known activities immediately and the existing ETag fetch revalidates in the
background (stale-while-revalidate). It composes with — and does not depend on —
any change to the shell service worker.

### Why client-side persistence (and not a service-worker change)

The alternative is to change the shell SW (`j26-app`) from NetworkFirst to
StaleWhileRevalidate. That would help every sub-app but (a) is a cross-repo
change owned by another team, (b) affects signupinfo/notifications/platsbank
too, and (c) still doesn't give a *synchronous* first paint. Persisting the
cache in this repo is self-contained, benefits the booking app specifically,
reuses the `WindowKey`/`etags`/entity-cache machinery we already have, and works
even outside the PWA shell. If the shell later adopts SWR, the two stack
cleanly.

### Storage choice: `localStorage` (via `plinth`), not IndexedDB

The cached payload is slim: `ActivitySummary` records (`id`, bilingual title,
times, `max_attendees`, `location_name`, `tags`, `target_groups`,
`cancellation`) plus id lists and ETag strings — tens to low-hundreds of KB for
a whole jamboree, well under the ~5 MB `localStorage` budget.

- **`localStorage`** is synchronous, so we can read it **inside `init`** and
  populate the `Model` *before the first render* — a genuinely instant paint.
  Clean get/set, no transaction/event-model ceremony.
- **IndexedDB** is the right tool only if the dataset grows past a few hundred
  KB or main-thread cost becomes measurable; it is async, so hydration would
  arrive a few ms *after* first paint (via a message), not synchronously.

Both are native browser APIs and both are covered by **`plinth`** (the
established browser-bindings package, ~75k downloads): `plinth/javascript/storage`
for `localStorage`, `plinth/browser/indexeddb/*` for IndexedDB. Use `plinth`'s
`localStorage` for v1. Add it with `gleam add plinth` (never hand-edit
`gleam.toml`).

> If profiling later shows synchronous writes janking on large blobs, migrate
> the same serialized shape to IndexedDB behind the same persistence module — the
> `Model`-facing API below doesn't change, only the storage backend does.

---

## What to persist (and what not to)

Persist only what is **user-independent** and **safe to show stale-then-confirm**:

| `Model` field | Persist? | Why |
| --- | --- | --- |
| `activities: Dict(Uuid, ActivitySummary)` | ✅ | Entity cache; user-independent metadata; renders the cards |
| `windows: Dict(WindowKey, RemoteData(List(Uuid)))` | ✅ **`Loaded` only**, **non-favourites only** | The ordered id lists per browse day/tab; skip `Loading`/`Failed` |
| `etags: Dict(WindowKey, String)` | ✅ non-favourites only | Enables the `If-None-Match` `304` on reopen |
| `spots: Dict(Uuid, Int)` | ❌ | Must be fresh (changes on every booking); always refetch — explicit product decision |
| `statuses: Dict(Uuid, ActivityStatus)` | ❌ (v1) | Per-user; small and cheap to refetch; avoid a cross-user leak on shared devices |
| `activity_tags`, `locations` | ➕ optional | User-independent vocab fetched once; nice easy win, can piggy-back on the same blob |
| `details`, `page`, `translator`, `roles`, `edit_ui`, day filters | ❌ | Transient / per-view / cheap / already handled elsewhere |

**Favourites carve-out.** `SourceFavourites` windows are per-user, and the
favourited entity summaries are per-user. Membership of the Favourites tab is
already *derived from `statuses`* (`client.gleam:672-673`), which we refetch, so
excluding favourites from persistence costs nothing and avoids showing user A's
favourited activities to user B on a shared device. **Filter persisted windows to
`source != SourceFavourites`.** (A more complete alternative — namespacing the
whole blob by user id — is noted under Risks; not needed for v1.)

---

## 1. Add the persistence module

Create `client/src/client/cache_store.gleam` (single, focused module — do not
fragment). It owns the storage key, the schema version, and the encode/decode of
the persisted slice. Public API, storage-backend-agnostic:

```gleam
/// The persisted slice of the Model. Only user-independent, stale-safe fields.
pub type PersistedCache {
  PersistedCache(
    activities: Dict(Uuid, ActivitySummary),
    windows: Dict(WindowKey, List(Uuid)),   // Loaded ids only
    etags: Dict(WindowKey, String),
  )
}

/// Read + decode the persisted cache synchronously (localStorage). Returns
/// `Error(Nil)` when absent, unparseable, or a stale schema version — callers
/// then start empty. Never panics.
pub fn load() -> Result(PersistedCache, Nil)

/// Encode + write the cache. Fire-and-forget effect; storage errors (quota,
/// disabled storage) are swallowed — persistence is best-effort.
pub fn save(cache: PersistedCache) -> Effect(msg)
```

Implementation notes:

- **Backend:** `plinth/javascript/storage` — `storage.local()` then
  `storage.get_item` / `storage.set_item`. Wrap writes so a thrown quota error
  (Safari private mode, full disk) is caught and ignored.
- **Schema version:** store `{ "v": 1, ... }`; on `load`, if `v` ≠ current,
  return `Error(Nil)`. Bump `v` whenever `ActivitySummary` or `WindowKey`
  serialization changes so old blobs are discarded, never mis-decoded.
- **Storage key:** a booking-specific constant (e.g. `"j26_booking_cache_v1"`) —
  the origin is shared with other sub-apps, so namespace it.
- **`WindowKey` serialization.** `WindowKey = #(ActivityListSource,
  Option(calendar.Date), Bool)` (`client.gleam:402-403`). It's a dict key, so
  encode it as a stable string (e.g. `"activities|2026-07-25|false"`) and decode
  back. Add `window_key_to_string` / `window_key_from_string` here (or reuse the
  path builder that already renders these keys for fetches, keeping one source of
  truth for the encoding).
- **`ActivitySummary` codec.** The client currently only *decodes* summaries
  (for window responses). Add an **encoder** — mirror the server's
  `activity.summary_to_json` shape so the persisted JSON matches the wire format
  and can share the existing summary decoder on load. Bilingual strings, times
  (`gleam_time`), uuids (`youid`), tags, target groups, and the optional
  `cancellation`/`location_name` all need round-tripping — cover them in one
  place with tests.

## 2. Hydrate the `Model` in `init`

In `init` (`client.gleam:~1297-1346`), before constructing the `Model`, call
`cache_store.load()`:

- **On `Ok(cache)`** — seed the `Model`:
  - `activities: cache.activities`
  - `windows:` the persisted ids as `Loaded(ids)`, i.e.
    `dict.map_values(cache.windows, fn(_, ids) { Loaded(ids) })`, **then**
    overlay the `initial_key` — but instead of forcing it to `Loading`, keep the
    hydrated `Loaded` if present so it paints instantly.
  - `etags: cache.etags`
- **On `Error(_)`** — keep today's empty dicts + `initial_key -> Loading`
  (unchanged behavior).

Crucially, **still fire `fetch_window(model, initial_key)`** either way. When the
window is hydrated, `fetch_window` already sends the stored ETag as
`If-None-Match` (`client.gleam:~2558-2600`), so the revalidation is a cheap
`304`. Net: instant paint from cache, background confirm. `fetch_spots()`,
`fetch_statuses()`, `fetch_me()` continue to run unconditionally (fresh
per-user/volatile data), matching the "don't persist spots/statuses" decision.

> Keep `init` readable: extract a small `hydrate_model(base_model, cache)` helper
> rather than inlining dict gymnastics into the record literal.

## 3. Persist on every successful window load

The single write site is the window-result handler. In `update`, the
`ApiReturnedActivityWindow(key, WindowLoaded(...))` branch (`client.gleam:~1463`)
already merges summaries into `activities`, sets the window `Loaded(ids)`, and
stores the new ETag. After it produces the new `model`, batch a
`cache_store.save(...)` effect built from the **post-update** model:

```gleam
ApiReturnedActivityWindow(key, WindowLoaded(items, etag)) -> {
  // …existing merge/set/etag logic → `model2`…
  #(model2, cache_store.save(persisted_of(model2)))
}
```

where `persisted_of(model)` projects the persisted slice and applies the
**non-favourites filter** on `windows`/`etags`. `WindowUnchanged` (a `304`) needs
no write — nothing changed. This whole-slice write is simple and cheap at this
data size; if writes ever show up in a profile, debounce with a short
`effect.after_paint` timer, but don't add that complexity pre-emptively.

Optionally also persist after `ApiReturnedActivityTags` / `ApiReturnedLocations`
if you include the vocab (see the optional row above) — same pattern.

## 4. Invalidation

No manual cache-busting is needed for correctness — the ETag path handles it: a
create/update/cancel/delete changes the body, so the next conditional fetch
returns `200` with a new ETag and `save` overwrites the persisted window. Just
confirm mutation handlers still trigger the refetch (they do today via
`invalidate_browse_windows`, `client.gleam:~770`), so the stale persisted copy is
replaced on the following load.

Add a `cache_store.clear()` and call it on an explicit sign-out if/when the app
grows a logout affordance inside the iframe (today auth is shell-owned). Not
required for v1 given the favourites carve-out, but note it.

## 5. Failure handling — keep stale data, warn you might be offline

Persistence changes what a **failed revalidation** must do. Today a window on
reopen starts `Loading`, so a failed fetch → `Failed` is fine (there was no data
to lose). Once we hydrate, the window starts `Loaded(ids)` and paints instantly —
so the current handler, which overwrites unconditionally, would **wipe the
just-shown list and replace it with an error** exactly when the network is bad
(poor reception in the field), which is when showing saved data matters most:

```gleam
// client.gleam:1480 — current, destructive:
ApiReturnedActivityWindow(key, WindowFailed) -> #(
  set_window_remote(model, key, Failed(LoadActivitiesFailed)),
  effect.none(),
)
```

This section makes a failed *refresh* non-destructive (true
stale-while-revalidate) and surfaces a small callout so the user knows they're
looking at saved, possibly-stale data. It is a correct improvement even without
persistence, but persistence makes it **required**.

### Model — track which shown windows failed their last refresh

Add a field to `Model` (`client.gleam:661`) and seed it empty in `init`
(`client.gleam:~1303`):

```gleam
// Windows currently showing cached data whose last revalidation failed
// (e.g. offline). Drives the "showing saved activities" callout; cleared as
// soon as a later revalidation succeeds (200 or 304).
stale_windows: Set(WindowKey),
```

(`import gleam/set`; `stale_windows: set.new()` in `init`.) A `Set` keyed by
`WindowKey` — rather than a single bool — so the callout only shows for the
window you're actually viewing, and switching to a fresh tab/day doesn't inherit
another window's warning.

### Update — branch `WindowFailed` on whether we already have data

```gleam
ApiReturnedActivityWindow(key, WindowFailed) ->
  case window_remote(model, key) {
    // A failed *refresh* must not wipe data we're already showing. Keep the
    // stale window (and its ETag, so the next attempt still revalidates) and
    // flag it so the list shows the offline callout.
    Loaded(_) -> #(
      Model(..model, stale_windows: set.insert(model.stale_windows, key)),
      effect.none(),
    )
    // No data to show → the usual error state (unchanged behavior).
    NotAsked | Loading | Failed(_) -> #(
      set_window_remote(model, key, Failed(LoadActivitiesFailed)),
      effect.none(),
    )
  }
```

Clear the flag on any success, in both existing branches:

- `WindowLoaded` (`client.gleam:1463`) — refresh succeeded with new data:
  `stale_windows: set.delete(model.stale_windows, key)`.
- `WindowUnchanged` (the `304`, `client.gleam:1478`) — data confirmed current:
  same `set.delete`, so a `304` after a blip removes the callout.

### View — a small callout above the list

In the activities list view, when the **current** window key is in
`model.stale_windows` (and the window is `Loaded`), render a `scout-callout`
(see the `web-components` skill; use the warning/info variant) **pinned to the
top of the list's scroll viewport** — `position: sticky; top: 0` (plus a
`z-index` above the cards), as the first child of the scrolling container.

> **Pin it, don't just place it.** The failure is an event, but the user may be
> scrolled well down the list when it fires. A callout rendered as a normal
> first child would be off-screen and never seen. Sticky positioning keeps it
> visible at the top edge of the viewport regardless of scroll position; because
> `stale_windows` is level-triggered (set until a revalidation succeeds), the
> callout appears in place the moment the state flips on and disappears on
> recovery — no scroll-to-top or toast needed (and Scouterna UI has no
> toast/snackbar component anyway). Mind the shell app bar: `top: 0` pins to the
> top of the iframe's scroll area, which sits below the app bar — verify it isn't
> obscured.

Keep it compact — a title plus one line, e.g.:

- **sv:** "Du kanske är offline" / "Visar sparade aktiviteter — de kan vara
  inaktuella."
- **en:** "You might be offline" / "Showing saved activities — they may be out
  of date."

Add the two keys to the g18n translation files (both `sv` and `en`) and resolve
them via the model's `translator`. The view already derives the current
`WindowKey` from the active tab + day to look up the window it renders; reuse
that key for the membership check. Non-dismissible for v1 (it auto-clears the
moment a revalidation succeeds); a dismiss affordance (`scoutDismiss`) is an
optional later nicety.

> Scope: the callout is for the browse/list windows this plan persists. The
> per-user surfaces (favourites/statuses/spots) keep their existing loading/error
> handling.

---

## Verification

1. **Build/tests:** `cd client && gleam format && gleam test`. Add unit tests for
   `cache_store`: `WindowKey` string round-trip, `ActivitySummary` encode→decode
   round-trip (incl. `None` location, `Some(cancellation)`, bilingual fields),
   and `load()` returning `Error` on a bumped schema version / garbage blob.
2. **Instant reopen (Playwright MCP against `./start.sh`, via `local.j26.se`):**
   - Open the Activities tab, let it load.
   - Navigate to another shell app (e.g. `/notifications`), then back to
     `/app/booking/activities`.
   - **Expect:** cards render immediately with no loader/flicker, and the Network
     panel shows the list request resolving as a `304` (server log:
     `304 GET /_services/booking/api/activities`). Contrast with `main`, which
     shows a loader then a `200`/`304` after the round-trip.
3. **Persistence inspection:** in devtools Application → Local Storage, confirm a
   single `j26_booking_cache_v1` key holds the entity cache + non-favourites
   windows + etags, and **no** `spots`/`statuses`/favourites data.
4. **Freshness:** edit an activity (manager), reopen the app → the change appears
   (the reopen revalidates to `200` with a new ETag, and the persisted blob
   updates).
5. **Spots stay fresh:** book/cancel to change spot counts, reopen → spot numbers
   reflect the fresh `fetch_spots()`, not a persisted value.
6. **Offline / failed revalidation (Playwright, devtools offline or a blocked
   route):** with a persisted cache, go offline, then reopen the app →
   **cards still render** (stale data retained, not wiped) and the "you might be
   offline" callout shows above the list. **Scroll down the list first, then
   trigger the failure → the callout is still visible (pinned), not scrolled
   off.** Go back online and revisit → the callout disappears on the next
   successful revalidation (`200`/`304`), and the window is **not** left in an
   error state. Confirm a *cold* offline load (no persisted cache, no SW copy)
   still shows the normal error state.
7. **Schema bump:** change `v` to 2, reload → old blob is discarded, app starts
   empty and repopulates (no decode crash).
8. **Storage disabled:** simulate `localStorage` throwing (private mode / stubbed
   FFI) → app still works, just without persistence (no crash).
9. **Review:** `gleam-reviewer` on changed client files; check `lustre-guide`
   (effects in `init`/`update`, keeping `update` pure) and `gleam-conventions`
   (module placement, `x_to_y` naming, no premature fragmentation).

## Notes / risks

- **This is a UX/latency change, not a bandwidth one.** Plan 09 already made
  reopen bytes cheap (`304`). The win here is *instant paint* — set expectations
  accordingly; the reopen network request still happens (and should, to
  revalidate).
- **Shared-device favourites leak** is avoided by excluding `SourceFavourites`
  from persistence. If you ever persist per-user data (favourites/statuses),
  namespace the storage key by user id (from `/api/me`) or `clear()` on logout —
  otherwise user B could momentarily see user A's data before revalidation.
- **A failed revalidation must not wipe hydrated data.** Hydration makes the
  window start `Loaded`, so the current destructive `WindowFailed` handler would
  regress to an error state on a bad network — the exact case where saved data is
  most useful. §5 makes the refresh non-destructive and shows an offline callout;
  it is a prerequisite, not an optional polish.
- **Treat storage as a cache, not truth.** Browsers evict `localStorage`/IDB
  under pressure and it can be disabled; every read path must fall back to
  "fetch fresh." The ETag revalidation guarantees correctness regardless of
  staleness.
- **Serialization must round-trip exactly** or the schema version must bump.
  A silent shape drift that still decodes could render wrong cards; prefer a
  strict decoder that fails (→ discard) over a lenient one.
- **`ActivitySummary` encoder is new.** Keep it byte-compatible with the server's
  `summary_to_json` so the same decoder serves both wire and storage, and test
  the round-trip.
- **Independent of the shell SW.** Hydration only pre-fills the `Model`; the
  actual fetch still traverses the shell's NetworkFirst route. If the shell later
  switches to StaleWhileRevalidate, this still holds and the two compound.
- **Scope:** v1 persists the browse windows (+ optional vocab). Detail views,
  statuses, and spots remain fetch-on-demand by design.

---

## Environment & investigation notes (verified 2026-07-17)

Findings from an end-to-end investigation (Playwright + server logs) that will
save the implementer time — especially for the Verification steps.

### Two cache layers sit between the SPA and the server

1. **Browser HTTP cache.** It stores the `private, no-cache` + ETag list
   responses and revalidates them to `304` on every use — *independently* of
   `Vary: Cookie`, which is **inert** for `no-cache` responses (revalidation is
   unconditional and the `304` decision is ETag-only, cookie-independent; even
   changing a cookie value still produced a `304`). So reopen bytes are already
   cheap; this plan is about paint, not bytes.
2. **The shell service worker** (`j26-app`). The **deployed** `sw.js` is *not*
   the same as that repo's working-tree source — read the served file. It fronts
   `/_services/(booking|signupinfo|notifications)/api/` with **NetworkFirst**,
   `networkTimeoutSeconds: 5`, `cacheName: "subapp-api"`, `maxEntries: 200`,
   `maxAgeSeconds: 86400`. On a slow network it falls back to its own cached
   `200` after 5s.

**Implication for §5:** a timed-out revalidation often returns the SW's cached
`200` → `WindowLoaded` (not `WindowFailed`), so the offline callout fires only
when the SW *also* has no copy (evicted / hard offline / no SW controlling).
`localStorage` and the SW cache are two independent fallbacks — don't assume the
callout appears on every network blip; force a true miss to test it.

### Measurement traps (use the server log as ground truth)

- **`transferSize` is unreliable** — Chrome reports a padded ~300 bytes for any
  cache-served response, so it cannot distinguish a `304` revalidation from a
  full download. Read the **server log** (`304` vs `200 GET …/api/activities`)
  to know what actually happened.
- **The SW masks page-level timing** — SW-served responses show
  `deliveryType: "cache"`, `transferSize: 0` regardless of the underlying
  behavior. To measure the *raw* HTTP cache, `navigator.serviceWorker` →
  `unregister()` **and** navigate to a non-app same-origin page (e.g. the raw
  JSON at `/_services/booking/api/app-config`) so the app doesn't immediately
  re-register the SW.
- **Playwright does NOT disable the HTTP cache here** — verified (a non-SW font
  loaded with `deliveryType: "cache"`), so its cache behavior is representative
  of production, not a CDP artifact.
- **`browser_network_requests` accumulates** across SPA navigations and can show
  stale indices; prefer the server log for reopen measurement.

### Running it locally

- `./start.sh` builds the client and serves on `:8000`; reach the full shell at
  `https://local.j26.se` (Caddy proxies `/_services/booking` → :8000; booking is
  in "local" mode in j26-cli `services.yaml`, `rewritePath: false`). Requires the
  j26-cli docker stack (caddy, auth, db) running.
- **Auth:** either the real ScoutID login (creds in `.creds.local`), or set
  `DEV_AUTH_ROLES=admin` to authenticate tokenless `curl` as the seeded dev user.
  The dev var only applies when *no* cookie/bearer is present, so browser
  sessions still authenticate via the real cookie — the two don't interfere.

### Endpoint facts confirmed

- `/api/statuses/me` and `/api/activity-spots` send **no** caching headers (no
  ETag / no Cache-Control) — they always refetch in full, which is why they are
  excluded from persistence (and spots must stay fresh regardless).
- Favourites is `GET /api/favourited-activities` (per-user, `Vary: Cookie`).
- The manager list is a distinct URL `?include_call_offs=true`, cached separately
  from the default list; both are user-independent (role-scoped), only favourites
  and `statuses/me` are per-user.

# 23. Anonymous browsing: activities load without login (issue #20)

> **Status: ✅ Done 2026-07-20** (commit `TBD`; shipped as planned with small
> deviations: `fetch_me` kept `rsvp.expect_json` — the 401 is matched on
> `rsvp.HttpError(response)` in the `ApiReturnedMe` update arm instead of a
> new status-aware handler; the card corner got a `NoAction` variant in
> `component.gleam`; the anonymous Boka replacement lives inside
> `book_action` so the informational disabled states — Full, "Bokningen
> öppnar …" — still show to anonymous visitors; the anonymous default-view
> 200 is covered by live verification since handler tests have no database)

## Context

Issue #20 (High): "If not logged in, heart and booking information should not
be shown but activities should load fine. Currently activities won't load if
you are not logged in."

Two halves:

1. **Server**: the browse list endpoints require auth, so an anonymous visitor
   gets a 401 and the client renders a hard load error instead of the list.
2. **Client**: nothing is hidden for anonymous users — heart buttons and the
   Boka button render as usual, and their actions fail (favourite toggles
   revert, booking submits 401).

Issue #21 ("Not MVP: store favourites client side for not logged in users") is
the explicitly-deferred follow-up; this plan only makes browsing work and
hides the logged-in-only affordances.

### Current state (anchors, on top of `cc88fa7`)

- **Server — auth-gated GETs an anonymous visitor hits**:
  - `GET /api/activities`, `/api/beach-bus-activities`,
    `/api/climbing-wall-activities`: `web.with_authenticated_user` in
    `activities.gleam` (`get_page` :311, `get_beach_bus` :364,
    `get_climbing_wall` :385). The `user` is only used by
    `with_include_call_offs` (:54) to gate the manager-only
    `include_call_offs=true` view; the default response is already
    `SharedAcrossUsers` (:296).
  - `GET /api/me` (`account.gleam:18`), `GET /api/statuses/me`
    (`status.gleam:24`), `GET /api/favourited-activities`
    (`activities.gleam:413`): per-user by nature — the 401s are correct and
    stay.
- **Server — already public** (no guard): `GET /api/activities/:id` (:428),
  `/api/activity-tags`, `/api/activity-spots` (+ per-activity spots),
  `/api/locations` (+ tags), `/api/app-config` (anonymous callers get just
  the base activities nav item — `app_config.gleam:42`).
- **Client** (`client/src/client.gleam`):
  - Startup (`init` :1920, effects :1974-1992) fetches the browse window
    (`/api/activities?day=…`), spots, tags, locations, `/api/statuses/me`,
    `/api/me`. Beach-bus/climbing-wall/favourited lists load lazily on first
    tab open.
  - **Why the list "won't load"**: `activity_window_handler` (:3616) maps any
    non-2xx/304 — including the 401 — to `WindowFailed` (:3631) →
    `Failed(LoadActivitiesFailed)` (:2153) → `tab_summaries` derives
    `ListFailed` (:1466) → `view_activities_list` (:4214) renders a
    full-width error callout with Retry.
  - **Login state is implicit**: `/api/me` Ok sets `model.roles` and
    `model.booker` (:2207); *any* error (401 or network) sets `roles: []`,
    `booker: IdentityUnknown` (:2234). There is no anonymous-vs-error
    distinction. `/api/statuses/me` errors leave the statuses dict empty
    (:2248) — already graceful.
  - **Hearts**: `view_activity_card` (:4752) always renders
    `component.FavouriteAction` (:4796-4802); detail-page heart at :5288.
    Toggle 401 reverts optimistically (:3088) but the button still shows.
  - **Boka**: `book_action` (:5683) keys only on booking window + spots, not
    auth; an anonymous submit would 401.
  - Favourites tab membership derives from `model.statuses`; the lazy
    `fetch_favourited` (`/api/favourited-activities`) 401s for anonymous and
    would render the tab's error callout.

## Design decisions

- **The list endpoints become public.** Drop `with_authenticated_user` from
  `get_page`/`get_beach_bus`/`get_climbing_wall`. `with_include_call_offs`
  changes signature from `(req, user, next)` to `(req, ctx, next)`: the
  default `false` needs no user at all; `true` requires an authenticated user
  (401 otherwise) holding `ActivitiesManage` (403 otherwise). Caching is
  unaffected: the default body is byte-identical for everyone
  (`SharedAcrossUsers`), which now simply includes anonymous callers.
- **`/me`, `/statuses/me`, `/favourited-activities` keep their 401s** — they
  are per-user endpoints; anonymous handling belongs in the client.
- **The client models anonymity explicitly.** New custom type (no bare bool,
  per gleam-conventions):

  ```gleam
  pub type Session {
    /// /api/me has not answered (or failed for a non-auth reason).
    SessionUnknown
    /// /api/me returned 401: no token. Hide logged-in-only affordances.
    Anonymous
    LoggedIn
  }
  ```

  `fetch_me` switches to status-aware response handling (same
  `expect_any_response` pattern as `activity_window_handler` :3616): 401 →
  `Anonymous`; Ok → `LoggedIn` + today's roles/booker handling; other errors →
  `SessionUnknown` (keep today's degraded-but-visible behaviour so a flaky
  `/me` doesn't strip the UI for logged-in users). `roles` and `booker` stay
  as they are — `Session` is additive.
- **Hide, don't disable.** When `session == Anonymous`:
  - No `FavouriteAction` on browse cards or the detail page (hearts gone).
  - No Boka button in the detail actions; in its place a one-line hint
    ("Logga in för att boka" / "Log in to book") so the page doesn't just
    look broken. Booking info (Bokad/Avbokad chips, booker identity, my
    bookings) needs no work — it all derives from `model.statuses`, which
    stays empty for anonymous users.
  - The **Favourites tab is hidden** — with hearts hidden it can never gain a
    member, an always-empty tab is confusing, and its backing fetch would
    401 into an error callout. (Issue #21 will bring it back client-side.)
  - `SessionUnknown` and `LoggedIn` render exactly today's UI: hearts may
    flash in ~100ms later than the list for anonymous users, but logged-in
    users (the overwhelming majority) see no change or flicker.
- **Startup fetches stay unconditional.** `/api/statuses/me` and `/api/me`
  fire before anonymity is known and degrade gracefully; skipping them on
  `Anonymous` would only save one doomed request after the first answer.
  Not worth the sequencing complexity.

## Changes

### 1. Server (`server/src/server/web/activities.gleam`)

- `with_include_call_offs(req, ctx, next)`: on `true`, match
  `ctx.authentication_result` — `Authenticated(user)` with
  `web.has_role(user, web.ActivitiesManage)` → `next(True)`;
  authenticated without the role → 403; `NotAuthenticated | InvalidToken` →
  401. On absent/`false` → `next(False)` with no auth check.
- `get_page`, `get_beach_bus`, `get_climbing_wall`: drop
  `web.with_authenticated_user`; update the stale comment in `get_page`
  (:309-311) that says "the whole API requires auth".

### 2. Server tests (`server/test/`)

- Anonymous `GET /api/activities` (and the two recurring lists) → 200 with
  the same body a role-less authenticated user gets.
- Anonymous `GET /api/activities?include_call_offs=true` → 401;
  authenticated non-manager → 403 (exists today — keep it passing);
  manager → 200.

### 3. Client (`client/src/client.gleam`)

- **Model**: add `session: Session` (init `SessionUnknown`) next to `roles`
  (:1044).
- **`fetch_me`** (:3668): switch to status-aware handling; new/extended msg
  carries enough to distinguish 401. Update handler (:2207/:2234): Ok →
  `LoggedIn` (+ existing roles/booker/manager-refetch logic :2226-2230);
  401 → `Anonymous`; other → `SessionUnknown` (existing fallback
  behaviour).
- **Cards** (:4752): thread the anonymity down (the card builder already
  takes per-item config) — `Anonymous` → no `FavouriteAction`
  (:4796-4802). Same for the detail-page heart (:5288).
- **Detail actions** (`book_action` :5683 / `view_detail_actions`): when
  `Anonymous`, replace the Boka button with the login hint text.
- **Tabs** (`tab_summaries` :1410 / tab rendering): drop the Favourites tab
  when `Anonymous`. If the user somehow sits on it when the 401 lands (deep
  link), fall back to the browse tab.
- **Translations** (sv + en blocks): `booking.login_to_book`
  "Logga in för att boka" / "Log in to book".

### 4. Client tests (`client/test/client_test.gleam`)

- `/me` 401 → `session == Anonymous`; other error → `SessionUnknown`; Ok →
  `LoggedIn`.
- Card view with `Anonymous` renders no favourite action; with
  `SessionUnknown`/`LoggedIn` it does (today's behaviour pinned).
- Detail view with `Anonymous`: no Boka, hint text present.
- Favourites tab absent when `Anonymous`.

### 5. OpenAPI (`server/priv/openapi.yaml`)

- `GET /activities`, `/beach-bus-activities`, `/climbing-wall-activities`:
  mark as anonymous-accessible (`security: []` alongside the cookie scheme),
  document `include_call_offs=true` → 401 (anonymous) / 403 (no
  `activities:manage`).

### 6. Verification

- `gleam test` in `server/` and `client/`; `gleam format` everywhere.
- Live (`./seed.sh`, then `./start.sh` **with `DEV_AUTH_ROLES` unset** so
  tokenless requests are genuinely `NotAuthenticated`):
  1. `curl` without cookie: `GET /api/activities?day=…` → 200 + ETag;
     `include_call_offs=true` → 401; `/api/me`, `/api/statuses/me`,
     `/api/favourited-activities` → 401 still.
  2. Browser without token: activity list renders (no error callout), no
     hearts, no Favourites tab; detail page shows times/spots/location, no
     heart, hint instead of Boka.
  3. `DEV_AUTH_ROLES=bookings:self:create` (and again as `admin`): UI
     unchanged from today — hearts, Boka, Favourites tab, manage pages,
     call-off superset refetch all still work.

## Open questions

- **Login hint vs nothing**: the plan adds a one-line "Logga in för att boka"
  hint on the detail page. If a hint is unwanted (the shell may already push
  users to log in), just render no booking action — trivial to drop.
- **Should the hint link to the login flow?** The auth flow lives in the
  j26-app shell outside the iframe; if there is a shell navigation message
  for "go to login", the hint could be a link instead of plain text. Needs
  knowledge of the shell's capabilities — plain text is the safe default.

## Handoff notes

- The one subtle server bit is `with_include_call_offs`: the 401/403 split
  must not leak the manager view through a cached response — the default
  (`False`) branch stays cacheable `SharedAcrossUsers`, the `true` branch is
  already `ScopedToUser` via `list_audience` (:296). No cache changes needed.
- Don't gate hearts on `roles == []` — role-less *logged-in* users can
  favourite and book themselves; only `Anonymous` hides things.
- `UserToggledFavourite`'s optimistic-revert (:3067/:3088) stays as the
  safety net for the `SessionUnknown` window.
- Commit should include `Closes #20`.

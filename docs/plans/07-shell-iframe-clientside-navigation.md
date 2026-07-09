# 07. Client-side shell→iframe navigation (no SPA reload on back)

> **Status: 🔲 Not started** (as of 2026-07-09)

Cross-repo plan: touches both **j26-app** (React shell) and **j26-booking**
(Lustre sub-app). The plan file lives here, but the shell changes land in the
`j26-app` repo.

## Context

The booking SPA runs in a same-origin iframe inside the j26-app shell. Forward
navigation *out of* the iframe is already reload-free: the booking client posts
`j26:navigate` on every `OnRouteChange` (`client.gleam:862`), and the shell
mirrors it into TanStack Router history **without** touching `iframe.src`
(guarded by `iframeInitiatedUrl`, `IframeRouter.tsx:38-50`).

The reverse direction is the problem. When the shell URL changes for any
*external* reason — the app back button (`AppBar.tsx:106` → `router.history.back()`),
the browser back button, or Android/iOS native back (all bottom out at
`window.history.back()`) — the shell reacts by reassigning the iframe's `src`:

```ts
// IframeRouter.tsx:44-49  — the culprit
if (iframeRef.current.contentWindow?.location.href !== url) {
  iframeRef.current.src = url;   // full document load = SPA cold reload
}
```

Reassigning `src` is a cold document load. That is the reload seen on back.

Because all three back affordances trigger a `popstate` that TanStack observes
(they never call the app's button handler), **the fix must live in the shell's
reaction to the URL change (this effect), not in any button handler** — a
button-only fix would leave browser/OS back still reloading.

## Design (solution B)

Replace the `src` reassignment with a **shell→iframe postMessage** that asks the
booking SPA to navigate client-side. A cold `src` load is kept only as a
fallback for when the iframe has not loaded yet (initial mount is already
handled by `src={initialUrl.current}`).

Key observation: while a single `IframeRouter` instance is mounted, every URL
change it sees is *within the same sub-app*. Navigating to a **different**
sub-app changes the first path segment, remounting cold via `initialUrl`. So the
effect only ever handles same-sub-app navigation.

### Per-sub-app strategy (default unchanged)

There is **no per-sub-app component**: a single generic `IframeRouter` serves
every sub-app through the catch-all `/app/$` route (`app.$.tsx`), with the
sub-app identified by the first path segment (`booking`, `notifications`, …).
"Different behavior per sub-app" therefore means a **capability registry keyed by
that segment**. The default strategy is today's full `src` reload; only listed
sub-apps opt into an alternative. Booking opts into `client-side`; every other
sub-app is byte-for-byte unchanged.

```ts
// src/components/microfrontends/sub-apps.ts
export type NavStrategy = "src-reload" | "client-side";

/** Sub-apps default to a full src reload; only listed ids opt out. */
const NAV_STRATEGY: Record<string, NavStrategy> = { booking: "client-side" };

/** Sub-app id = first path segment, e.g. "./booking/activities" → "booking". */
export function subAppIdFromPath(path: string): string {
  return path.replace(/^\.?\//, "").split("/")[0] ?? "";
}
export function navStrategyFor(path: string): NavStrategy {
  return NAV_STRATEGY[subAppIdFromPath(path)] ?? "src-reload";
}
```

`IframeRouter` stays generic and branches on `navStrategyFor(path)`. Both the new
postMessage path **and** the echo guard are gated behind `"client-side"`, so a
sub-app that hasn't opted in keeps the exact current control flow — the change is
provably scoped to booking.

> **Evolution path.** When a second sub-app wants custom behavior, replace the
> hardcoded map with a **runtime capability handshake**: the sub-app posts
> `{type:"j26:capabilities", navigation:"client-side"}` on load and the shell
> records it per-iframe, defaulting to `src-reload` when none arrives. That
> decouples the shell from app names, is race-safe (capability is known by load
> time — exactly when postMessage nav becomes possible), and degrades gracefully
> for old sub-apps. Only the `navStrategyFor` call site changes. An
> `app-config.json` field was rejected: it loads async, so an early external nav
> could fire before the strategy is known, forcing a fallback anyway.

### Message flow

```
shell URL changes (back/forward/nav-link, from popstate or navigate)
  └─ IframeRouter effect fires
       ├─ iframe not loaded yet ─────────────► iframe.src = url        (cold load)
       └─ iframe loaded ─────────────────────► postMessage j26:navigate → iframe
                                                     │
             booking window "message" listener ◄─────┘
                   └─ dispatch ShellRequestedNavigation(url)
                        └─ update: modem.replace(path, query, fragment)  (client-side, no reload)
                             └─ OnRouteChange fires → page re-renders + notify_navigation echoes back
                                  └─ shell syncIframeUrl(url): url == current shell URL → early-return (no navigate)
                                       └─ loop terminates
```

`modem.replace` (not `push`) is used for shell-originated navs: the shell already
owns the authoritative history entry, so the iframe must update its view **in
place** without adding another same-origin joint-history entry.

### Loop prevention

The booking side unconditionally echoes every `OnRouteChange` back to the shell
via `notify_navigation` (`client.gleam:862`). A shell-driven nav therefore
produces an echo `j26:navigate` back to the shell. Break the loop with **one
guard on the shell side** — the smallest change, and it keeps booking's
`OnRouteChange` logic untouched:

In `syncIframeUrl` (`IframeRouter.tsx:52`), compute the normalized `expectedUrl`
as today, and **for a `client-side` sub-app, if it equals the current shell URL,
return early without calling `navigate()`** (and without setting the
`iframeInitiatedUrl` guard). The echo lands on a URL the shell is already on, so
it becomes a no-op and no duplicate history entry is created. Genuine forward
navs (different URL) fall through to `navigate()` exactly as before. Gating the
guard on the strategy means `src-reload` sub-apps keep their current
`syncIframeUrl` path unchanged.

> Alternative (not chosen): suppress the echo on the booking side with a
> one-shot Model flag. Rejected because it adds transient state and mutates it
> in two places; the shell-side same-URL guard is localized and stateless.

## Changes — j26-app (shell)

All shell changes land in the **j26-app** repo (this plan file lives in
j26-booking for reference).

### 1. `src/components/microfrontends/sub-apps.ts` (new)

The per-sub-app capability registry from the Design section — `NavStrategy`,
`subAppIdFromPath`, `navStrategyFor`. Default `"src-reload"`; `booking →
"client-side"`.

### 2. `src/components/microfrontends/shell-protocol.ts`

Add a shell→iframe direction. Reuse `NavigateMessage`:

```ts
/** Messages the shell posts down to a sub-app iframe. */
export type ShellToIframeMessage = NavigateMessage;
```

### 3. `src/components/microfrontends/IframeRouter.tsx`

- Import `navStrategyFor` and track load state:
  `const loadedRef = useRef(false);` set `true` in `onIframeLoad`.
- Replace the `iframe.src = url` branch (lines 44-49) with a strategy branch.
  `src-reload` sub-apps keep the exact current behavior; only `client-side`
  post-messages once loaded (with `src` as the pre-load fallback):

  ```ts
  const strategy = navStrategyFor(path);
  const win = iframeRef.current?.contentWindow;
  if (strategy === "client-side" && loadedRef.current && win) {
    win.postMessage(
      { type: "j26:navigate", url } satisfies ShellToIframeMessage,
      new URL(url, window.location.origin).origin,
    );
  } else if (iframeRef.current) {
    iframeRef.current.src = url; // default reload; also client-side pre-load fallback
  }
  ```

- In `syncIframeUrl` (line 52), after computing `expectedUrl`, add the
  loop-breaking guard **before** `navigate()`, gated on strategy so `src-reload`
  apps are untouched:

  ```ts
  const currentShellUrl = new URL(window.location.href).toString();
  if (navStrategyFor(path) === "client-side" && expectedUrl === currentShellUrl) {
    return; // echo of a shell-driven client-side nav
  }
  iframeInitiatedUrl.current = expectedUrl;
  navigate({ to: route, params: { _splat: relativePath } });
  ```

  (Match `expectedUrl`'s normalization — trailing slash — to how the current
  shell URL is expressed, or normalize both the same way before comparing.)

## Changes — j26-booking (Lustre client)

### 3. `client/src/client_ffi.mjs`

Add a listener that mirrors the `observe_html_lang` shape (source/origin checks +
`pagehide` teardown):

```js
export function observe_shell_navigation(callback) {
  const handler = (event) => {
    if (event.source !== window.parent) return;
    if (event.origin !== window.location.origin) return;
    const data = event.data;
    if (data?.type !== "j26:navigate" || typeof data.url !== "string") return;
    callback(data.url);
  };
  window.addEventListener("message", handler);
  window.addEventListener("pagehide", () => window.removeEventListener("message", handler), {
    once: true,
  });
}
```

### 4. `client/src/client.gleam`

- Add FFI binding + effect next to `observe_lang` (`client.gleam:1439/1458`):

  ```gleam
  @external(javascript, "./client_ffi.mjs", "observe_shell_navigation")
  fn observe_shell_navigation(callback: fn(String) -> Nil) -> Nil

  fn observe_shell_nav() -> Effect(Msg) {
    effect.from(fn(dispatch) {
      observe_shell_navigation(fn(url) { dispatch(ShellRequestedNavigation(url)) })
    })
  }
  ```

- Add the message to `Msg` (routing group, `client.gleam:809`), SVO-named:

  ```gleam
  ShellRequestedNavigation(String)
  ```

- Register the subscription in `init`'s `effect.batch` (`client.gleam:792`),
  alongside `modem.init` and `observe_lang`:

  ```gleam
  observe_shell_nav(),
  ```

- Handle it in `update` — parse the URL and `modem.replace` its path
  components (replace, not push, per the design):

  ```gleam
  ShellRequestedNavigation(url) -> {
    case uri.parse(url) {
      Ok(uri.Uri(path:, query:, fragment:, ..)) -> #(
        model,
        modem.replace(path, query, fragment),
      )
      Error(_) -> #(model, effect.none())
    }
  }
  ```

  `modem.replace` triggers a normal `OnRouteChange`, which re-renders the page
  and echoes `notify_navigation` back to the shell — absorbed by the shell's
  same-URL guard. No booking-side loop state is needed.

  (Optional micro-optimization: skip the `modem.replace` when `path` already
  equals the current location to avoid a redundant re-render. Not required for
  correctness.)

## Files to modify

- `j26-app/src/components/microfrontends/sub-apps.ts` — **new** capability
  registry (`NavStrategy`, `subAppIdFromPath`, `navStrategyFor`).
- `j26-app/src/components/microfrontends/shell-protocol.ts` — add `ShellToIframeMessage`.
- `j26-app/src/components/microfrontends/IframeRouter.tsx` — strategy branch
  (postMessage for `client-side`, `src` default); `loadedRef`; gated same-URL
  guard in `syncIframeUrl`.
- `j26-booking/client/src/client_ffi.mjs` — add `observe_shell_navigation`.
- `j26-booking/client/src/client.gleam` — FFI binding, `observe_shell_nav`
  effect, `ShellRequestedNavigation` msg + handler, register in `init`.

## Alternatives considered

### Make the reload cheap instead (caching + SSR)

Rather than avoid the reload, make it fast and content-ful. This targets a
*different* failure mode and is **complementary, not a substitute**.

A `src` reassignment always tears down the iframe document and cold-boots the
SPA. Caching and SSR make that reboot faster and less ugly; neither makes it
*not* a reload, and neither can restore **live in-memory client state** — scroll
position, which pagination pages were loaded, active filters, half-filled
booking-form input, and the normalized activity store (plan 02) all reset on
every back press. That state loss is exactly the pain this plan removes.

- **Caching** (service worker / HTTP / API responses) — speeds the cold boot.
  The `client.js` bundle is likely already cached; API caching shortens the
  `init` round-trips. Does nothing for state loss or the teardown flash.
- **SSR** — Lustre SSR is mechanically cheap: render `view(model)` with
  `element.to_string`/`to_document_string`, the same call the server already
  makes for the shell (`router.gleam:85`); no `lustre` runtime needed. There is
  **no SSR today** — `spa_shell_page` renders an empty `#app` div
  (`server/web.gleam:380`). Standing it up for this app is a *moderate refactor*,
  not a big project, but it is more than the render call:
  1. Extract the pure `view`/`Model`/`Msg` into a target-agnostic module —
     `client.gleam` is JS-target and leans on JS-only FFI/deps (`get_html_lang`,
     `modem`, `rsvp`, plinth). The view body ports cleanly (it renders `scout-*`
     via `element.element`); the edges don't — the translator comes from
     `get_html_lang()` (server would read lang from the request instead).
  2. Build the initial `Model` from the DB server-side (the client fills it via
     `fetch_list`/`fetch_spots`/`fetch_statuses`; the server already has the
     `model/` + `sql` modules to query directly).
  3. Hydration handshake — serialize that `Model` to JSON in a `<script>` and
     have the client `init` decode it instead of re-fetching, so the client
     Model matches the server markup (no re-render flash).

  Even done perfectly, hydration matches the **serialized** model (freshly
  DB-loaded lists, request lang), **not the live pre-back model** — so the state
  loss above remains.

**Verdict:** SSR/caching are worth doing on their own merits — they improve the
paths this plan leaves untouched (genuine cold entry, deep-links, refresh, and
cross-sub-app switches, which always reload by design). But only client-side
navigation makes *back* instant and state-preserving, so this plan stands.

## Edge cases

- **Nav before first load** — falls back to `src` (which is the load anyway); no
  message is lost because the booking listener registers during `init`, before
  the iframe `load` event fires.
- **Origin/source spoofing** — the booking listener rejects messages whose
  `source` is not `window.parent` or whose origin differs.
- **Switching to a different sub-app** — handled by React unmount/mount; the new
  `IframeRouter` cold-loads via `initialUrl`. Not a postMessage case.
- **iOS PWAShell** — no system back button; the in-app back button is primary.
  Because the fix lives in the shell's URL-change reaction (not the button), the
  app button, swipe-back, and any native back all get identical no-reload
  behavior.

## Related (out of scope)

Each in-iframe *forward* nav still creates **two** joint-history entries — the
iframe's own `modem.push` and the shell's mirroring `navigate()` push — which
can make back feel like it needs two presses. This plan does not change that;
`modem.replace` here only avoids *adding* to it for shell-driven navs. A
separate change (make the shell mirror use `replace`, or suppress the iframe's
own push) would collapse it to one entry per navigation. Track separately if it
proves annoying on mobile.

## Verification

1. `./dev.sh` from j26-booking; run j26-app against it.
2. Navigate several activities deep inside the booking iframe.
3. Press the **app** back button → page changes with **no** flash/reload
   (Network tab: no new document request for `client.js`; the SPA keeps its
   in-memory state).
4. Repeat with the **browser** back button and, on device/emulator, **Android
   hardware back** and **iOS swipe-back** → same no-reload behavior.
5. Confirm no history desync: back then forward lands on the expected screens;
   the shell URL and iframe content stay in agreement.
6. Regression: forward nav out of the iframe still updates the shell URL and app
   bar title; switching to a *different* sub-app still loads it.
7. Regression on a **non-booking** sub-app (default `src-reload`): back still
   reloads it exactly as before — confirming the change is scoped to booking.
8. `cd client && gleam format`.

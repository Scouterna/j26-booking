# 07. Client-side shell→iframe navigation (no SPA reload on back)

> **Status: 🚧 In progress** (as of 2026-07-10) — Approach A implemented in
> j26-app and verified locally. PR: [Scouterna/j26-app#6](https://github.com/Scouterna/j26-app/pull/6) (not yet merged).
>
> Revised 2026-07-10: **Approach A (native history)** is the chosen design.
> **Approach B** is retained below as the deterministic fallback.
>
> **Verified 2026-07-10** (Playwright, local `j26 up` stack, booking iframe):
> forward nav mirrors the deep route to the shell URL; app-bar back button,
> browser back, and browser forward all navigate **client-side with no iframe
> reload** (a marker planted on the iframe `window` survived every traversal;
> `client.js` fetched exactly once) and **one press = one screen** (no
> double-entry). Implemented in j26-app: `sub-apps.ts` (new), `IframeRouter.tsx`,
> and **`AppBar.tsx`** (see the `canGoBack` caveat below — this third file was
> not in the original design).

Cross-repo plan: touches **j26-app** (React shell) and — only in Approach B —
**j26-booking** (Lustre sub-app). The plan file lives here, but the shell
changes land in the `j26-app` repo.

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
button-only fix would leave browser/OS back still reloading. (This is also why
"just call `iframe.contentWindow.history.back()` from the shell back button"
doesn't work on its own: it only covers the app button, and it doesn't remove
the `src` reassignment that actually causes the reload.)

## Approach — pick A, keep B as fallback

Two designs are documented.

- **Approach A (native history) — recommended, try first.** A ~2-line shell
  change, **no booking-side changes**, and it also fixes the pre-existing
  double-entry "back needs two presses" bug. It relies on same-origin
  joint-history + `popstate` semantics, so it **must be verified on the Android
  TWA and the iOS WKWebView** (the environments most likely to have quirks).
- **Approach B (explicit postMessage) — deterministic fallback.** More code (a
  shell→iframe message + a booking-side listener), but it does not depend on
  joint-history behavior — the shell explicitly tells the iframe where to go.
  Use this only if Approach A fails device verification.

Both share the per-sub-app gating below, so the change stays scoped to booking
and every other sub-app keeps today's `src`-reload behavior byte-for-byte.

### Per-sub-app strategy (shared; default unchanged)

There is **no per-sub-app component**: a single generic `IframeRouter` serves
every sub-app through the catch-all `/app/$` route (`app.$.tsx`), with the
sub-app identified by the first path segment (`booking`, `notifications`, …).
"Different behavior per sub-app" therefore means a **capability registry keyed by
that segment**. Default is today's full `src` reload; only listed sub-apps opt
into an alternative. Booking opts into `client-side`; everything else is
unchanged.

```ts
// src/components/microfrontends/sub-apps.ts
export type NavStrategy = "src-reload" | "client-side";

/** Sub-apps default to a full src reload; only listed ids opt out. */
const NAV_STRATEGY: Record<string, NavStrategy> = { booking: "client-side" };

/** Sub-app id = first path segment, e.g. "./booking/activities" → "booking". */
export function subAppIdFromPath(path: string): string {
  return path.replace(/^\.?\//, "").split("/")[0] ?? "";
}
/** Same, from a full/absolute URL. */
export function subAppIdFromUrl(url: string): string {
  const p = new URL(url, window.location.origin).pathname; // /app/booking/... or /_services/booking/...
  return p.split("/").filter(Boolean)[1] ?? "";
}
export function navStrategyFor(path: string): NavStrategy {
  return NAV_STRATEGY[subAppIdFromPath(path)] ?? "src-reload";
}
```

`IframeRouter` stays generic and branches on `navStrategyFor(path)`; both
approaches gate their new behavior behind `"client-side"`, so a sub-app that
hasn't opted in keeps the exact current control flow — the change is provably
scoped to booking.

> **Evolution path.** When a second sub-app wants custom behavior, replace the
> hardcoded map with a **runtime capability handshake**: the sub-app posts
> `{type:"j26:capabilities", navigation:"client-side"}` on load and the shell
> records it per-iframe, defaulting to `src-reload` when none arrives. That
> decouples the shell from app names, is race-safe, and degrades gracefully for
> old sub-apps. Only the `navStrategyFor` call site changes. An
> `app-config.json` field was rejected: it loads async, so an early external nav
> could fire before the strategy is known, forcing a fallback anyway.

## Approach A — native history (recommended)

### Why it works

Only assigning `iframe.src` reloads. A history **traversal** of a same-origin
iframe that navigated via `pushState` fires `popstate` *inside the iframe* and
re-renders it client-side — no reload. Every back trigger (app button, browser,
Android/iOS native) funnels through the same native `history.back()`, so if the
shell simply **stops reassigning `src`** and lets the traversal through, they all
become reload-free at once. Booking already handles `popstate` (modem) and
already emits `j26:navigate`, so **no booking changes are needed** — the browser
itself moves the iframe to the right entry and modem re-renders.

The one prerequisite is to **collapse the two-entries-per-nav down to one**.
Today each in-iframe nav creates *two* joint-history entries — the iframe's own
`modem.push` **and** the shell's mirroring `navigate()` push. With two entries,
pressing back once pops the shell's top-only push: the top URL reverts but the
iframe URL doesn't, so the iframe view doesn't move (no popstate) while the shell
URL says otherwise — a desync that takes a second back press to resolve. That is
the "back needs two presses" bug. Collapsing to one entry fixes both problems.

### Change 1 — mirror with `replace`, not `push`

In `syncIframeUrl` (`IframeRouter.tsx:68`), mirror the URL with a **replace** for
`client-side` sub-apps so the shell reuses the single joint-history entry the
iframe's `pushState` already created (rather than pushing a second):

```ts
navigate({
  to: route,
  params: { _splat: relativePath },
  replace: navStrategyFor(path) === "client-side",
});
```

Result: history holds exactly one entry per nav (the iframe's), with the
top-frame URL kept in sync inside it. `src-reload` sub-apps keep the default
push. This alone fixes the double-entry bug.

### Change 2 — stop reassigning `src` for same-sub-app client-side navs

Rework the effect (`IframeRouter.tsx:38-50`). Keep the `iframeInitiatedUrl` guard
(it absorbs the shell's own mirror `navigate`, and — pre-set at mount, line 33 —
the mount-time run). For a genuine external nav, do **nothing** when it's within
the same `client-side` sub-app: the native traversal already re-rendered the
iframe via `popstate`. Only reassign `src` for a cross-sub-app switch (cold load)
or a `src-reload` sub-app:

```ts
useEffect(() => {
  if (iframeInitiatedUrl.current === url) { iframeInitiatedUrl.current = null; return; }

  const win = iframeRef.current?.contentWindow;
  const sameSubApp = !!win && subAppIdFromUrl(win.location.href) === subAppIdFromUrl(url);

  if (navStrategyFor(path) === "client-side" && sameSubApp) {
    return; // native history traversal already moved + re-rendered the iframe
  }
  if (iframeRef.current) iframeRef.current.src = url; // cold load / cross-app / src-reload app
}, [url]);
```

### Change 3 — show the app-bar back button on iframe routes (`AppBar.tsx`)

**Discovered during verification** — not in the original design. The mobile
app-bar back button renders only when `!isDesktop && !isOnRootPage &&
canGoBack`, where `canGoBack` is TanStack's `useCanGoBack()`. That hook reads
TanStack's *internal* history index, which **`replace` (Change 1) never
advances** — so while inside a client-side sub-app the shell thinks its
back-stack is empty and hides the button, even though the browser's real history
is not empty and native back works.

This is the fundamental `push`-vs-`replace` tension: `push` keeps `canGoBack`
accurate but reintroduces the double-entry (a dead back press); `replace` gives
clean one-press nav but freezes `canGoBack`. Keep `replace` and instead use a
back-signal that isn't TanStack's frozen index for iframe routes:

```ts
// /app/$ catch-all = an iframe sub-app; its route is mirrored with replace, so
// useCanGoBack() is unreliable there. Use the browser's real history depth.
const isIframeRoute = location.pathname.startsWith("/app/");
const canGoBackHere = isIframeRoute ? window.history.length > 1 : canGoBack;
// ...render back button when: !isDesktop && !isOnRootPage && canGoBackHere
```

`window.history.length > 1` is `true` once the user has navigated within the
sub-app and correctly `false` on a fresh deep-link (empty history → no button).
Native shell routes keep TanStack's `canGoBack` unchanged.

### What stays

The forward mirror (iframe → shell `navigate`) and the `iframeInitiatedUrl`
guard stay — they keep TanStack, the URL bar, the app bar, and deep-linking in
sync. In `IframeRouter` only two things change: `push` → `replace` (Change 1)
and the effect's external branch (Change 2). The back button's `onClick`
(`router.history.back()`) is unchanged: it bottoms out at
`window.history.back()`, which traverses the single joint entry and lets the
iframe's `popstate` do the work.

### Approach A — files to modify (all in j26-app)

- `src/components/microfrontends/sub-apps.ts` — **new** registry
  (`NavStrategy`, `subAppIdFromPath`, `subAppIdFromUrl`, `navStrategyFor`).
- `src/components/microfrontends/IframeRouter.tsx` — `replace` in `syncIframeUrl`
  (Change 1); rework the effect (Change 2).
- `src/components/AppBar.tsx` — `canGoBackHere` for iframe routes (Change 3).

No `shell-protocol.ts` change, no j26-booking change.

## Approach B — explicit shell→iframe postMessage (fallback)

Use only if Approach A fails device verification. Instead of relying on native
traversal, the shell **posts a `j26:navigate` down to the iframe**, and the
booking SPA applies it via `modem.replace`. Deterministic; independent of
joint-history semantics.

### Message flow

```
shell URL changes (external)
  └─ IframeRouter effect fires
       ├─ iframe not loaded yet ─────────────► iframe.src = url        (cold load)
       └─ iframe loaded (client-side app) ───► postMessage j26:navigate → iframe
                                                     │
             booking window "message" listener ◄─────┘
                   └─ dispatch ShellRequestedNavigation(url)
                        └─ update: modem.replace(path, query, fragment)  (no reload)
                             └─ OnRouteChange → re-render + notify_navigation echoes back
                                  └─ syncIframeUrl(url): url == current shell URL → early-return
                                       └─ loop terminates
```

### Shell (j26-app)

- `shell-protocol.ts` — add the down direction: `export type ShellToIframeMessage = NavigateMessage;`
- `IframeRouter.tsx` — track load state (`const loadedRef = useRef(false)`, set in
  `onIframeLoad`). Replace the `src` branch with a strategy branch:

  ```ts
  const win = iframeRef.current?.contentWindow;
  if (navStrategyFor(path) === "client-side" && loadedRef.current && win) {
    win.postMessage(
      { type: "j26:navigate", url } satisfies ShellToIframeMessage,
      new URL(url, window.location.origin).origin,
    );
  } else if (iframeRef.current) {
    iframeRef.current.src = url; // default reload; also client-side pre-load fallback
  }
  ```

- `syncIframeUrl` — add the loop-breaking guard before `navigate()`, gated on
  strategy so `src-reload` apps are untouched:

  ```ts
  const currentShellUrl = new URL(window.location.href).toString();
  if (navStrategyFor(path) === "client-side" && expectedUrl === currentShellUrl) {
    return; // echo of a shell-driven client-side nav
  }
  ```

  > Alternative (not chosen): suppress the echo on the booking side with a
  > one-shot Model flag. Rejected — it adds transient state mutated in two
  > places; the shell-side same-URL guard is localized and stateless.

### Booking (j26-booking)

- `client/src/client_ffi.mjs` — add a listener mirroring `observe_html_lang`
  (source/origin checks + `pagehide` teardown):

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

- `client/src/client.gleam`:
  - FFI binding + effect next to `observe_lang` (`client.gleam:1439/1458`):

    ```gleam
    @external(javascript, "./client_ffi.mjs", "observe_shell_navigation")
    fn observe_shell_navigation(callback: fn(String) -> Nil) -> Nil

    fn observe_shell_nav() -> Effect(Msg) {
      effect.from(fn(dispatch) {
        observe_shell_navigation(fn(url) { dispatch(ShellRequestedNavigation(url)) })
      })
    }
    ```

  - New `Msg` (routing group, `client.gleam:809`, SVO-named): `ShellRequestedNavigation(String)`.
  - Register `observe_shell_nav()` in `init`'s `effect.batch` (`client.gleam:792`).
  - Handle in `update` — `modem.replace` (not push; the shell owns the entry):

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
  (`server/web.gleam:380`). Standing it up is a *moderate refactor*, not a big
  project, but it is more than the render call:
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

- **Switching to a different sub-app** — a cross-app URL change reassigns `src`
  in both approaches (Approach A: `sameSubApp` is false; Approach B: it's still a
  different document). Back into a torn-down app necessarily reloads it — expected.
- **iOS PWAShell** — no system back button; the in-app back button is primary.
  Because the fix lives in the shell's URL-change reaction (not the button), the
  app button, swipe-back, and any native back get identical no-reload behavior.
- **Approach B, nav before first load** — falls back to `src` (which is the load
  anyway); no message is lost because the booking listener registers during
  `init`, before the iframe `load` event fires.
- **Approach B, origin/source spoofing** — the booking listener rejects messages
  whose `source` is not `window.parent` or whose origin differs.

## Verification

1. `./dev.sh` from j26-booking; run j26-app against it.
2. Navigate several activities deep inside the booking iframe.
3. Press the **app** back button → page changes with **no** flash/reload
   (Network tab: no new document request for `client.js`; the SPA keeps its
   in-memory state, e.g. list scroll position).
4. **One press = one screen** (double-entry regression, Approach A): a single
   back press moves exactly one navigation, with shell URL and iframe content in
   agreement at each step (no intermediate desync).
5. Repeat step 3 with the **browser** back button and, on device/emulator,
   **Android hardware back** and **iOS swipe-back** → same no-reload behavior.
   *(This is the make-or-break check for Approach A; if any of these reload or
   desync, fall back to Approach B.)*
6. Back-then-forward lands on the expected screens.
7. Regression: forward nav out of the iframe still updates the shell URL and app
   bar title; switching to a *different* sub-app still loads it.
8. Regression on a **non-booking** sub-app (default `src-reload`): back still
   reloads it exactly as before — confirming the change is scoped to booking.
9. Approach B only: `cd client && gleam format`.

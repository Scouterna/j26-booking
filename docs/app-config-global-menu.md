# Global menu / shell navigation via `app-config`

Reference for how the **global navigation menu** in the j26-app shell works, and
how a sub-app (like j26-booking) contributes items to it. Captured while
investigating "move the edit button to the top nav bar" — the conclusion was
that app-config drives the *global menu*, **not** the top app bar.

## TL;DR

- Each sub-app exposes **`GET /api/app-config`** returning a `navigation` JSON.
- The shell fetches every sub-app's app-config, merges them, and renders the
  items as the app's **global navigation**: the **bottom nav bar** (mobile), the
  **side menu** (desktop), and the **"More"** list.
- Items are **global, static page links** — one `path` each, no per-page or
  per-record/runtime context.
- This is **not** the top app bar. The top app bar is a separate `postMessage`
  channel (`j26:appBar`) and currently only carries a title.

## Producer side (the sub-app, e.g. j26-booking)

- Handler: `server/src/server/web/app_config.gleam`
- Route: `GET /api/app-config` (`server/src/server/router.gleam`)
- Response shape: `{ "navigation": [ ...NavigationItem ] }`
- Contract documented in `server/priv/static/openapi.yaml`
  (`AppConfig` / `NavigationGroup` / `NavigationPage`). Keep this in sync with
  the handler (server API convention).

## Schema

```
AppConfig      = { navigation: NavigationItem[] }
NavigationItem = Page | Group
Page  = { type: "page",  id: string, label: string, icon?: string, path: string }
Group = { type: "group", id: string, label: string, children: Page[] }
```

| Field   | Meaning |
| ------- | ------- |
| `type`  | `"page"` (a link) or `"group"` (a labelled group of pages). |
| `id`    | Stable unique id (e.g. `page_activities`). The shell keys off this (e.g. to decide bottom-bar membership). |
| `label` | An **i18n key**, not display text. The shell resolves it via tolgee, namespace **`navigation`** — the translation must exist shell-side. |
| `icon`  | An **icon name** resolved by the shell's icon registry (`useIcon`). Optional. |
| `path`  | URL **relative to the config URL** (e.g. `../activities`, `../`). The shell remaps `/_services/<app>/...` → `/app/<app>/...`. Prefer relative paths. |

Example (from the openapi spec):

```json
{
  "navigation": [
    { "type": "group", "id": "group_booking", "label": "booking.schedule.label",
      "children": [
        { "type": "page", "id": "page_all_activities", "label": "booking.all_activities.label", "icon": "campfire", "path": "../activities" },
        { "type": "page", "id": "page_my_schedule",   "label": "booking.my_schedule.label",   "icon": "calendar-event", "path": "../" }
      ] }
  ]
}
```

## Consumer side (the shell, j26-app)

- **Schema / validation:** `src/dynamic-routes/app-config.ts` (arktype `appConfig` scope).
- **Load + merge:** `src/dynamic-routes/dynamic-routes.ts`
  - `loadAppConfigs(urls)` fetches each sub-app's config (`Promise.allSettled`; a
    failed/invalid config is skipped with a warning, not fatal).
  - `remapNavigationItems` / `remapPageUrl` rewrite each `path`
    (`/_services/…` → `/app/…`, resolved against the config URL).
- **Render:**
  - `src/components/BottomNavigation.tsx` — the bottom bar (mobile); items chosen
    by `bottomNavItems` from `useDynamicRoutes()`.
  - side menu (desktop) / the "More" list (overflow).
- The **shell's own** top-level pages come from `public/app-config.json`
  (notifications, info, more, settings) — merged the same way.
- **Which** items land in the bottom bar vs. "More"/side menu is decided by the
  **shell** (`useDynamicRoutes`: `allPages`, `bottomNavItems`), not by the sub-app.

## What it can't do

- **No contextual actions.** Items are global static links with no runtime or
  entity context, so you can't express "do X to *this* record" (e.g. edit the
  currently-viewed activity).
- **It's not the top app bar.** The top app bar is driven by the `j26:appBar`
  postMessage (`src/components/microfrontends/shell-protocol.ts`), which today
  carries only `{ title }`. The bar *can* render a suffix action
  (`AppBarAction` = `icon` + `label` + `onClick | to`, see `src/route-types.ts`),
  but only from route `staticData`, and it's **suppressed while an iframe controls
  the bar** (`iframeAppBar === null && routeAction` in `src/components/AppBar.tsx`).
  A contextual action from a sub-app would require **extending the `j26:appBar`
  protocol** (shell + sub-app change), not app-config.

## Recipe: add a global menu item

1. In the sub-app's `app-config` handler, add a `page` (or a `group` with
   `children`) to `navigation` — set `id`, `label` (an i18n key), optional
   `icon`, and a relative `path`.
2. Add the shell-side tolgee translation for `label` (namespace `navigation`) and
   make sure `icon` resolves in the shell's icon registry.
3. Update the sub-app's `openapi.yaml` to match.
4. The shell picks it up on next load. Bottom-bar vs. "More"/side-menu placement
   is the shell's call (`bottomNavItems`).

## Gotchas

- **openapi vs. code drift:** `openapi.yaml` documents the `group → children`
  shape, but j26-booking's handler currently returns a single flat `page`. Both
  are schema-valid (`NavigationItem = Page | Group`); just keep them consistent.
- **Async load:** app-config is fetched at shell startup, so it's unsuitable for
  anything that must be known synchronously/early (this is why plan 07 rejected an
  app-config field for the nav-strategy and preferred a runtime capability
  handshake).
- **Relative paths:** `path` is resolved against the config URL and remapped
  (`/_services/` → `/app/`); use `../` forms.

## Key files

**Producer (j26-booking):**
- `server/src/server/web/app_config.gleam` (handler)
- `server/src/server/router.gleam` (route)
- `server/priv/static/openapi.yaml` (`AppConfig` schema)

**Consumer (j26-app shell):**
- `src/dynamic-routes/app-config.ts` (schema)
- `src/dynamic-routes/dynamic-routes.ts` (load/merge/remap)
- `src/components/BottomNavigation.tsx` (render)
- `src/components/AppBar.tsx` + `src/components/microfrontends/shell-protocol.ts`
  (the *separate* top-app-bar channel — for contrast)
- `public/app-config.json` (the shell's own pages)

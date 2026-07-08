# 01. Emit j26:navigate on every route change

> **Status: ✅ Done** (verified 2026-07-02)
>
> Implemented, but with a different FFI shape than proposed below. Instead of a
> generalized `post_message_to_parent(messageJson)` + `post_to_parent` helper,
> the code keeps two dedicated FFI functions in `client_ffi.mjs`:
> `post_app_bar_title(title)` and `post_navigation(url)`. `OnRouteChange`
> (`client.gleam:708`) batches `notify_navigation(uri)` alongside the title
> effect, matching the plan's intent. `TODO.md` line 5 is checked off.

## Context

`TODO.md` line 5: *"modem is not triggered properly for route changes (back button in wrapper app is not working due to this probably)"*.

The j26-app shell only learns the iframe's URL via the iframe's native `load` event, which doesn't fire on `pushState`. So in-iframe SPA navigation is invisible to the shell, the shell URL stays stale, and the wrapper's back button operates on a history stack that was never advanced.

The shell-side handler for the new `j26:navigate` message is being implemented separately in j26-app by someone else. Scope for this plan is **j26-booking only**: emit the event on every `OnRouteChange` and generalise the existing `post_message_to_parent` FFI so it carries both the existing `j26:appBar` and the new `j26:navigate` messages cleanly.

## Implementation

### 1. Generalise `client/src/client_ffi.mjs`

Replace the current two-string signature with one that takes the full message object, serialised as a JSON string from Gleam:

```js
export function post_message_to_parent(messageJson) {
  window.parent.postMessage(JSON.parse(messageJson), window.location.origin);
}
```

### 2. Update `client/src/client.gleam`

Replace the FFI binding and `set_app_bar_title` helper near line 1072 with a general `post_to_parent` helper, plus a new `post_navigate`:

```gleam
@external(javascript, "./client_ffi.mjs", "post_message_to_parent")
fn post_message_to_parent(message: String) -> Nil

fn post_to_parent(type_: String, fields: List(#(String, json.Json))) -> Effect(msg) {
  let message =
    json.object([#("type", json.string(type_)), ..fields])
    |> json.to_string
  effect.from(fn(_dispatch) { post_message_to_parent(message) })
}

fn set_app_bar_title(title: String) -> Effect(msg) {
  post_to_parent("j26:appBar", [#("title", json.string(title))])
}

fn post_navigate(uri: Uri) -> Effect(msg) {
  post_to_parent("j26:navigate", [#("url", json.string(uri.to_string(uri)))])
}
```

`uri.to_string` gives the full absolute URL because modem's FFI populates scheme/host/port from `window.location` (`modem.ffi.mjs:151-163`).

In `OnRouteChange` at `client.gleam:507`, batch `post_navigate(uri)` alongside `title_effect`:

```gleam
OnRouteChange(uri) -> {
  let #(page, page_effect) = uri_to_page(uri)
  let title_effect = case app_bar_title(model.translator, page) {
    Some(title) -> set_app_bar_title(title)
    None -> effect.none()
  }
  #(
    Model(..model, page:),
    effect.batch([page_effect, title_effect, post_navigate(uri)]),
  )
}
```

No first-dispatch guard needed: `modem.init` does not synthesise an initial dispatch — `OnRouteChange` only fires from real link clicks, popstate, or programmatic `modem.push`/`replace`, all of which are real navigations the shell should mirror.

## Files to modify

- `client/src/client_ffi.mjs` — generalise `post_message_to_parent` to take a JSON string.
- `client/src/client.gleam` — update FFI binding, add `post_to_parent` helper, add `post_navigate`, batch into `OnRouteChange`.

`TODO.md` line 5 stays open until the shell-side handler lands in j26-app — strike it as a follow-up once the end-to-end behaviour is verified.

## Verification

1. `./dev.sh` from the repo root.
2. Open `https://local.j26.se/app/booking/activities` in DevTools, attach a listener to confirm the message is posted:

   ```js
   window.addEventListener("message", (e) => console.log("from iframe:", e.data));
   ```

   Or inspect from the parent frame on the shell side.
3. Click an activity card → expect a `{ type: "j26:navigate", url: "https://local.j26.se/_services/booking/activities/<id>" }` message in the console.
4. Use the wrapper's back arrow / browser back → expect another `j26:navigate` for the previous URL.
5. App bar title still updates as before (regression check on the generalised `post_message_to_parent`).
6. `cd client && gleam format`.

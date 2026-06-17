# J26 Booking Client

Lustre web client for the Jamboree 2026 booking application.

## Tech Stack

- Gleam (targeting JavaScript)
- Lustre (Elm-like frontend framework)
- Scouterna UI web components

## Development

```sh
# First-time setup: vendor bun + tailwind, then install JS deps
gleam run -m lustre/dev add bun tailwind  # downloads binaries into .lustre/bin
.lustre/bin/*/bun install                 # installs node_modules (e.g. @scouterna/tailwind-theme)

gleam run -m lustre/dev start  # Start dev server with hot reload
gleam build                    # Build the project
gleam test                     # Run the tests

# Build the bundle the API server serves (server/priv/static/client.js)
gleam run -m lustre/dev build --outdir=../server/priv/static
```

## Notes

### Why is there a package.json and bun.lock?

We use the Lustre Dev Tools bun binary to install a Tailwind dependency which is
used by the Lustre Dev Tools Tailwind integration. The bun binary is vendored
under `.lustre/bin/` by `gleam run -m lustre/dev add bun tailwind`, so you don't
need a global `bun` or `node` — run `.lustre/bin/*/bun install` to populate
`node_modules`. The Tailwind theme (`@scouterna/tailwind-theme`) is resolved from
there at build time; without it the build fails with
`Can't resolve '@scouterna/tailwind-theme'`.

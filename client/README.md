# J26 Booking Client

Lustre web client for the Jamboree 2026 booking application.

## Tech Stack

- Gleam (targeting JavaScript)
- Lustre (Elm-like frontend framework)
- Scouterna UI web components

## Development

```sh
gleam run -m lustre/dev start  # Start dev server with hot reload
gleam build                    # Build the project
gleam test                     # Run the tests
```

## Notes

### Why is there a package.json and bun.lock?

We use the Lustre Dev Tools bun binary to install a Tailwind dependency which is used by the Lustre Dev Tools Tailwind integration. 

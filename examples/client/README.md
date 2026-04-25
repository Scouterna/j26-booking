# Example Client — Scouterna UI Web Components in Lustre

Reference implementation demonstrating how to use `@scouterna/ui-webc` web components in a Lustre (Gleam) frontend.

See [Web Components Guide](../../.claude/web-components.md) for patterns and component catalog.

## Demonstrates

- Lustre Model-View-Update with web component events
- `scout-button`, `scout-input`, `scout-checkbox`, `scout-tabs`, `scout-card`, `scout-loader`, `scout-link`, `scout-divider`, `scout-app-bar`, `scout-field`
- Custom event decoding (`scoutClick`, `scoutChange`, `scoutChecked`)
- Controlled inputs (value in model, passed back as attribute)

## Development

```sh
gleam run -m lustre/dev start  # Dev server with hot reload
gleam build                    # Build the project
gleam test                     # Run tests
```

### Why is there a package.json?

Lustre Dev Tools uses Bun to install the Tailwind/Scouterna theme dependency.

# J26 Booking Shared

Shared types and utilities used by both the server and client packages.

## Contents

- `shared/model.gleam` - Shared data types (`Activity`)

## Usage

This package is referenced as a path dependency in `client/gleam.toml`:

```toml
shared = { path = "../shared" }
```

## Development

```sh
gleam test  # Run the tests
```

# Booking app for Jamboree 2026

This app enables participants of Jamboree 2026 to book various activities.

Built as a Gleam fullstack monorepo with Lustre.

## Project Structure

| Package | Target | Purpose |
| ------- | ------ | ------- |
| [`server/`](server/) | Erlang | Web server (Mist + Wisp), SSR, REST API, PostgreSQL |
| [`client/`](client/) | JavaScript | Lustre SPA, compiled to `server/priv/static/client.js` |
| [`shared/`](shared/) | Both | Shared types (`Activity`, etc.) and utilities |

## Getting Started

### Prerequisites

- [Gleam](https://gleam.run/getting-started/installing/) (v1.13+)
- [Erlang/OTP](https://www.erlang.org/) (for server)
- [PostgreSQL](https://www.postgresql.org/) (running locally or via Docker)

### Quick Start (with Docker)

```sh
docker-compose up
```

This starts PostgreSQL, runs migrations, and starts the server at http://localhost:8000.

### Quick Start (without Docker)

```sh
# 1. Set up database
export DATABASE_URL="postgres://postgres@localhost:5432/j26booking"
cd server
gleam run -m cigogne last                          # Run migrations
psql "$DATABASE_URL" -f priv/seeding/activities.sql  # Seed example data

# 2. Build client and start the server
cd ..
./dev.sh  # Builds client, then starts server on http://localhost:8000
```

For detailed instructions, see the [server README](server/README.md) and [client README](client/README.md).

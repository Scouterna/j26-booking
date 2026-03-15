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
- [Docker](https://www.docker.com/) (for PostgreSQL and migrations)

### Quick Start

```sh
# 1. Set up environment
cp .env.sh.template .env.sh  # Adjust values if needed

# 2. Start PostgreSQL and run migrations
docker compose up db migrate

# 3. (Optional) Seed example data
./seed.sh

# 4. Build client and start the server
./dev.sh  # Sources .env.sh, builds client, starts server on http://localhost:8000
```

> **Note:** Docker exposes PostgreSQL on port **5433** to avoid conflicts with any local Postgres instance. The `DATABASE_URL` in `.env.sh.template` already reflects this.

### Full Docker Setup

To run everything in Docker (DB, migrations, and app):

```sh
docker compose up
```

This starts PostgreSQL, runs migrations, and starts the server at http://localhost:8000.

For detailed instructions, see the [server README](server/README.md) and [client README](client/README.md).

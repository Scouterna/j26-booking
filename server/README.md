# J26 Booking Server

Backend server for the Jamboree 2026 booking application.

## Tech Stack

- Gleam (targeting Erlang)
  - Mist + Wisp for web server
  - Lustre for SSR and client-side SPA
  - Squirrel for type-safe DB queries
  - Cigogne for database migrations
- PostgreSQL

The compiled Lustre client app (`client.js`) is served from `priv/static/`.

## Folder Structure

| Path | Purpose |
| ---- | ------- |
| [`src/server.gleam`](src/server.gleam) | Entry point, supervision tree |
| [`src/server/`](src/server/) | Main app modules (router, web, components, model, etc.) |
| [`src/server/sql/`](src/server/sql/) | SQL query files for Squirrel |
| [`priv/migrations/`](priv/migrations/) | Database migration SQL files (applied with Cigogne) |
| [`priv/seeding/`](priv/seeding/) | SQL scripts for seeding the database with example data |
| [`priv/static/`](priv/static/) | Static files served by the web server (client.js, CSS, OpenAPI spec) |
| [`test/`](test/) | Gleam test files |

## Development

### Local Development (without Docker)

```sh
gleam run   # Run the project
gleam test  # Run the tests
```

### Local Development (with Docker)

The easiest way to run the entire stack locally is using Docker Compose:

```sh
# Start all services (database + migrations + application)
docker-compose up

# Start in detached mode
docker-compose up -d

# View logs
docker-compose logs -f app

# Stop all services
docker-compose down

# Rebuild after code changes
docker-compose up --build
```

The application will be available at http://localhost:8000

**Note**: Database migrations run automatically when starting the stack. The app service waits for migrations to complete successfully before starting.

### Environment Variables

| Variable | Default | Description |
| -------- | ------- | ----------- |
| `PORT` | 8000 | Port the web server listens on |
| `DATABASE_URL` | postgres://postgres@localhost:5432/j26booking | PostgreSQL connection URL |
| `DB_POOL_SIZE` | 15 | Connection pool size |
| `SECRET_KEY_BASE` | (random) | Secret key for sessions (required in production) |
| `OPEN_ID_CONFIGURATION_URL` | https://app.dev.j26.se/auth/... | OpenID Connect discovery URL |
| `DEV_AUTH_ROLES` | (unset) | **Local dev only.** Comma-separated roles (e.g. `admin` or `bookings:self:create,bookings:read`). When set, requests without an access token authenticate as the seeded dev user with these roles. Never set in production. |

**Note:** The base path `/_services/booking` is hardcoded as `web.base_path` (not an environment variable). All routes are served under this prefix.

### Authentication & Authorization

Requests are authenticated by a Keycloak-issued JWT, taken from the
`Authorization: Bearer` header when present, otherwise from the httpOnly
`j26-auth_access-token` cookie that the j26-auth service sets on the shared
origin (the browser sends it automatically from inside the j26-app shell, and
the shell's refresh loop keeps it fresh). Signatures are verified against the
JWKS fetched from OpenID Connect discovery at startup.

Roles come from the token's `resource_access.j26-booking.roles` claim:
`activities:manage`, `bookings:others:create`, `bookings:read`,
`bookings:self:create`, and `admin` (implies all). The booker group id is
parsed from the `/j26-scoutid-sync/groups/<id>` entry of the `groups` claim.

When running without the shell, set `DEV_AUTH_ROLES` to work as a fallback
dev user (see table above); real tokens always take precedence.

### Building Docker Image

To build the Docker image manually:

```sh
# Build the image
docker build -t j26booking:latest .

# Run the container
docker run -p 8000:8000 \
  -e DATABASE_URL=postgres://postgres@host.docker.internal:5432/j26booking \
  -e SECRET_KEY_BASE=your-secret-key \
  j26booking:latest
```

## Database

This app requires a PostgreSQL database.

### Squirrel

This project uses [Squirrel](https://hexdocs.pm/squirrel/index.html) for type-safe database access. Squirrel generates Gleam code from SQL query files.

**After changing or adding any SQL files** in [`src/server/sql/`](src/server/sql/), regenerate the Gleam modules by running:

```sh
gleam run -m squirrel
```

This updates `src/server/sql.gleam` — do not edit that file manually.

### Database Configuration

The app, migrations (Cigogne), and Squirrel all use the same `DATABASE_URL` environment variable:

```sh
export DATABASE_URL="postgres://postgres@localhost:5432/j26booking"
```

If not set, the app defaults to `postgres://postgres@localhost:5432/j26booking`.

### Running Migrations

Database migrations are managed using [Cigogne](https://hexdocs.pm/cigogne/index.html).

```sh
gleam run -m cigogne all
```

This applies all pending migrations from [`priv/migrations/`](priv/migrations/).

### Seeding the Database

```sh
psql "$DATABASE_URL" -f priv/seeding/locations.sql
psql "$DATABASE_URL" -f priv/seeding/activities.sql
psql "$DATABASE_URL" -f priv/seeding/bookings.sql
```

This inserts locations with their tags, sample activities (some linked to a
location via `location_id`), users, bookings, and activity_user assignments.
Locations must be seeded before activities, which reference them; bookings
reference activities, so they come last. Make sure migrations have been applied
first. From the repo root you can also run `./seed.sh`.

### Database Schema

#### MVP

```mermaid
erDiagram

user {
  uuid id PK
  enum role "_organizer_, _booker_, _admin_"
}

activity {
  uuid id PK
  text title
  text title_en
  text description
  text description_en
  int[null] max_attendees
  timestamp start_time
  timestamp end_time
  text[null] recurring_activity_kind "slug: beach-bus | climbing-wall"
  uuid[null] location_id FK "_not initial scope_"
}

booking {
  uuid id PK
  uuid user_id FK "_booker_"
  uuid activity_id FK
  int booker_group_id "Bokarens kår id
  _Kopierat från Scoutnet_"
  text booker_group_name "Bokarens kårnamn
  _Kopierat från Scoutnet_"
  text group_free_text "Kår, Patrull"
  text responsible_name "Ansvarig vuxen"
  text phone_number "Till ansvarig vuxen"
  int participant_count
}

activity_user {
  uuid activity_id PK,FK
  uuid user_id PK,FK
}

location {
  uuid id PK
  text name
  text name_en
  text description
  text description_en
  text icon_name
  text icon_variant
  text color
  float8 latitude
  float8 longitude
  jsonb opening_hours "{ \"YYYY-MM-DD\": [{ from, to }] }"
}

location_tag_location {
  uuid location_tag_id PK,FK
  uuid location_id PK,FK
}

location_tag {
  uuid id PK
  text name
  text name_en
  text icon_name
  text icon_variant
}

location ||--o{ location_tag_location : tagged
location_tag ||--o{ location_tag_location : tags

activity }o--o| location : "happens_at (not initial scope)"


activity ||--o{ activity_user : organized_by
user ||--o{ activity_user : organizes

booking }o--|| activity : reserves
user ||--o{ booking : places
```

#### Non MVP Scout Group feature

```mermaid
erDiagram

scout_group {
  uuid id PK
  text name
  uuid created_by_user_id FK "_booker_"
}

user {
  uuid id PK
}

activity {
  uuid id PK
}

booking {
  uuid id PK
  uuid user_id FK "_booker_"
  uuid activity_id FK
}

booking_scout_group {
  uuid booking_id PK,FK
  uuid scout_group_id PK,FK
}

scout_group_user {
  uuid scout_group_id PK,FK
  uuid user_id PK,FK
}

activity_user {
  uuid activity_id PK,FK
  uuid user_id PK,FK
}

booking ||--o{ booking_scout_group : includes
scout_group ||--o{ booking_scout_group : part_of

scout_group ||--o{ scout_group_user : managed_by
user ||--o{ scout_group_user : manages

activity ||--o{ activity_user : organized_by
user ||--o{ activity_user : organizes

booking }o--|| activity : reserves
user ||--o{ booking : places
```

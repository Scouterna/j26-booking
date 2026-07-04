# Server CLAUDE.md

Server-specific guidance. See root `CLAUDE.md` for monorepo-wide info (commands, module map, database workflow).

## Patterns

- **Context threading**: `web.Context` is passed through middleware → router → handlers. Contains DB connection, auth state, static directory
- **Base path**: `web.base_path` is a hardcoded constant (`/_services/booking`), imported directly where needed — not passed through Context or function parameters
- **Middleware composition**: Uses `use` syntax with wisp middleware functions in `web.middleware()`
- **Squirrel workflow**: SQL files in `src/server/sql/` → `gleam run -m squirrel` → generates `sql.gleam` with typed functions
- **Env helpers**: `utils.gleam` provides `get_env`/`get_env_int`/`get_secret_key_base` for reading environment variables with defaults — used in `server.gleam` for config
- **Auth**: JWT verification keys fetched from OpenID Connect discovery on startup (stored in `Context.jwt_verify_keys`). `web.authenticate()` verifies the token from the `Authorization: Bearer` header, falling back to the httpOnly `j26-auth_access-token` cookie (sent automatically by browsers inside the j26-app shell), then to the `DEV_AUTH_ROLES` dev fallback user (local dev only). Handlers guard with `web.with_authenticated_user` (401) and `web.require_role` (403; `Admin` implies every role). Roles decode from `resource_access.j26-booking.roles`; the booker group id from the `groups` claim (`/j26-scoutid-sync/groups/<id>`)

## API changes

Whenever you change anything about the HTTP API — routes, request/response shapes, status codes, query parameters, error formats — update `server/priv/static/openapi.yaml` in the same change. The spec is served at `/api/docs` (Scalar UI) and is the contract clients rely on, so it must stay in sync with the code in `server/src/server/router.gleam`, `server/src/server/web/`, and `server/src/server/model/`.

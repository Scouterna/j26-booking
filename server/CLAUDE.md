# Server CLAUDE.md

Server-specific guidance. See root `CLAUDE.md` for monorepo-wide info (commands, module map, database workflow).

## Patterns

- **Context threading**: `web.Context` is passed through middleware → router → handlers. Contains DB connection, auth state, base_path, static directory
- **Middleware composition**: Uses `use` syntax with wisp middleware functions in `web.middleware()`
- **Squirrel workflow**: SQL files in `src/server/sql/` → `gleam run -m squirrel` → generates `sql.gleam` with typed functions
- **Auth**: JWT verification keys fetched from OpenID Connect discovery on startup (stored in `Context.jwt_verify_keys`). Authentication middleware in `web.gleam` (TODO: not fully wired up yet)

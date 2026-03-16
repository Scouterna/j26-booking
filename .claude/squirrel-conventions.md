# Squirrel Conventions

[Squirrel](https://hexdocs.pm/squirrel/index.html) generates type-safe Gleam code from plain SQL query files.

## How It Works

1. Write `.sql` files in `server/src/server/sql/`
2. Run `gleam run -m squirrel` (from `server/`)
3. Squirrel reads the SQL, connects to the database to infer types, and generates `server/src/server/sql.gleam`

**Never edit `sql.gleam` manually** — it is fully generated.

## SQL File Conventions

- **One query per file.** The filename becomes the generated function name (snake_case).
  - `create_booking.sql` → `sql.create_booking()`
- **Use `$1`, `$2`, …** for parameters. Squirrel infers their Gleam types from the database schema.
- **Use `RETURNING`** to get back typed rows. The returned columns define the generated Row type.
  - `create_booking.sql` with `RETURNING id, user_id, ...` → `CreateBookingRow` type
- **Comments** at the top of the file (starting with `--`) become the doc comment on the generated function.
- Squirrel maps PostgreSQL types to Gleam types:
  - `UUID` → `Uuid` (from `youid/uuid`)
  - `TEXT` → `String`
  - `INT` / `INTEGER` → `Int`
  - `TIMESTAMP` → `Timestamp` (from `gleam/time/timestamp`)
  - `NULLABLE` columns → `Option(T)`
  - Custom enums → `String` (Squirrel treats them as text)
- **Quote reserved words** in SQL (e.g., `"user"`) — PostgreSQL requires this for reserved identifiers.

## Generated Code Structure

For each `.sql` file, Squirrel generates:
- A **Row type**: `<PascalCaseFileName>Row` with a field per `RETURNING` / `SELECT` column
- A **query function**: `<snake_case_file_name>(db, arg_1, arg_2, ...)` returning `Result(pog.Returned(Row), pog.QueryError)`

## Naming Conventions

- Use descriptive verb-noun names: `create_booking`, `get_booking`, `delete_booking`
- For queries with different clauses, use suffixes: `get_bookings_by_activity`
- Match the existing patterns in the project (see `server/src/server/sql/` for examples)

## Workflow Checklist

1. Ensure migrations are applied (`gleam run -m cigogne last`)
2. Ensure `DATABASE_URL` is set and the database is running
3. Add/modify `.sql` files in `server/src/server/sql/`
4. Run `gleam run -m squirrel` to regenerate `sql.gleam`
5. Run `gleam format .` to format the generated code
6. Update model conversion functions if Row types changed

-- Creates the user row for a JWT-authenticated user on first sight, so
-- handlers can write rows with user_id foreign keys.
INSERT INTO "user" (id)
VALUES ($1) ON CONFLICT (id) DO NOTHING
RETURNING id

-- The kår display name for a Scoutnet kårnummer. Returns no row when the id
-- is not among the registered kårer — the caller falls back to 'Kår <id>',
-- matching the COALESCE fallback in the booking queries.
SELECT name
FROM scout_group
WHERE id = $1;

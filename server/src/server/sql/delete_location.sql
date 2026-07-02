-- Deletes a location, returning its id if it existed.
DELETE FROM location
WHERE id = $1
RETURNING id;

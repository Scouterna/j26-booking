-- Deletes a location tag, returning its id if it existed.
DELETE FROM location_tag
WHERE id = $1
RETURNING id;

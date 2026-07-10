-- Deletes an activity tag, returning its id if it existed.
DELETE FROM activity_tag
WHERE id = $1
RETURNING id;

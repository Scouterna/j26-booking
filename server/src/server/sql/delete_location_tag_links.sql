-- Removes all tag links for a location (used when re-syncing or deleting).
DELETE FROM location_tag_location
WHERE location_id = $1;

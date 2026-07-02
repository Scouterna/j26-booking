-- Removes all location links for a tag (used before deleting the tag).
DELETE FROM location_tag_location
WHERE location_tag_id = $1;

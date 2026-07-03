-- Lists the tag ids linked to a location.
SELECT location_tag_id
FROM location_tag_location
WHERE location_id = $1;

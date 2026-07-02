-- Links a location to the given tag ids in one statement. An empty array
-- inserts no rows.
INSERT INTO location_tag_location (location_id, location_tag_id)
SELECT $1, unnest($2::uuid[]);

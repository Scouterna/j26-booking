-- Links an activity to the given tag ids in one statement. An empty array
-- inserts no rows.
INSERT INTO activity_tag_activity (activity_id, activity_tag_id)
SELECT $1, unnest($2::uuid[]);

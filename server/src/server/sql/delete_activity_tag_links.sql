-- Removes all tag links for an activity (used when re-syncing or deleting).
DELETE FROM activity_tag_activity
WHERE activity_id = $1;

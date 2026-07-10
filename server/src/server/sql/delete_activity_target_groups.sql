-- Removes all target groups for an activity (used when re-syncing or deleting).
DELETE FROM activity_target_group
WHERE activity_id = $1;

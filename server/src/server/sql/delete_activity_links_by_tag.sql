-- Removes all activity links for a tag (used before deleting the tag).
DELETE FROM activity_tag_activity
WHERE activity_tag_id = $1;

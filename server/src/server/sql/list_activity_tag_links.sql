-- Lists every activity-to-tag link. Grouped by activity in the handler to embed
-- each activity's tag ids without an array aggregation.
SELECT activity_id,
    activity_tag_id
FROM activity_tag_activity;

-- Lists every activity-to-target-group link. Grouped by activity in the handler
-- to embed each activity's target groups without an array aggregation.
SELECT activity_id,
    target_group
FROM activity_target_group;

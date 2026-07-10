-- Sets an activity's target groups in one statement. Casting the array to the
-- enum type makes Squirrel type the parameter as the generated target group
-- type. An empty array inserts no rows.
INSERT INTO activity_target_group (activity_id, target_group)
SELECT $1, unnest($2::target_group[]);

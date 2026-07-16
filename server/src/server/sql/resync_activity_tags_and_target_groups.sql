-- Re-syncs an activity's tag links and target groups to the given sets in one
-- statement. A naive delete-all + insert-all can't be a single statement: all
-- data-modifying CTEs share one snapshot, so the inserts wouldn't see the
-- deletes and would collide with still-present rows on any overlap. Instead this
-- deletes only rows no longer wanted and inserts only rows not already present,
-- so the deletes and inserts touch disjoint rows and never conflict. The insert
-- filters read the pre-delete snapshot, which is exactly what we want. Empty
-- arrays delete everything and insert nothing.
WITH desired_tags AS (SELECT unnest($2::uuid[]) AS tag),
desired_target_groups AS (SELECT unnest($3::target_group[]) AS target_group),
deleted_tags AS (
  DELETE FROM activity_tag_activity
  WHERE activity_id = $1
    AND activity_tag_id NOT IN (SELECT tag FROM desired_tags)
),
inserted_tags AS (
  INSERT INTO activity_tag_activity (activity_id, activity_tag_id)
  SELECT $1, tag FROM desired_tags
  WHERE tag NOT IN (
    SELECT activity_tag_id FROM activity_tag_activity WHERE activity_id = $1
  )
),
deleted_target_groups AS (
  DELETE FROM activity_target_group
  WHERE activity_id = $1
    AND target_group NOT IN (SELECT target_group FROM desired_target_groups)
)
INSERT INTO activity_target_group (activity_id, target_group)
SELECT $1, target_group FROM desired_target_groups
WHERE target_group NOT IN (
  SELECT target_group FROM activity_target_group WHERE activity_id = $1
);

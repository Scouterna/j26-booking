SELECT *
FROM activity
WHERE recurring_activity_kind IS NULL
ORDER BY start_time ASC;

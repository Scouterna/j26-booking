SELECT *
FROM activity
WHERE recurring_activity_kind IS NULL
ORDER BY title ASC;

SELECT *
FROM activity
ORDER BY start_time ASC
LIMIT $1 OFFSET $2;
SELECT DISTINCT activity.*
FROM activity
WHERE activity.id IN (SELECT activity_id FROM favourite WHERE user_id = $1)
   OR activity.id IN (SELECT activity_id FROM booking WHERE user_id = $1)
ORDER BY activity.start_time ASC;

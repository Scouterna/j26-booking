SELECT id
FROM booking
WHERE user_id = $1
    AND activity_id = $2
LIMIT 1

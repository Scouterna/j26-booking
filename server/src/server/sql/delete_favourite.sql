DELETE FROM favourite
WHERE user_id = $1
    AND activity_id = $2
RETURNING id

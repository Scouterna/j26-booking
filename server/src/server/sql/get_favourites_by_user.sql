SELECT id,
    user_id,
    activity_id
FROM favourite
WHERE user_id = $1
ORDER BY id

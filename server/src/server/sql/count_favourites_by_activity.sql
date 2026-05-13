SELECT COUNT(*) AS favourite_count
FROM favourite
WHERE activity_id = $1

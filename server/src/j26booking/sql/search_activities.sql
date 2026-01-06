-- Search for activity titles
SELECT *
FROM activity
WHERE title ILIKE '%' || $1 || '%'
ORDER BY title;
-- Gets a single activity tag by id.
SELECT id,
    name,
    name_en
FROM activity_tag
WHERE id = $1;

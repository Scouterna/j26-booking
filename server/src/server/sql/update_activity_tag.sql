-- Updates an activity tag and returns it.
UPDATE activity_tag
SET name = $2,
    name_en = $3
WHERE id = $1
RETURNING id,
    name,
    name_en;

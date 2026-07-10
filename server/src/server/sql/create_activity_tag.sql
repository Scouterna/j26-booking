-- Creates an activity tag and returns it.
INSERT INTO activity_tag (id, name, name_en)
VALUES ($1, $2, $3)
RETURNING id,
    name,
    name_en;

-- Lists all activity tags ordered by name.
SELECT id,
    name,
    name_en
FROM activity_tag
ORDER BY name ASC;

-- Lists all location tags ordered by name.
SELECT id,
    name,
    name_en,
    icon_name
FROM location_tag
ORDER BY name ASC;

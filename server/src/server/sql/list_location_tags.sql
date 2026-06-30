-- Lists all location tags ordered by name.
SELECT id,
    name,
    name_en,
    icon_name,
    icon_variant
FROM location_tag
ORDER BY name ASC;

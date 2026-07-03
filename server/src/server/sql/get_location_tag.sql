-- Gets a single location tag by id.
SELECT id,
    name,
    name_en,
    icon_name,
    icon_variant
FROM location_tag
WHERE id = $1;

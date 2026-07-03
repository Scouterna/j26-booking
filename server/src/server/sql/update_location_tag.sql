-- Updates a location tag and returns it.
UPDATE location_tag
SET name = $2,
    name_en = $3,
    icon_name = $4,
    icon_variant = $5
WHERE id = $1
RETURNING id,
    name,
    name_en,
    icon_name,
    icon_variant;

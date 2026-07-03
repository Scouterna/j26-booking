-- Creates a location tag and returns it.
INSERT INTO location_tag (id, name, name_en, icon_name, icon_variant)
VALUES ($1, $2, $3, $4, $5)
RETURNING id,
    name,
    name_en,
    icon_name,
    icon_variant;

-- Updates a location, setting its coordinates, and returns it. opening_hours
-- is sent as JSON text; the parameter type is inferred as jsonb from the
-- target column. Squirrel cannot generate optional query parameters, so
-- clearing the coordinates goes through the _without_coordinates variant.
UPDATE location
SET name = $2,
    name_en = $3,
    description = $4,
    description_en = $5,
    icon_name = $6,
    icon_variant = $7,
    color = $8,
    latitude = $9,
    longitude = $10,
    opening_hours = $11
WHERE id = $1
RETURNING id,
    name,
    name_en,
    description,
    description_en,
    icon_name,
    icon_variant,
    color,
    latitude,
    longitude,
    opening_hours;

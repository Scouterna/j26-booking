-- Updates a location, clearing its coordinates, and returns it. opening_hours
-- is sent as JSON text; the parameter type is inferred as jsonb from the
-- target column. Squirrel cannot generate optional query parameters, so the
-- NULL coordinates are literals here rather than parameters of the
-- _with_coordinates variant.
UPDATE location
SET name = $2,
    name_en = $3,
    description = $4,
    description_en = $5,
    icon_name = $6,
    icon_variant = $7,
    color = $8,
    latitude = NULL,
    longitude = NULL,
    opening_hours = $9
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

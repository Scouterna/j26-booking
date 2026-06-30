-- Lists all locations ordered by name. `opening_hours` is returned as a JSON
-- string (cast from jsonb) for the model layer to parse.
SELECT id,
    name,
    name_en,
    description,
    description_en,
    icon_name,
    icon_variant,
    color,
    latitude,
    longitude,
    opening_hours::text AS opening_hours
FROM location
ORDER BY name ASC;

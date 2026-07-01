-- Lists all locations ordered by name. `opening_hours` (jsonb) comes back as
-- its JSON text, which Squirrel maps to a String for the model layer to parse.
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
    opening_hours
FROM location
ORDER BY name ASC;

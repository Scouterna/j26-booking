-- Lists locations ordered by name. `opening_hours` (jsonb) comes back as its
-- JSON text, which Squirrel maps to a String for the model layer to parse.
--
-- When $1 is true, only locations referenced by at least one activity are
-- returned — the activity list's location filter uses this so facility-only
-- locations (toilets, info points, …) that no activity links to aren't offered.
-- When $1 is false, every location is returned (e.g. the activity form's
-- location picker, which must be able to assign any location).
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
WHERE NOT $1
    OR EXISTS (
        SELECT 1
        FROM activity
        WHERE activity.location_id = location.id
    )
ORDER BY name ASC;

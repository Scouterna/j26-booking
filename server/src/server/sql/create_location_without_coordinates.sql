-- Creates a location that has no coordinates (name-only, no map marker) and
-- returns it. opening_hours is sent as JSON text; the parameter type is
-- inferred as jsonb from the target column. Squirrel cannot generate optional
-- query parameters, so the NULL coordinates are literals here rather than
-- parameters of the _with_coordinates variant.
INSERT INTO location (
        id,
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
    )
VALUES (
        $1,
        $2,
        $3,
        $4,
        $5,
        $6,
        $7,
        $8,
        NULL,
        NULL,
        $9
    )
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

--- migration:up
CREATE TABLE location(
    id UUID PRIMARY KEY,
    name TEXT NOT NULL,
    name_en TEXT NOT NULL,
    description TEXT NOT NULL,
    description_en TEXT NOT NULL,
    icon_name TEXT NOT NULL,
    color TEXT NOT NULL,
    latitude FLOAT8 NOT NULL,
    longitude FLOAT8 NOT NULL,
    opening_hours JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE location_tag(
    id UUID PRIMARY KEY,
    name TEXT NOT NULL,
    name_en TEXT NOT NULL,
    icon_name TEXT NOT NULL
);

CREATE TABLE location_tag_location(
    location_tag_id UUID NOT NULL REFERENCES location_tag(id),
    location_id UUID NOT NULL REFERENCES location(id),
    PRIMARY KEY (location_tag_id, location_id)
);

CREATE INDEX location_tag_location_location_id_idx ON location_tag_location (location_id);
--- migration:down
DROP TABLE location_tag_location;
DROP TABLE location_tag;
DROP TABLE location;
--- migration:end

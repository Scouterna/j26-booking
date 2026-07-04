--- migration:up
ALTER TABLE activity
ADD COLUMN location_id UUID REFERENCES location(id);

CREATE INDEX activity_location_id_idx ON activity (location_id);
--- migration:down
DROP INDEX activity_location_id_idx;

ALTER TABLE activity
DROP COLUMN location_id;
--- migration:end

--- migration:up
ALTER TABLE booking ADD COLUMN booked_for_other BOOLEAN NOT NULL DEFAULT FALSE;
--- migration:down
ALTER TABLE booking DROP COLUMN booked_for_other;
--- migration:end

--- migration:up
ALTER TABLE activity ADD COLUMN booking_opens_at TIMESTAMP;
--- migration:down
ALTER TABLE activity DROP COLUMN booking_opens_at;
--- migration:end

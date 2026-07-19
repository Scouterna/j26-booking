--- migration:up
ALTER TABLE booking ADD COLUMN cancellation_reason TEXT;
--- migration:down
ALTER TABLE booking DROP COLUMN cancellation_reason;
--- migration:end

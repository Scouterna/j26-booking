--- migration:up
ALTER TABLE activity ADD COLUMN recurring_activity_kind TEXT;
--- migration:down
ALTER TABLE activity DROP COLUMN recurring_activity_kind;
--- migration:end

--- migration:up
UPDATE activity SET description = '' WHERE description IS NULL;
ALTER TABLE activity ALTER COLUMN description SET NOT NULL;
--- migration:down
ALTER TABLE activity ALTER COLUMN description DROP NOT NULL;
--- migration:end
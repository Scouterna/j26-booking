--- migration:up
ALTER TABLE booking ALTER COLUMN booker_group_id DROP NOT NULL;
ALTER TABLE booking ALTER COLUMN booker_group_name DROP NOT NULL;
ALTER TABLE booking ADD COLUMN booker_name TEXT NOT NULL DEFAULT '';
ALTER TABLE booking ALTER COLUMN booker_name DROP DEFAULT;
--- migration:down
ALTER TABLE booking DROP COLUMN booker_name;
ALTER TABLE booking ALTER COLUMN booker_group_name SET NOT NULL;
ALTER TABLE booking ALTER COLUMN booker_group_id SET NOT NULL;
--- migration:end

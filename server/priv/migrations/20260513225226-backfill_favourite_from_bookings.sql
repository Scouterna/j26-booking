--- migration:up
INSERT INTO favourite (id, user_id, activity_id)
SELECT gen_random_uuid(),
    user_id,
    activity_id
FROM booking ON CONFLICT (user_id, activity_id) DO NOTHING;
--- migration:down
-- Backfill cannot be safely reverted without distinguishing manually-added favourites
-- from those backfilled here. Down migration is a no-op.
SELECT 1;
--- migration:end

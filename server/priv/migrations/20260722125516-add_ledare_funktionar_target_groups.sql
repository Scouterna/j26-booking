--- migration:up
ALTER TYPE target_group ADD VALUE 'ledare';
ALTER TYPE target_group ADD VALUE 'funktionar';
--- migration:down
DELETE FROM activity_target_group WHERE target_group IN ('ledare', 'funktionar');

CREATE TYPE target_group_old AS ENUM (
    'sparare',
    'upptackare',
    'aventyrare',
    'utmanare',
    'rover'
);

ALTER TABLE activity_target_group
    ALTER COLUMN target_group TYPE target_group_old
    USING target_group::text::target_group_old;

DROP TYPE target_group;

ALTER TYPE target_group_old RENAME TO target_group;
--- migration:end
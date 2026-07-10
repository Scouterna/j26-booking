--- migration:up
CREATE TYPE target_group AS ENUM (
    'sparare',
    'upptackare',
    'aventyrare',
    'utmanare',
    'rover'
);

CREATE TABLE activity_target_group(
    activity_id UUID NOT NULL REFERENCES activity(id),
    target_group target_group NOT NULL,
    PRIMARY KEY (activity_id, target_group)
);
--- migration:down
DROP TABLE activity_target_group;
DROP TYPE target_group;
--- migration:end
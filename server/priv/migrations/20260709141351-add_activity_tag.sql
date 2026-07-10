--- migration:up
CREATE TABLE activity_tag(
    id UUID PRIMARY KEY,
    name TEXT NOT NULL,
    name_en TEXT NOT NULL
);

CREATE TABLE activity_tag_activity(
    activity_tag_id UUID NOT NULL REFERENCES activity_tag(id),
    activity_id UUID NOT NULL REFERENCES activity(id),
    PRIMARY KEY (activity_tag_id, activity_id)
);

CREATE INDEX activity_tag_activity_activity_id_idx ON activity_tag_activity (activity_id);
--- migration:down
DROP TABLE activity_tag_activity;
DROP TABLE activity_tag;
--- migration:end
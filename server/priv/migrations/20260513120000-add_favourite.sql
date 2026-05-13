--- migration:up
CREATE TABLE favourite(
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES "user"(id),
    activity_id UUID NOT NULL REFERENCES activity(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, activity_id)
);

CREATE INDEX favourite_user_id_idx ON favourite (user_id);

CREATE INDEX favourite_activity_id_idx ON favourite (activity_id);
--- migration:down
DROP TABLE favourite;
--- migration:end

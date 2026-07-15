--- migration:up
CREATE TABLE call_off(
    id UUID PRIMARY KEY,
    activity_id UUID NOT NULL REFERENCES activity(id),
    reason TEXT NOT NULL,
    cancelled_at TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE (activity_id)
);

CREATE INDEX call_off_activity_id_idx ON call_off (activity_id);

--- migration:down
DROP TABLE call_off;

--- migration:end

--- migration:up
CREATE TABLE activity(
    id UUID PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    max_attendees INT,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL
);
--- migration:down
DROP TABLE activity;
--- migration:end
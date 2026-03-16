--- migration:up
CREATE TYPE user_role AS ENUM ('organizer', 'booker', 'admin');

CREATE TABLE "user"(
    id UUID PRIMARY KEY,
    role user_role NOT NULL
);

CREATE TABLE booking(
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES "user"(id),
    activity_id UUID NOT NULL REFERENCES activity(id),
    booker_group_id INT NOT NULL,
    booker_group_name TEXT NOT NULL,
    group_free_text TEXT NOT NULL,
    responsible_name TEXT NOT NULL,
    phone_number TEXT NOT NULL,
    participant_count INT NOT NULL
);

CREATE TABLE activity_user(
    activity_id UUID NOT NULL REFERENCES activity(id),
    user_id UUID NOT NULL REFERENCES "user"(id),
    PRIMARY KEY (activity_id, user_id)
);
--- migration:down
DROP TABLE activity_user;
DROP TABLE booking;
DROP TABLE "user";
DROP TYPE user_role;
--- migration:end

--- migration:up
ALTER TABLE activity
    ADD COLUMN title_en TEXT,
    ADD COLUMN description_en TEXT;

UPDATE activity
SET title_en = title,
    description_en = description;

ALTER TABLE activity
    ALTER COLUMN title_en SET NOT NULL,
    ALTER COLUMN description_en SET NOT NULL;

--- migration:down
ALTER TABLE activity
    DROP COLUMN title_en,
    DROP COLUMN description_en;

--- migration:end

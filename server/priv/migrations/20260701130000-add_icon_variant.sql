--- migration:up
ALTER TABLE location
    ADD COLUMN icon_variant TEXT NOT NULL DEFAULT 'outline';

ALTER TABLE location_tag
    ADD COLUMN icon_variant TEXT NOT NULL DEFAULT 'outline';
--- migration:down
ALTER TABLE location DROP COLUMN icon_variant;
ALTER TABLE location_tag DROP COLUMN icon_variant;
--- migration:end

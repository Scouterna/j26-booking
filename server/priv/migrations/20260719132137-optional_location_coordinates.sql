--- migration:up
ALTER TABLE location
    ALTER COLUMN latitude DROP NOT NULL,
    ALTER COLUMN longitude DROP NOT NULL,
    ADD CONSTRAINT location_coordinates_paired
        CHECK ((latitude IS NULL) = (longitude IS NULL));
--- migration:down
ALTER TABLE location
    DROP CONSTRAINT location_coordinates_paired,
    ALTER COLUMN latitude SET NOT NULL,
    ALTER COLUMN longitude SET NOT NULL;
--- migration:end

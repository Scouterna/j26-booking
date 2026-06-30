-- Lists every location-to-tag link. Joined to locations in the handler to embed
-- each location's tag ids without an array aggregation.
SELECT location_id,
    location_tag_id
FROM location_tag_location;

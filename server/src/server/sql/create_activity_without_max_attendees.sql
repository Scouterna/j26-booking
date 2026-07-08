INSERT INTO activity (
        id,
        title,
        title_en,
        description,
        description_en,
        max_attendees,
        start_time,
        end_time
    )
VALUES ($1, $2, $3, $4, $5, NULL, $6, $7)
RETURNING id,
    title,
    title_en,
    description,
    description_en,
    start_time,
    end_time,
    location_id
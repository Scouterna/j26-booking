UPDATE activity
SET title = $2,
    title_en = $3,
    description = $4,
    description_en = $5,
    max_attendees = NULL,
    start_time = $6,
    end_time = $7
WHERE id = $1
RETURNING id,
    title,
    title_en,
    description,
    description_en,
    start_time,
    end_time,
    location_id
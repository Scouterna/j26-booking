UPDATE activity
SET title = $2,
    title_en = $3,
    description = $4,
    description_en = $5,
    max_attendees = $6,
    start_time = $7,
    end_time = $8
WHERE id = $1
RETURNING id,
    title,
    title_en,
    description,
    description_en,
    max_attendees,
    start_time,
    end_time,
    location_id,
    booking_opens_at
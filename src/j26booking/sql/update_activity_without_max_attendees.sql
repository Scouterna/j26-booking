UPDATE activity
SET title = $2,
    description = $3,
    max_attendees = NULL,
    start_time = $4,
    end_time = $5
WHERE id = $1
RETURNING id,
    title,
    description,
    start_time,
    end_time
UPDATE activity
SET title = $2,
    description = $3,
    max_attendees = $4,
    start_time = $5,
    end_time = $6
WHERE id = $1
RETURNING id,
    title,
    description,
    max_attendees,
    start_time,
    end_time
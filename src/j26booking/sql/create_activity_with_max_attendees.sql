INSERT INTO activity (id, title, description, max_attendees, start_time, end_time)
VALUES ($1, $2, $3, $4, $5, $6)
RETURNING id, title, description, max_attendees, start_time, end_time

INSERT INTO activity (id, title, description, max_attendees, start_time, end_time)
VALUES ($1, $2, $3, NULL, $4, $5)
RETURNING id, title, description, start_time, end_time

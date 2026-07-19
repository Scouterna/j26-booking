-- Whether the user has a cancelled booking on the activity. A cancelled
-- booking blocks re-booking until a bookings:others:create holder restores
-- or hard-deletes it (the create handler answers 409).
SELECT id
FROM booking
WHERE user_id = $1
    AND activity_id = $2
    AND cancellation_reason IS NOT NULL
LIMIT 1

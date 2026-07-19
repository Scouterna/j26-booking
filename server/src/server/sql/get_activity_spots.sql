-- Booked spot count for a single activity. The aggregate has no GROUP BY, so
-- it always returns exactly one row (0 when the activity has no bookings).
-- Cancelled bookings don't occupy spots.
SELECT COALESCE(SUM(participant_count), 0) AS spots_booked
FROM booking
WHERE activity_id = $1
    AND cancellation_reason IS NULL

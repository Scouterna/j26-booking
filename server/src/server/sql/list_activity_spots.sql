-- Booked spot count per activity. LEFT JOIN so activities with no bookings
-- return 0 (not absent) — the client distinguishes known-zero from unknown.
-- Cancelled bookings don't occupy spots.
SELECT activity.id AS activity_id,
    COALESCE(SUM(booking.participant_count), 0) AS spots_booked
FROM activity
    LEFT JOIN booking ON booking.activity_id = activity.id
    AND booking.cancellation_reason IS NULL
GROUP BY activity.id

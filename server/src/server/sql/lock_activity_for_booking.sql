-- Lock a single activity row for the duration of the transaction and return
-- what the booking create flow validates against: the capacity and the booking
-- window (opens-at override plus start/end times). Locking serialises
-- concurrent bookings for the same activity so the checks can't be raced.
SELECT max_attendees,
    start_time,
    end_time,
    booking_opens_at
FROM activity
WHERE id = $1
FOR UPDATE;

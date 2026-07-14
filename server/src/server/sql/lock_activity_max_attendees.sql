-- Lock a single activity row for the duration of the transaction and return
-- its capacity. Used by the booking create/update flow to serialise concurrent
-- bookings for the same activity so the capacity check can't be raced.
SELECT max_attendees
FROM activity
WHERE id = $1
FOR UPDATE;

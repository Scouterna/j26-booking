-- Clear an activity's booking-opens-at override so it falls back to the
-- global BOOKING_OPENS_AT default. Counterpart of
-- set_activity_booking_opens_at.
UPDATE activity
SET booking_opens_at = NULL
WHERE id = $1

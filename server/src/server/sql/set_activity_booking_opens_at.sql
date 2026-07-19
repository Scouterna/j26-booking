-- Set an activity's per-activity booking-opens-at override. Cleared with
-- clear_activity_booking_opens_at (the column is nullable and squirrel
-- parameters are not, hence the set/clear pair — same pattern as
-- set/clear_activity_location).
UPDATE activity
SET booking_opens_at = $2
WHERE id = $1

-- Soft-cancel a booking: store the reason a bookings:others:create holder
-- gave. A cancelled booking stops occupying spots (the capacity aggregates
-- exclude it) but stays visible in booking lists so both the booker and the
-- staff can see that it was removed and why.
UPDATE booking
SET cancellation_reason = $2
WHERE id = $1
RETURNING id,
    user_id,
    activity_id,
    booker_name,
    booker_group_id,
    booker_group_name,
    group_free_text,
    responsible_name,
    phone_number,
    participant_count,
    booked_for_other,
    cancellation_reason

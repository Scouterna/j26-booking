-- Soft-cancel a booking: store the reason a bookings:others:create holder
-- gave. A cancelled booking stops occupying spots (the capacity aggregates
-- exclude it) but stays visible in booking lists so both the booker and the
-- staff can see that it was removed and why. The booker's kår name is derived
-- by joining scout_group on the returned booking.
WITH cancelled AS (
    UPDATE booking
    SET cancellation_reason = $2
    WHERE id = $1
    RETURNING id,
        user_id,
        activity_id,
        booker_name,
        booker_group_id,
        group_free_text,
        responsible_name,
        phone_number,
        participant_count,
        booked_for_other,
        cancellation_reason
)
SELECT c.id,
    c.user_id,
    c.activity_id,
    c.booker_name,
    c.booker_group_id,
    COALESCE(sg.name, 'Kår ' || c.booker_group_id, '') AS booker_group_name,
    c.group_free_text,
    c.responsible_name,
    c.phone_number,
    c.participant_count,
    c.booked_for_other,
    c.cancellation_reason
FROM cancelled c
    LEFT JOIN scout_group sg ON sg.id = c.booker_group_id

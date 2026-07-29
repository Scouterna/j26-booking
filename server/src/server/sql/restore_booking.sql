-- Restore a cancelled booking to active by clearing its reason. The handler
-- re-checks capacity first — a restored booking occupies spots again. The
-- booker's kår name is derived by joining scout_group on the returned booking.
WITH restored AS (
    UPDATE booking
    SET cancellation_reason = NULL
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
        cancellation_reason,
        left_campsite,
        left_beach
)
SELECT r.id,
    r.user_id,
    r.activity_id,
    r.booker_name,
    r.booker_group_id,
    COALESCE(sg.name, 'Kår ' || r.booker_group_id, '') AS booker_group_name,
    r.group_free_text,
    r.responsible_name,
    r.phone_number,
    r.participant_count,
    r.booked_for_other,
    r.cancellation_reason,
    r.left_campsite,
    r.left_beach
FROM restored r
    LEFT JOIN scout_group sg ON sg.id = r.booker_group_id

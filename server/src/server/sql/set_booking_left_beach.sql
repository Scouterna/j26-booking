-- Tick (or untick) the badbuss "left the beach" check-off on one booking. The
-- sibling of set_booking_left_campsite — see that file for why each stage gets
-- its own single-column write.
WITH ticked AS (
    UPDATE booking
    SET left_beach = $2
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
SELECT t.id,
    t.user_id,
    t.activity_id,
    t.booker_name,
    t.booker_group_id,
    COALESCE(sg.name, 'Kår ' || t.booker_group_id, '') AS booker_group_name,
    t.group_free_text,
    t.responsible_name,
    t.phone_number,
    t.participant_count,
    t.booked_for_other,
    t.cancellation_reason,
    t.left_campsite,
    t.left_beach
FROM ticked t
    LEFT JOIN scout_group sg ON sg.id = t.booker_group_id

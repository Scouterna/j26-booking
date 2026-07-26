-- The booker's kår name is derived by joining scout_group on the returned
-- booking; a kårnummer not among the registered kårer renders as 'Kår <id>'.
-- A booking without a kår yields '' (squirrel cannot type expressions as
-- nullable) — the model layer derives the Option from booker_group_id.
WITH updated AS (
    UPDATE booking
    SET group_free_text = $2,
        responsible_name = $3,
        phone_number = $4,
        participant_count = $5
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
SELECT u.id,
    u.user_id,
    u.activity_id,
    u.booker_name,
    u.booker_group_id,
    COALESCE(sg.name, 'Kår ' || u.booker_group_id, '') AS booker_group_name,
    u.group_free_text,
    u.responsible_name,
    u.phone_number,
    u.participant_count,
    u.booked_for_other,
    u.cancellation_reason
FROM updated u
    LEFT JOIN scout_group sg ON sg.id = u.booker_group_id

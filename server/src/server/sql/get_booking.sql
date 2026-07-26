-- The booker's kår name is derived by joining scout_group; a kårnummer not
-- among the registered kårer renders as 'Kår <id>'. A booking without a kår
-- yields '' (squirrel cannot type expressions as nullable) — the model layer
-- derives the Option from booker_group_id.
SELECT b.id,
    b.user_id,
    b.activity_id,
    b.booker_name,
    b.booker_group_id,
    COALESCE(sg.name, 'Kår ' || b.booker_group_id, '') AS booker_group_name,
    b.group_free_text,
    b.responsible_name,
    b.phone_number,
    b.participant_count,
    b.booked_for_other,
    b.cancellation_reason
FROM booking b
    LEFT JOIN scout_group sg ON sg.id = b.booker_group_id
WHERE b.id = $1

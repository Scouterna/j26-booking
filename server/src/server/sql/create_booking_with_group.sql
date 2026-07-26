-- The kår name is not stored on the row — it is derived by joining
-- scout_group on the returned booking, falling back to 'Kår <id>' for a
-- kårnummer not among the registered kårer.
WITH inserted AS (
    INSERT INTO booking (
            id,
            user_id,
            activity_id,
            booker_name,
            booker_group_id,
            group_free_text,
            responsible_name,
            phone_number,
            participant_count,
            booked_for_other
        )
    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
    RETURNING id,
        user_id,
        activity_id,
        booker_name,
        booker_group_id,
        group_free_text,
        responsible_name,
        phone_number,
        participant_count,
        booked_for_other
)
SELECT i.id,
    i.user_id,
    i.activity_id,
    i.booker_name,
    i.booker_group_id,
    COALESCE(sg.name, 'Kår ' || i.booker_group_id, '') AS booker_group_name,
    i.group_free_text,
    i.responsible_name,
    i.phone_number,
    i.participant_count,
    i.booked_for_other
FROM inserted i
    LEFT JOIN scout_group sg ON sg.id = i.booker_group_id

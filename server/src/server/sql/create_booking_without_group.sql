INSERT INTO booking (
        id,
        user_id,
        activity_id,
        booker_name,
        booker_group_id,
        group_free_text,
        responsible_name,
        phone_number,
        participant_count
    )
VALUES ($1, $2, $3, $4, NULL, $5, $6, $7, $8)
RETURNING id,
    user_id,
    activity_id,
    booker_name,
    group_free_text,
    responsible_name,
    phone_number,
    participant_count

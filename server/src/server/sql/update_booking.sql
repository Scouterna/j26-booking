UPDATE booking
SET group_free_text = $2,
    responsible_name = $3,
    phone_number = $4,
    participant_count = $5
WHERE id = $1
RETURNING id,
    user_id,
    activity_id,
    booker_group_id,
    booker_group_name,
    group_free_text,
    responsible_name,
    phone_number,
    participant_count

SELECT id,
    user_id,
    activity_id,
    booker_group_id,
    booker_group_name,
    group_free_text,
    responsible_name,
    phone_number,
    participant_count
FROM booking
WHERE id = $1

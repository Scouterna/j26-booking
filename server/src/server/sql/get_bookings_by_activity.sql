SELECT id,
    user_id,
    activity_id,
    booker_name,
    booker_group_id,
    booker_group_name,
    group_free_text,
    responsible_name,
    phone_number,
    participant_count,
    booked_for_other
FROM booking
WHERE activity_id = $1
ORDER BY responsible_name ASC
LIMIT $2
OFFSET $3

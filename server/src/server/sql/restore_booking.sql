-- Restore a cancelled booking to active by clearing its reason. The handler
-- re-checks capacity first — a restored booking occupies spots again.
UPDATE booking
SET cancellation_reason = NULL
WHERE id = $1
RETURNING id,
    user_id,
    activity_id,
    booker_name,
    booker_group_id,
    booker_group_name,
    group_free_text,
    responsible_name,
    phone_number,
    participant_count,
    booked_for_other,
    cancellation_reason

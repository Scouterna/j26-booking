SELECT id,
    activity_id,
    reason,
    cancelled_at
FROM call_off
WHERE activity_id = $1;

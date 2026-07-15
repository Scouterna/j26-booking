SELECT *
FROM activity
WHERE recurring_activity_kind IS NULL
    AND (
        NOT EXISTS (
            SELECT 1 FROM call_off c WHERE c.activity_id = activity.id
        )
        OR $1 = TRUE
        OR activity.id IN (SELECT activity_id FROM favourite WHERE user_id = $2)
        OR activity.id IN (SELECT activity_id FROM booking WHERE user_id = $2)
    )
ORDER BY start_time ASC;

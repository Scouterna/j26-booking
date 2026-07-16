SELECT *
FROM activity
WHERE recurring_activity_kind = 'climbing-wall'
    AND (
        $1 = TRUE
        OR NOT EXISTS (
            SELECT 1 FROM call_off c WHERE c.activity_id = activity.id
        )
    )
ORDER BY start_time ASC;

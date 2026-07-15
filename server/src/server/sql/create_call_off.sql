INSERT INTO call_off (id, activity_id, reason)
VALUES ($1, $2, $3) ON CONFLICT (activity_id) DO
UPDATE
SET reason = EXCLUDED.reason,
    cancelled_at = NOW();

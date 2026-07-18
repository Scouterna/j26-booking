-- Per-slot booking aggregate for a recurring activity kind ('beach-bus' /
-- 'climbing-wall'), powering the Badbuss / Klättervägg overview. Returns one
-- row per (activity, booker group): `group_count` is that group's participant
-- total and `booking_count` how many bookings it aggregates. An activity with
-- no bookings still yields a single row (LEFT JOIN) with NULL group columns and
-- a zero `booking_count`, so every bookable slot appears. Called-off slots are
-- excluded. Restricted to a single day window: `$2` (inclusive) .. `$3`
-- (exclusive), matching the activity list queries. Ordered so a slot's rows are
-- contiguous and groups sort by name.
SELECT
    a.id AS activity_id,
    a.start_time,
    a.end_time,
    a.max_attendees,
    b.booker_group_id,
    b.booker_group_name,
    COALESCE(SUM(b.participant_count), 0)::int AS group_count,
    COUNT(b.id) AS booking_count
FROM activity a
LEFT JOIN booking b ON b.activity_id = a.id
WHERE a.recurring_activity_kind = $1
    AND NOT EXISTS (
        SELECT 1 FROM call_off c WHERE c.activity_id = a.id
    )
    AND a.start_time >= $2
    AND a.start_time < $3
GROUP BY a.id, a.start_time, a.end_time, a.max_attendees,
    b.booker_group_id, b.booker_group_name
ORDER BY a.start_time ASC, a.id, b.booker_group_name ASC;

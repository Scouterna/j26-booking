-- Per-slot booking aggregate for a recurring activity kind ('beach-bus' /
-- 'climbing-wall'), powering the Badbuss / Klättervägg overview. Returns one
-- row per (activity, booker group): `group_count` is that group's participant
-- total and `booking_count` how many bookings it aggregates. An activity with
-- no bookings still yields a single row (LEFT JOIN) with NULL group columns and
-- a zero `booking_count`, so every bookable slot appears. Called-off slots and
-- cancelled bookings are excluded. Restricted to a single day window: `$2`
-- (inclusive) .. `$3` (exclusive), matching the activity list queries. Ordered
-- so a slot's rows are contiguous and groups sort by name. The kår name is
-- derived by joining scout_group; a kårnummer not among the registered kårer
-- renders as 'Kår <id>'. A booking without a kår yields '' (squirrel cannot
-- type expressions as nullable) — the model layer derives the Option from
-- booker_group_id.
SELECT
    a.id AS activity_id,
    a.start_time,
    a.end_time,
    a.max_attendees,
    b.booker_group_id,
    COALESCE(sg.name, 'Kår ' || b.booker_group_id, '') AS booker_group_name,
    COALESCE(SUM(b.participant_count), 0)::int AS group_count,
    COUNT(b.id) AS booking_count
FROM activity a
LEFT JOIN booking b ON b.activity_id = a.id
    AND b.cancellation_reason IS NULL
LEFT JOIN scout_group sg ON sg.id = b.booker_group_id
WHERE a.recurring_activity_kind = $1
    AND NOT EXISTS (
        SELECT 1 FROM call_off c WHERE c.activity_id = a.id
    )
    AND a.start_time >= $2
    AND a.start_time < $3
GROUP BY a.id, a.start_time, a.end_time, a.max_attendees,
    b.booker_group_id, sg.name
ORDER BY a.start_time ASC, a.id, booker_group_name ASC;

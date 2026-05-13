INSERT INTO favourite (id, user_id, activity_id)
VALUES ($1, $2, $3) ON CONFLICT (user_id, activity_id) DO NOTHING
RETURNING id,
    user_id,
    activity_id

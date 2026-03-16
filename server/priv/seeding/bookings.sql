-- Seed users first (bookings require a valid user_id)
INSERT INTO "user" (id, role)
VALUES ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'booker'),
    ('b2c3d4e5-f6a7-8901-bcde-f12345678901', 'booker'),
    ('c3d4e5f6-a7b8-9012-cdef-123456789012', 'organizer')
ON CONFLICT (id) DO NOTHING;

-- Seed bookings (references activities from activities.sql)
INSERT INTO booking (
        id,
        user_id,
        activity_id,
        booker_group_id,
        booker_group_name,
        group_free_text,
        responsible_name,
        phone_number,
        participant_count
    )
VALUES (
        '11111111-1111-1111-1111-111111111111',
        'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
        '6f5e1d46-5f58-4e23-9a9d-8c2bfc2d22a0',
        101,
        'Sjöscoutkåren Dansen',
        'Patrull Örnarna',
        'Anna Svensson',
        '+46701234567',
        12
    ),
    (
        '22222222-2222-2222-2222-222222222222',
        'b2c3d4e5-f6a7-8901-bcde-f12345678901',
        '6f5e1d46-5f58-4e23-9a9d-8c2bfc2d22a0',
        202,
        'Scoutkåren Vansen',
        'Patrull Falkarna',
        'Erik Johansson',
        '+46709876543',
        8
    ),
    (
        '33333333-3333-3333-3333-333333333333',
        'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
        'b4219a53-4746-4a09-8b4e-3e2ac0c3df11',
        101,
        'Sjöscoutkåren Dansen',
        'Patrull Örnarna',
        'Anna Svensson',
        '+46701234567',
        10
    ),
    (
        '44444444-4444-4444-4444-444444444444',
        'b2c3d4e5-f6a7-8901-bcde-f12345678901',
        'fa3825ab-8bc1-4f59-9100-2cc6aeb3d219',
        202,
        'Scoutkåren Vansen',
        'Patrull Hökarna',
        'Maria Lindström',
        '+46701122334',
        15
    ),
    (
        '55555555-5555-5555-5555-555555555555',
        'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
        'd923f1ae-8f8e-45f2-8e7d-89e7d7b4cb75',
        101,
        'Sjöscoutkåren Dansen',
        'Hela kåren',
        'Anna Svensson',
        '+46701234567',
        20
    );

-- Seed activity_user (organizer assignments)
INSERT INTO activity_user (activity_id, user_id)
VALUES ('6f5e1d46-5f58-4e23-9a9d-8c2bfc2d22a0', 'c3d4e5f6-a7b8-9012-cdef-123456789012'),
    ('b4219a53-4746-4a09-8b4e-3e2ac0c3df11', 'c3d4e5f6-a7b8-9012-cdef-123456789012'),
    ('fa3825ab-8bc1-4f59-9100-2cc6aeb3d219', 'c3d4e5f6-a7b8-9012-cdef-123456789012')
ON CONFLICT (activity_id, user_id) DO NOTHING;

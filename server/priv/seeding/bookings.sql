-- Seed users first (bookings require a valid user_id)
INSERT INTO "user" (id)
VALUES ('a1b2c3d4-e5f6-4a90-abcd-ef1234567890'),
    ('b2c3d4e5-f6a7-4b01-bcde-f12345678901'),
    ('c3d4e5f6-a7b8-4c12-8def-123456789012')
ON CONFLICT (id) DO NOTHING;

-- Seed bookings (references activities from activities.sql)
INSERT INTO booking (
        id,
        user_id,
        activity_id,
        booker_name,
        booker_group_id,
        booker_group_name,
        group_free_text,
        responsible_name,
        phone_number,
        participant_count
    )
VALUES (
        'dd000001-0000-4000-8000-000000000001',
        'a1b2c3d4-e5f6-4a90-abcd-ef1234567890',
        '6f5e1d46-5f58-4e23-9a9d-8c2bfc2d22a0',
        'Anna Svensson',
        101,
        'Sjöscoutkåren Dansen',
        'Patrull Örnarna',
        'Anna Svensson',
        '+46701234567',
        12
    ),
    (
        'dd000002-0000-4000-8000-000000000002',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        '6f5e1d46-5f58-4e23-9a9d-8c2bfc2d22a0',
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Patrull Falkarna',
        'Erik Johansson',
        '+46709876543',
        8
    ),
    (
        'dd000003-0000-4000-8000-000000000003',
        'a1b2c3d4-e5f6-4a90-abcd-ef1234567890',
        'b4219a53-4746-4a09-8b4e-3e2ac0c3df11',
        'Anna Svensson',
        101,
        'Sjöscoutkåren Dansen',
        'Patrull Örnarna',
        'Anna Svensson',
        '+46701234567',
        10
    ),
    (
        'dd000004-0000-4000-8000-000000000004',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        'fa3825ab-8bc1-4f59-9100-2cc6aeb3d219',
        'Maria Lindström',
        202,
        'Scoutkåren Vansen',
        'Patrull Hökarna',
        'Maria Lindström',
        '+46701122334',
        15
    ),
    (
        'dd000005-0000-4000-8000-000000000005',
        'a1b2c3d4-e5f6-4a90-abcd-ef1234567890',
        'd923f1ae-8f8e-45f2-8e7d-89e7d7b4cb75',
        'Anna Svensson',
        101,
        'Sjöscoutkåren Dansen',
        'Hela kåren',
        'Anna Svensson',
        '+46701234567',
        20
    );

-- On-behalf bookings (booked_for_other): made by info-tent staff for another
-- kår. Owned by a different user than the dev fallback user, so the
-- team-managed edit rule (any bookings:others:create holder may manage them)
-- can be exercised against "someone else's" rows locally.
INSERT INTO booking (
        id,
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
    )
VALUES (
        'dd000006-0000-4000-8000-000000000006',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        '6f5e1d46-5f58-4e23-9a9d-8c2bfc2d22a0',
        'Erik Johansson',
        1102,
        'Adolf Fredriks Scoutkår',
        'Patrull Ugglan',
        'Karin Berg',
        '+46705556677',
        6,
        TRUE
    ),
    (
        'dd000007-0000-4000-8000-000000000007',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        'b4219a53-4746-4a09-8b4e-3e2ac0c3df11',
        'Erik Johansson',
        1124,
        'Scoutkåren Vikingarna',
        'Patrull Björnen',
        'Lars Ek',
        '+46704445566',
        4,
        TRUE
    );

-- Seed activity_user (organizer assignments)
INSERT INTO activity_user (activity_id, user_id)
VALUES ('6f5e1d46-5f58-4e23-9a9d-8c2bfc2d22a0', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('b4219a53-4746-4a09-8b4e-3e2ac0c3df11', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('fa3825ab-8bc1-4f59-9100-2cc6aeb3d219', 'c3d4e5f6-a7b8-4c12-8def-123456789012')
ON CONFLICT (activity_id, user_id) DO NOTHING;

-- Booking implies favourite. Seed favourites for every seeded booking so that
-- the heart and "Booked!" state stay consistent. Idempotent via the unique
-- constraint on (user_id, activity_id).
INSERT INTO favourite (id, user_id, activity_id)
SELECT gen_random_uuid(),
    user_id,
    activity_id
FROM booking ON CONFLICT (user_id, activity_id) DO NOTHING;

-- ============================================================================
-- Extra volume for the programme imported from the xlsx: more seed users,
-- bookings spread over the week, organizers and favourites.
-- ============================================================================
-- More seed users so bookings spread over several bookers
INSERT INTO "user" (id)
VALUES ('d4e5f6a7-b8c9-4d23-9ef0-234567890123'),
    ('e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('f6a7b8c9-d0e1-4f45-b012-456789012345')
ON CONFLICT (id) DO NOTHING;

-- Shared dev test accounts from j26-auth (JIT-provisioned on real logins):
-- Markus Test Planeringsfunktionär, Markus Test Funktionär and Markus Test
-- Ledare (Kår 1386). Seeding them lets their bookings below attach to the
-- accounts used when logging in locally.
INSERT INTO "user" (id)
VALUES ('006e3fdd-dc54-43a0-9a2a-4232335c07bc'),
    ('2c378f10-bbf5-4a32-b8f4-050dd552a447'),
    ('3ae85c94-5d76-4d43-ab18-a3521d9ed479')
ON CONFLICT (id) DO NOTHING;

-- Bookings on the imported programme (capacity-aware; some activities are
-- booked exactly full).
INSERT INTO booking (
        id,
        user_id,
        activity_id,
        booker_name,
        booker_group_id,
        booker_group_name,
        group_free_text,
        responsible_name,
        phone_number,
        participant_count
    )
VALUES
    (
        '1a957bec-fc73-5d3c-8b3d-0a4106e3f1f4',
        'a1b2c3d4-e5f6-4a90-abcd-ef1234567890',
        'a6b93ca9-1418-5ac3-b668-6429c1023514', -- Quiz: Musikquiz, det som varit och det som är 2026-07-25
        'Anna Svensson',
        101,
        'Sjöscoutkåren Dansen',
        'Patrull Räven',
        'Anna Svensson',
        '+46701234567',
        3
    ),
    (
        'bdcb607e-d4cb-5e71-8812-c25f679709a0',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        'b208a2a7-08dd-58c5-bd88-3084dbeb9436', -- Arrivo 2026-07-25
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Patrull Vargen',
        'Erik Johansson',
        '+46709876543',
        10
    ),
    (
        '0fcf026d-aa66-506b-b3a5-46724399cc3e',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        'b208a2a7-08dd-58c5-bd88-3084dbeb9436', -- Arrivo 2026-07-25
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Patrull Lodjuret',
        'Sara Öberg',
        '+46706667788',
        5
    ),
    (
        'aa4fc4b6-6d25-5e73-ab10-da57c1bdd57f',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        'e5d2c766-cc40-5a2f-8488-f05fc8820572', -- Godnattsaga 2026-07-25
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Lodjuret',
        'Petra Vikström',
        '+46702223344',
        7
    ),
    (
        '0f01564a-894e-505e-9a97-1b8820d87959',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        'e5d2c766-cc40-5a2f-8488-f05fc8820572', -- Godnattsaga 2026-07-25
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Bävern',
        'Lena Holm',
        '+46708889900',
        12
    ),
    (
        '4ea44fc7-0b0e-5810-9e1f-f2ccf7b40a6d',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        'e5d2c766-cc40-5a2f-8488-f05fc8820572', -- Godnattsaga 2026-07-25
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Ugglan',
        'Markus Test Ledare',
        '+46700000003',
        7
    ),
    (
        '4506fa87-bc92-5379-a231-f1264161ba13',
        'd4e5f6a7-b8c9-4d23-9ef0-234567890123',
        '37c3e713-0561-55fd-9900-4bc20f8899e5', -- Öppet hus - Känn Pulsen 2026-07-25
        'Johan Nilsson',
        303,
        'Scoutkåren Norrsken',
        'Patrull Bävern',
        'Johan Nilsson',
        '+46703334455',
        4
    ),
    (
        'b3295973-bb94-50d1-908a-5f51333b9319',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        'a5cd670d-4c43-5400-8f5f-bf4da7113ac8', -- Speed date - vad vill du förändra i samhället? 2026-07-25
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Hela avdelningen',
        'Markus Test Funktionär',
        '+46700000002',
        6
    ),
    (
        'cad5faf9-3c0e-5da3-bfcd-32c5f23707ec',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        'd6394f2b-7a4b-53ac-9287-aef7f65359aa', -- Deeptalk: Nya ideal, gamla mönster - vad händer med jämställdheten 2026? 2026-07-25
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Hela avdelningen',
        'Lena Holm',
        '+46708889900',
        8
    ),
    (
        '2b146763-e5c3-5ae5-ac6c-a0693a05c162',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        'd6394f2b-7a4b-53ac-9287-aef7f65359aa', -- Deeptalk: Nya ideal, gamla mönster - vad händer med jämställdheten 2026? 2026-07-25
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Räven',
        'Markus Test Ledare',
        '+46700000003',
        3
    ),
    (
        '65978dd8-75c0-5979-8fa6-47adab158c91',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        'd6394f2b-7a4b-53ac-9287-aef7f65359aa', -- Deeptalk: Nya ideal, gamla mönster - vad händer med jämställdheten 2026? 2026-07-25
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Vargen',
        'Petra Vikström',
        '+46702223344',
        8
    ),
    (
        '428edccd-6fe1-5995-9e74-b2783dc54841',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        'ce006bf2-571c-5af3-acb1-9b09812bfe7d', -- Kåsan 2026-07-25
        'Markus Test Planeringsfunktionär',
        NULL,
        NULL,
        'Patrull Räven',
        'Markus Test Planeringsfunktionär',
        '+46700000001',
        5
    ),
    (
        '8fd6cdef-8bfb-5259-80b0-059a0d4d882d',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        'c1addd1a-13ff-5c26-b804-be51a43dd6e1', -- Känslokartan 2026-07-25
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Patrull Vargen',
        'Markus Test Funktionär',
        '+46700000002',
        12
    ),
    (
        '17f39795-dde9-5bfd-b1d9-0d3199ea12b2',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        'c1addd1a-13ff-5c26-b804-be51a43dd6e1', -- Känslokartan 2026-07-25
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Patrull Lodjuret',
        'Erik Johansson',
        '+46709876543',
        7
    ),
    (
        '587616cf-2965-5890-80fb-79c8b42d41ec',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        'b2bac4bb-2eac-5205-9326-f21c7701cae2', -- Brädspel 2026-07-25
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Bävern',
        'Petra Vikström',
        '+46702223344',
        4
    ),
    (
        '95b476d2-d89e-525d-8ff5-6dfceb3c9f70',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        'b2bac4bb-2eac-5205-9326-f21c7701cae2', -- Brädspel 2026-07-25
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Ugglan',
        'Lena Holm',
        '+46708889900',
        9
    ),
    (
        'be540d38-0246-54c1-baa7-ef3708ade535',
        'a1b2c3d4-e5f6-4a90-abcd-ef1234567890',
        'f81290e7-83ef-5704-96e7-c312916f3658', -- Lekaktiviteter 2026-07-25
        'Anna Svensson',
        101,
        'Sjöscoutkåren Dansen',
        'Patrull Bävern',
        'Anna Svensson',
        '+46701234567',
        6
    ),
    (
        'b6e82a58-f6c5-5c1c-8e7d-11cf89309c51',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        '678980c6-bcec-54df-868d-dee8cb79c7f8', -- Bubbelballs 2026-07-25
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Patrull Ugglan',
        'Erik Johansson',
        '+46709876543',
        3
    ),
    (
        '6439db68-3618-5fc2-8fba-8c654ed00ee4',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        '678980c6-bcec-54df-868d-dee8cb79c7f8', -- Bubbelballs 2026-07-25
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Hela avdelningen',
        'Sara Öberg',
        '+46706667788',
        8
    ),
    (
        '6c5a6b85-7041-5234-8b91-978b922b6561',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '1b0ad30f-07f7-599f-b0ed-f52358c885e2', -- Cybersäkerhet med Unga forskare 2026-07-25
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Hela avdelningen',
        'Petra Vikström',
        '+46702223344',
        10
    ),
    (
        'f18d78c8-121d-52ec-a8b2-b4cde23165fb',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        '1b0ad30f-07f7-599f-b0ed-f52358c885e2', -- Cybersäkerhet med Unga forskare 2026-07-25
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Räven',
        'Lena Holm',
        '+46708889900',
        5
    ),
    (
        'd2206e38-86b7-527b-8815-28049aa6b061',
        'd4e5f6a7-b8c9-4d23-9ef0-234567890123',
        'd28215c6-a981-5223-a703-3d7156437d79', -- Halmpool 2026-07-25
        'Johan Nilsson',
        303,
        'Scoutkåren Norrsken',
        'Patrull Räven',
        'Johan Nilsson',
        '+46703334455',
        7
    ),
    (
        'f51a8330-c0c4-5cdc-9c39-e5ef621ec966',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        '4f3dd97a-571d-515c-8e73-f7a0ca192da9', -- Slankaruseller 2026-07-25
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Patrull Vargen',
        'Sara Öberg',
        '+46706667788',
        4
    ),
    (
        '23ce1c5a-cb44-5b81-8f60-662647742c9f',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        '4f3dd97a-571d-515c-8e73-f7a0ca192da9', -- Slankaruseller 2026-07-25
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Patrull Lodjuret',
        'Markus Test Funktionär',
        '+46700000002',
        9
    ),
    (
        '46542a87-0113-5707-bd5a-b1fc0a461ca2',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        'f123cd57-0cd6-5e71-8993-fe631c0ae9e3', -- Knoprep 2026-07-25
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Lodjuret',
        'Lena Holm',
        '+46708889900',
        11
    ),
    (
        'e0e4dc6d-5378-55b8-a3a5-1c71367bbabd',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        'f123cd57-0cd6-5e71-8993-fe631c0ae9e3', -- Knoprep 2026-07-25
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Bävern',
        'Markus Test Ledare',
        '+46700000003',
        6
    ),
    (
        'e3dba8ea-d456-5282-9cd4-6c92930e5d9a',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        'f123cd57-0cd6-5e71-8993-fe631c0ae9e3', -- Knoprep 2026-07-25
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Ugglan',
        'Petra Vikström',
        '+46702223344',
        11
    ),
    (
        'e96aa084-5728-595e-8253-56f24a53f629',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '2c9884a6-d823-5905-b717-d54d9ae3bd6e', -- Tillsammans målning 2026-07-25
        'Markus Test Planeringsfunktionär',
        NULL,
        NULL,
        'Patrull Bävern',
        'Markus Test Planeringsfunktionär',
        '+46700000001',
        8
    ),
    (
        '4d8ad6ff-837b-5c64-be2d-27c56d5a7bfc',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        '49f455f9-9b5c-5bc2-8db3-b80189e30a26', -- Våga lyssna fördjupning 2026-07-26
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Hela avdelningen',
        'Erik Johansson',
        '+46709876543',
        10
    ),
    (
        '3db81059-e005-5b88-9e5c-1e8e014ba8d1',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        '0c73e5da-a930-528b-9b49-95a22f35655c', -- Påverka på riktigt: när de vanliga vägarna inte räcker 2026-07-26
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Hela avdelningen',
        'Markus Test Ledare',
        '+46700000003',
        12
    ),
    (
        '93e31fef-8aec-54fd-9951-8fb4fbc0920b',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '0c73e5da-a930-528b-9b49-95a22f35655c', -- Påverka på riktigt: när de vanliga vägarna inte räcker 2026-07-26
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Räven',
        'Petra Vikström',
        '+46702223344',
        7
    ),
    (
        '63551b5a-1adf-5e20-b968-41bd278f0098',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        '0c73e5da-a930-528b-9b49-95a22f35655c', -- Påverka på riktigt: när de vanliga vägarna inte räcker 2026-07-26
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Vargen',
        'Lena Holm',
        '+46708889900',
        12
    ),
    (
        '17894496-8bbf-51eb-a7b0-4e4e656b0a80',
        'a1b2c3d4-e5f6-4a90-abcd-ef1234567890',
        '86f8c015-5b80-584c-b685-f5a9dfaa9a20', -- Quiz 2026-07-26
        'Anna Svensson',
        101,
        'Sjöscoutkåren Dansen',
        'Patrull Räven',
        'Anna Svensson',
        '+46701234567',
        9
    ),
    (
        'a04098a1-cbe5-5c24-a563-702d0fac8106',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        '9abfb6d5-fa00-5280-8715-fb53fa0c6c1f', -- Hinderbanerace upptäckare 2026-07-26
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Patrull Vargen',
        'Erik Johansson',
        '+46709876543',
        6
    ),
    (
        '88386268-92b0-5f9a-8e1d-beeeab103efa',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        '9abfb6d5-fa00-5280-8715-fb53fa0c6c1f', -- Hinderbanerace upptäckare 2026-07-26
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Patrull Lodjuret',
        'Sara Öberg',
        '+46706667788',
        11
    ),
    (
        '8242a277-123a-566d-b42a-edc5e1eb53c5',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        'fd6b5c43-abd1-54da-8012-c4eba92dea0b', -- Upptäckarsamtal 2026-07-26
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Bävern',
        'Lena Holm',
        '+46708889900',
        8
    ),
    (
        '4bc8e6c4-42e2-5136-9e13-6e9f2c1bc543',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        'fd6b5c43-abd1-54da-8012-c4eba92dea0b', -- Upptäckarsamtal 2026-07-26
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Ugglan',
        'Markus Test Ledare',
        '+46700000003',
        3
    ),
    (
        'fea0de28-4558-540f-9b99-245ee643b7b4',
        'd4e5f6a7-b8c9-4d23-9ef0-234567890123',
        '73ca9e93-b4e0-5bf2-80c8-5b6448b9bb3f', -- Äventyrararsamtal 2026-07-26
        'Johan Nilsson',
        303,
        'Scoutkåren Norrsken',
        'Patrull Bävern',
        'Johan Nilsson',
        '+46703334455',
        10
    ),
    (
        '89de466e-b59d-5848-8da0-f04e2c905175',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        '481c9c0a-07c9-5a8b-a45b-d5622bfe5c09', -- Leda Scouting - Spork del 1 2026-07-26
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Patrull Ugglan',
        'Sara Öberg',
        '+46706667788',
        24
    ),
    (
        '549558d6-90a1-5077-9f1b-35418f116241',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        'afa104af-7392-57ba-b646-75279a3b5d77', -- Leda Scouting - Tamoj del 1 2026-07-26
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Hela avdelningen',
        'Lena Holm',
        '+46708889900',
        4
    ),
    (
        '609b2eaf-6f4f-5065-b676-6cbcc2923d99',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        'afa104af-7392-57ba-b646-75279a3b5d77', -- Leda Scouting - Tamoj del 1 2026-07-26
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Räven',
        'Markus Test Ledare',
        '+46700000003',
        9
    ),
    (
        '7c79b4e7-a0a3-55eb-b54a-9248781dbccc',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '078a02ed-a35c-5d31-9381-6bd61542ec9b', -- Klubb BANGERS 2026-07-26
        'Markus Test Planeringsfunktionär',
        NULL,
        NULL,
        'Patrull Räven',
        'Markus Test Planeringsfunktionär',
        '+46700000001',
        11
    ),
    (
        '6b700f1a-a290-5e2a-81f2-5f30cc2122bf',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        '09f413be-effc-51c9-93b9-edefb32ab4c3', -- Karaoke! 2026-07-26
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Patrull Vargen',
        'Markus Test Funktionär',
        '+46700000002',
        8
    ),
    (
        '3edd47be-a53d-5f13-8d94-5be121b31f19',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        '09f413be-effc-51c9-93b9-edefb32ab4c3', -- Karaoke! 2026-07-26
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Patrull Lodjuret',
        'Erik Johansson',
        '+46709876543',
        3
    ),
    (
        '538e1cba-2469-56c7-bcfa-328cb1468620',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        '82dcf744-eed3-5e77-acda-c48b509fd9e2', -- Masterclass i knoplära 2026-07-26
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Lodjuret',
        'Markus Test Ledare',
        '+46700000003',
        5
    ),
    (
        'ae5b199e-b935-56b9-ae58-b90772db37ae',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '82dcf744-eed3-5e77-acda-c48b509fd9e2', -- Masterclass i knoplära 2026-07-26
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Bävern',
        'Petra Vikström',
        '+46702223344',
        10
    ),
    (
        'cd36f992-54fc-53c0-b98e-3bf2674cbbf8',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        '82dcf744-eed3-5e77-acda-c48b509fd9e2', -- Masterclass i knoplära 2026-07-26
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Ugglan',
        'Lena Holm',
        '+46708889900',
        5
    ),
    (
        '920123e2-e797-516b-9702-e6888ee5c76c',
        'a1b2c3d4-e5f6-4a90-abcd-ef1234567890',
        '126a1410-5896-5224-833c-28b5b9a0fd38', -- Sagostund 2026-07-26
        'Anna Svensson',
        101,
        'Sjöscoutkåren Dansen',
        'Patrull Bävern',
        'Anna Svensson',
        '+46701234567',
        12
    ),
    (
        'e23e53fd-5b09-5572-b831-db8cfa993bfd',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        'c97167ff-5519-5965-a8dc-3113c9f52289', -- Kvällsbön 2026-07-26
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Hela avdelningen',
        'Sara Öberg',
        '+46706667788',
        4
    ),
    (
        'd074b536-619f-55db-874e-1ec315927a9d',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '7986095f-e2ca-515a-b331-42eecc9a6daf', -- 26/7 – Påsk 🐣 2026-07-26
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Hela avdelningen',
        'Petra Vikström',
        '+46702223344',
        6
    ),
    (
        'dbcb77b9-b48c-551b-87c1-05f96584ad27',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        '7986095f-e2ca-515a-b331-42eecc9a6daf', -- 26/7 – Påsk 🐣 2026-07-26
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Räven',
        'Lena Holm',
        '+46708889900',
        11
    ),
    (
        'f155bbc7-a658-547d-949c-2366c4c9deac',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        '7986095f-e2ca-515a-b331-42eecc9a6daf', -- 26/7 – Påsk 🐣 2026-07-26
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Vargen',
        'Markus Test Ledare',
        '+46700000003',
        6
    ),
    (
        '583d0077-4b34-5b72-82ff-26f5c2c71ada',
        'd4e5f6a7-b8c9-4d23-9ef0-234567890123',
        '58969b83-d19a-5feb-aa0a-ab79ed50dd95', -- Dagens lek 2026-07-26
        'Johan Nilsson',
        303,
        'Scoutkåren Norrsken',
        'Patrull Räven',
        'Johan Nilsson',
        '+46703334455',
        3
    ),
    (
        '09764aa9-2646-5475-8a24-1d08fcd8a345',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        '5086036b-0cfc-5c68-8806-3fbd222e70f6', -- Speed friendning 2026-07-26
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Patrull Vargen',
        'Sara Öberg',
        '+46706667788',
        10
    ),
    (
        '80aed447-0a6f-57a4-bf2d-22fd85e0a88e',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        '5086036b-0cfc-5c68-8806-3fbd222e70f6', -- Speed friendning 2026-07-26
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Patrull Lodjuret',
        'Markus Test Funktionär',
        '+46700000002',
        5
    ),
    (
        '7a786cf8-cbd0-5253-a45f-d0c39ea2fb2a',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        '55a02dd6-aa42-57ba-b881-40f6f6187613', -- Speed friendning 2026-07-26
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Bävern',
        'Markus Test Ledare',
        '+46700000003',
        12
    ),
    (
        'd03fd276-215c-5bf6-a511-ffde4386a996',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '55a02dd6-aa42-57ba-b881-40f6f6187613', -- Speed friendning 2026-07-26
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Ugglan',
        'Petra Vikström',
        '+46702223344',
        7
    ),
    (
        'f5569df4-a87b-57bf-b450-fd84ccd085b9',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '5f85b46c-f9b2-50e8-b8fb-04b42d02d27b', -- Speed friendning 2026-07-26
        'Markus Test Planeringsfunktionär',
        NULL,
        NULL,
        'Patrull Bävern',
        'Markus Test Planeringsfunktionär',
        '+46700000001',
        4
    ),
    (
        'd62a7c1e-9f84-560c-8c5a-c70fa2b906d6',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        'a6c40518-a47f-5846-8fbe-9deca32f61a7', -- Speed friendning 2026-07-26
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Patrull Ugglan',
        'Markus Test Funktionär',
        '+46700000002',
        11
    ),
    (
        '44f73423-4485-5a29-a926-7f68e607bac4',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        'a6c40518-a47f-5846-8fbe-9deca32f61a7', -- Speed friendning 2026-07-26
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Hela avdelningen',
        'Erik Johansson',
        '+46709876543',
        6
    ),
    (
        'd741c6c7-bce0-5ff0-af37-bf9ecd10b5da',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        'a8ada774-7cc9-5c31-8ce4-f5b97367d89b', -- Lekaktiviteter 2026-07-26
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Hela avdelningen',
        'Markus Test Ledare',
        '+46700000003',
        8
    ),
    (
        'c30e84f9-2bc8-593e-a6c1-968edd969cef',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        'a8ada774-7cc9-5c31-8ce4-f5b97367d89b', -- Lekaktiviteter 2026-07-26
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Räven',
        'Petra Vikström',
        '+46702223344',
        3
    ),
    (
        '33fbe496-c305-507e-b3aa-2f0ec3b3e36c',
        'a1b2c3d4-e5f6-4a90-abcd-ef1234567890',
        'b518a741-3087-5e95-87ce-92a7576252eb', -- Bubbelballs 2026-07-26
        'Anna Svensson',
        101,
        'Sjöscoutkåren Dansen',
        'Patrull Räven',
        'Anna Svensson',
        '+46701234567',
        5
    ),
    (
        'd9e0fdec-c9d8-5b72-b067-61c59f79b7e8',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        'a82c89e0-c1a7-5dd4-94ea-4822a33d8c1e', -- Kåsan 2026-07-26
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Patrull Vargen',
        'Erik Johansson',
        '+46709876543',
        12
    ),
    (
        'cff5e6c3-f70f-5ae6-bd35-e9a2577b0221',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        'a82c89e0-c1a7-5dd4-94ea-4822a33d8c1e', -- Kåsan 2026-07-26
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Patrull Lodjuret',
        'Sara Öberg',
        '+46706667788',
        7
    ),
    (
        '065a4f15-01db-5da8-a0a1-7eb0a917570c',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '71e5768c-7fb5-5bbf-9fdb-c68c208a443c', -- Känslokartan 2026-07-26
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Lodjuret',
        'Petra Vikström',
        '+46702223344',
        9
    ),
    (
        '1c50b023-b984-5f94-b095-d97f81ac4801',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        '71e5768c-7fb5-5bbf-9fdb-c68c208a443c', -- Känslokartan 2026-07-26
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Bävern',
        'Lena Holm',
        '+46708889900',
        4
    ),
    (
        '1f7eeb3e-0a59-5d26-be3b-f314a7b75477',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        '71e5768c-7fb5-5bbf-9fdb-c68c208a443c', -- Känslokartan 2026-07-26
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Ugglan',
        'Markus Test Ledare',
        '+46700000003',
        9
    ),
    (
        'a8964585-463c-530e-8b0c-86ec19c6d9ff',
        'd4e5f6a7-b8c9-4d23-9ef0-234567890123',
        '713733d3-32d9-5ea1-833b-3886d0c554ec', -- Brädspel 2026-07-26
        'Johan Nilsson',
        303,
        'Scoutkåren Norrsken',
        'Patrull Bävern',
        'Johan Nilsson',
        '+46703334455',
        6
    ),
    (
        '0aa4e0bc-acab-5025-9321-3888e101f3c0',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        'f0640f56-7792-5307-ba6d-6cec88b13c70', -- Cybersäkerhet med Unga forskare 2026-07-26
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Hela avdelningen',
        'Markus Test Funktionär',
        '+46700000002',
        8
    ),
    (
        '3ed4e386-f43b-59fc-b4f2-95caee6fd645',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        '37764be9-d7ba-58c8-b2f9-21497bd0a997', -- Hantverksfokus: Läder 2026-07-26
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Hela avdelningen',
        'Lena Holm',
        '+46708889900',
        10
    ),
    (
        'cabb37da-30e3-5bec-8df5-d00ee94569bf',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        '37764be9-d7ba-58c8-b2f9-21497bd0a997', -- Hantverksfokus: Läder 2026-07-26
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Räven',
        'Markus Test Ledare',
        '+46700000003',
        5
    ),
    (
        'db072654-a92d-517f-991d-e68f4d6a5735',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '37764be9-d7ba-58c8-b2f9-21497bd0a997', -- Hantverksfokus: Läder 2026-07-26
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Vargen',
        'Petra Vikström',
        '+46702223344',
        10
    ),
    (
        '4b3f0079-6378-5666-b7ef-a5f730e8410b',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '9ddf4439-267d-5f4c-9b9e-1ef7c400800d', -- Knoprep 2026-07-26
        'Markus Test Planeringsfunktionär',
        NULL,
        NULL,
        'Patrull Räven',
        'Markus Test Planeringsfunktionär',
        '+46700000001',
        7
    ),
    (
        '450bf888-b736-5e81-ac1f-746a4c48e6b2',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        '94ba81dd-0877-5b6a-a074-4c0739ce6d19', -- Tillsammans målning 2026-07-26
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Patrull Vargen',
        'Markus Test Funktionär',
        '+46700000002',
        4
    ),
    (
        '35d859e1-d8f7-5e7a-bcb1-2ff282d82ebb',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        '94ba81dd-0877-5b6a-a074-4c0739ce6d19', -- Tillsammans målning 2026-07-26
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Patrull Lodjuret',
        'Erik Johansson',
        '+46709876543',
        9
    ),
    (
        '6c82ceed-0c6d-51ca-be14-276925de4aae',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '7a7c0e31-d225-57a6-b418-d3c0a7c045c7', -- Halmpool 2026-07-26
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Bävern',
        'Petra Vikström',
        '+46702223344',
        6
    ),
    (
        'ab099799-281e-5c2b-9fd5-2c69521311cf',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        '7a7c0e31-d225-57a6-b418-d3c0a7c045c7', -- Halmpool 2026-07-26
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Ugglan',
        'Lena Holm',
        '+46708889900',
        11
    ),
    (
        'ae2c6301-acf2-5763-a1f5-a9d55db22fcd',
        'a1b2c3d4-e5f6-4a90-abcd-ef1234567890',
        'f00f9619-668b-5af6-8b49-08b5247c50fe', -- Slankaruseller 2026-07-26
        'Anna Svensson',
        101,
        'Sjöscoutkåren Dansen',
        'Patrull Bävern',
        'Anna Svensson',
        '+46701234567',
        8
    ),
    (
        'cfa8cbe2-0a54-50a0-96de-2daf2a5c22f2',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        'ee79360a-a81d-5f70-a42e-64f1ed0310cf', -- Psykologisk beredskap 2026-07-26
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Patrull Ugglan',
        'Erik Johansson',
        '+46709876543',
        5
    ),
    (
        '63e4946d-9a16-579a-868e-c96042ccc2ae',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        'ee79360a-a81d-5f70-a42e-64f1ed0310cf', -- Psykologisk beredskap 2026-07-26
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Hela avdelningen',
        'Sara Öberg',
        '+46706667788',
        10
    ),
    (
        'a606b716-9375-536e-a34e-646e9f88fc1e',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        'e7e035d4-ad8b-55da-a308-532d5a9bbafb', -- Psykologisk beredskap 2026-07-26
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Hela avdelningen',
        'Petra Vikström',
        '+46702223344',
        12
    ),
    (
        'b9150f28-8565-55c6-af29-6553a34979bf',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        'e7e035d4-ad8b-55da-a308-532d5a9bbafb', -- Psykologisk beredskap 2026-07-26
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Räven',
        'Lena Holm',
        '+46708889900',
        7
    ),
    (
        'f8f5e401-9f96-5257-b78f-56c3d4e2e79d',
        'd4e5f6a7-b8c9-4d23-9ef0-234567890123',
        'a25e5238-61a2-5523-95b3-2aea9004e56c', -- Mekanisk tjur 2026-07-26
        'Johan Nilsson',
        303,
        'Scoutkåren Norrsken',
        'Patrull Räven',
        'Johan Nilsson',
        '+46703334455',
        9
    ),
    (
        'ad6b9728-9eac-5434-8fb7-152409930510',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        '4bc7bc39-ae07-537a-909d-916a292f7da9', -- Unga forskare 2026-07-26
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Patrull Vargen',
        'Sara Öberg',
        '+46706667788',
        6
    ),
    (
        'b57aa1a3-353e-5308-af90-1a7e75ac9a1a',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        '4bc7bc39-ae07-537a-909d-916a292f7da9', -- Unga forskare 2026-07-26
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Patrull Lodjuret',
        'Markus Test Funktionär',
        '+46700000002',
        11
    ),
    (
        'd995476f-49b7-5294-8fb0-cd8ca82d1181',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        '94e0e7e2-dab6-5457-8ab5-5fe45151ecb0', -- Speedfriending 2026-07-26
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Lodjuret',
        'Lena Holm',
        '+46708889900',
        3
    ),
    (
        'e8eaff90-e01f-547a-9874-48f4c70672e7',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        '94e0e7e2-dab6-5457-8ab5-5fe45151ecb0', -- Speedfriending 2026-07-26
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Bävern',
        'Markus Test Ledare',
        '+46700000003',
        8
    ),
    (
        '9a0a553f-1c1d-53a5-8acb-4ec4b67d123a',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '94e0e7e2-dab6-5457-8ab5-5fe45151ecb0', -- Speedfriending 2026-07-26
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Ugglan',
        'Petra Vikström',
        '+46702223344',
        3
    ),
    (
        'e05453cb-3f8f-5fc2-ace5-b3e2a2071a2b',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '8839a2d8-5ded-531d-866e-a15a7c66f66e', -- Lokal trubadur 2026-07-26
        'Markus Test Planeringsfunktionär',
        NULL,
        NULL,
        'Patrull Bävern',
        'Markus Test Planeringsfunktionär',
        '+46700000001',
        10
    ),
    (
        '13f80713-e39e-5eb5-a92c-9e4456952992',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        'cef3019f-0305-56a0-8b32-d930994ef82f', -- Lokal trubadur 2026-07-26
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Hela avdelningen',
        'Erik Johansson',
        '+46709876543',
        12
    ),
    (
        'a49b21e1-e1ae-520a-a97f-a326d41eb19f',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        '76bbce09-a748-51b2-9bdc-abd08d3865f5', -- Trygga möten fördjupning 2026-07-27
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Hela avdelningen',
        'Markus Test Ledare',
        '+46700000003',
        4
    ),
    (
        '2252d29d-2bd6-59db-ab40-0997f4d67759',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '76bbce09-a748-51b2-9bdc-abd08d3865f5', -- Trygga möten fördjupning 2026-07-27
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Räven',
        'Petra Vikström',
        '+46702223344',
        9
    ),
    (
        '86b348cf-fb65-5176-b5ea-b7f028af0f28',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        '76bbce09-a748-51b2-9bdc-abd08d3865f5', -- Trygga möten fördjupning 2026-07-27
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Vargen',
        'Lena Holm',
        '+46708889900',
        4
    ),
    (
        'a84dd1b1-fa53-537a-a4ab-29fe68e23966',
        'a1b2c3d4-e5f6-4a90-abcd-ef1234567890',
        'fe69870d-9e76-5b79-bdf9-3dee3b81a968', -- Mind: Delaktighet som friskfaktor 2026-07-27
        'Anna Svensson',
        101,
        'Sjöscoutkåren Dansen',
        'Patrull Räven',
        'Anna Svensson',
        '+46701234567',
        11
    ),
    (
        '4b589759-c6b0-54f2-ab0b-22806e4f0fa6',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        'f3b00d8d-268d-5aaf-93c7-4167fda6d4a0', -- Treskablinoll: Trygga scouter - nytt material med fokus på integritet 2026-07-27
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Patrull Vargen',
        'Erik Johansson',
        '+46709876543',
        8
    ),
    (
        '8c2ba382-7beb-55b0-909d-ff2faf23c8dc',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        'f3b00d8d-268d-5aaf-93c7-4167fda6d4a0', -- Treskablinoll: Trygga scouter - nytt material med fokus på integritet 2026-07-27
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Patrull Lodjuret',
        'Sara Öberg',
        '+46706667788',
        3
    ),
    (
        '3a54d7f1-6074-5b26-a882-476a65b555cf',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        'fb2e9a02-0605-52ff-bee5-cb82c8b61312', -- Säker verksamhet 2026-07-27
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Bävern',
        'Lena Holm',
        '+46708889900',
        10
    ),
    (
        '6edb47d0-d22d-53c7-89d7-37c3feefd27b',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        'fb2e9a02-0605-52ff-bee5-cb82c8b61312', -- Säker verksamhet 2026-07-27
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Ugglan',
        'Markus Test Ledare',
        '+46700000003',
        5
    ),
    (
        'c22ba709-72d0-53bb-95fb-ad59a3821b63',
        'd4e5f6a7-b8c9-4d23-9ef0-234567890123',
        '90db323c-56d0-5fa9-9826-9b1cc6e2eab5', -- Trauma dumping - vilka problem ser du i din scoutkår? 2026-07-27
        'Johan Nilsson',
        303,
        'Scoutkåren Norrsken',
        'Patrull Bävern',
        'Johan Nilsson',
        '+46703334455',
        12
    ),
    (
        'b4aa922c-32d1-5ae1-89c7-2b7e81c9e7ac',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        '17786f13-ca1b-5efe-acf4-e633f2dfac3b', -- Mind & Tim Bergling Foundation: Så jobbar vi med ungdomsinflytande 2026-07-27
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Patrull Ugglan',
        'Sara Öberg',
        '+46706667788',
        9
    ),
    (
        'bef4da60-a599-5f50-9fa2-100f99686177',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        '17786f13-ca1b-5efe-acf4-e633f2dfac3b', -- Mind & Tim Bergling Foundation: Så jobbar vi med ungdomsinflytande 2026-07-27
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Hela avdelningen',
        'Markus Test Funktionär',
        '+46700000002',
        4
    ),
    (
        'b7bdc207-fc76-5f70-b009-0eb1ed46fdd5',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        'ab44ffae-97b5-5311-9d76-5b96e79ba50e', -- Mind & Tim Bergling Foundation: Träffa våra ungdomsambassadörer! 2026-07-27
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Hela avdelningen',
        'Lena Holm',
        '+46708889900',
        6
    ),
    (
        '4ea84ee2-b0ba-5939-8e1d-3bf8ec5bc475',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        'ab44ffae-97b5-5311-9d76-5b96e79ba50e', -- Mind & Tim Bergling Foundation: Träffa våra ungdomsambassadörer! 2026-07-27
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Räven',
        'Markus Test Ledare',
        '+46700000003',
        11
    ),
    (
        '6c451671-bd6e-5e23-819b-e9e74dfa1ba6',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '17af255f-d728-5c22-b076-8daae5474bde', -- WAGGGS & WOSM på besök – hitta din plats i världsscoutingen! 2026-07-27
        'Markus Test Planeringsfunktionär',
        NULL,
        NULL,
        'Patrull Räven',
        'Markus Test Planeringsfunktionär',
        '+46700000001',
        3
    ),
    (
        '9182eff2-4ed2-5ca6-8823-d24cbd110650',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        '272ef6c8-ac23-5c2c-ba08-6b401086f499', -- En organisation av och för unga, med stöd av vuxna. Eller? 2026-07-27
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Patrull Vargen',
        'Markus Test Funktionär',
        '+46700000002',
        10
    ),
    (
        'd69d176d-38ec-512b-bf85-2972998e36b9',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        '272ef6c8-ac23-5c2c-ba08-6b401086f499', -- En organisation av och för unga, med stöd av vuxna. Eller? 2026-07-27
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Patrull Lodjuret',
        'Erik Johansson',
        '+46709876543',
        5
    ),
    (
        'a9448801-9ff4-5d20-9f5f-03ee8501e612',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        '5699fdf0-232b-5511-a0c9-aaaf232dd936', -- Deep-talk: Borde jag göra slut med min scoutkår? 2026-07-27
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Lodjuret',
        'Markus Test Ledare',
        '+46700000003',
        7
    ),
    (
        '3fc6e459-3210-5348-96da-c4efeb555adf',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '5699fdf0-232b-5511-a0c9-aaaf232dd936', -- Deep-talk: Borde jag göra slut med min scoutkår? 2026-07-27
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Bävern',
        'Petra Vikström',
        '+46702223344',
        12
    ),
    (
        '921034b9-9153-51e2-804d-d0ace55a5714',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        '5699fdf0-232b-5511-a0c9-aaaf232dd936', -- Deep-talk: Borde jag göra slut med min scoutkår? 2026-07-27
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Ugglan',
        'Lena Holm',
        '+46708889900',
        7
    ),
    (
        '54f7b6d6-68bd-5987-a981-db93f7eb75a6',
        'a1b2c3d4-e5f6-4a90-abcd-ef1234567890',
        'fe751b3a-b3f9-502e-9c5d-dc79d7cf9127', -- Återträff Blå hajken 2026-07-27
        'Anna Svensson',
        101,
        'Sjöscoutkåren Dansen',
        'Patrull Bävern',
        'Anna Svensson',
        '+46701234567',
        4
    ),
    (
        'c541af24-d1d9-5501-adee-f5280b209264',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        '734e4cf4-1485-5454-b7fe-ecbb03977bd2', -- Återträff Go Global 2026-07-27
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Hela avdelningen',
        'Sara Öberg',
        '+46706667788',
        6
    ),
    (
        '48b9fc35-89ea-521e-b5b5-759c1991ac14',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '647fd0b0-c417-51e0-a2ee-5e712e2d22a9', -- Återträff Ung i Norden 2026-07-27
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Hela avdelningen',
        'Petra Vikström',
        '+46702223344',
        8
    ),
    (
        'bb262ec9-87d0-5cb4-9bd1-e57c9a908018',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        '647fd0b0-c417-51e0-a2ee-5e712e2d22a9', -- Återträff Ung i Norden 2026-07-27
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Räven',
        'Lena Holm',
        '+46708889900',
        3
    ),
    (
        '89d4c638-8d23-59e0-bb93-67f51d020de1',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        '647fd0b0-c417-51e0-a2ee-5e712e2d22a9', -- Återträff Ung i Norden 2026-07-27
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Vargen',
        'Markus Test Ledare',
        '+46700000003',
        8
    ),
    (
        '7e3fadc6-14c1-5458-bb01-75dc7731f397',
        'd4e5f6a7-b8c9-4d23-9ef0-234567890123',
        '4aa4dd5c-2187-530b-a0c9-e006024efeb6', -- Återträff NAR - Nordic Adeventure Race 2026-07-27
        'Johan Nilsson',
        303,
        'Scoutkåren Norrsken',
        'Patrull Räven',
        'Johan Nilsson',
        '+46703334455',
        200
    ),
    (
        'aba5031a-e6ff-5e9f-8fdf-d3f787898e18',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        'b881e453-dc15-5666-8710-604f137374f4', -- Återträff Destination 2026-07-27
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Patrull Vargen',
        'Sara Öberg',
        '+46706667788',
        12
    ),
    (
        '1b327d41-e11a-51e7-999d-34daabe37da9',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        'b881e453-dc15-5666-8710-604f137374f4', -- Återträff Destination 2026-07-27
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Patrull Lodjuret',
        'Markus Test Funktionär',
        '+46700000002',
        7
    ),
    (
        'adc90261-1b12-5613-9769-f3d7a41352d8',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        '8905edbc-6fdb-52fd-96d1-c72ab1c30911', -- Återträff Upplev 2026-07-27
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Bävern',
        'Markus Test Ledare',
        '+46700000003',
        4
    ),
    (
        '28d8a185-a147-566f-b8f3-e9875d21a90a',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '8905edbc-6fdb-52fd-96d1-c72ab1c30911', -- Återträff Upplev 2026-07-27
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Ugglan',
        'Petra Vikström',
        '+46702223344',
        9
    ),
    (
        '835d524f-c96b-5a10-b2c1-c60f4b52f706',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        'bf3c8d00-859a-5c2e-a139-0485003a95c9', -- Quiz 2026-07-27
        'Markus Test Planeringsfunktionär',
        NULL,
        NULL,
        'Patrull Bävern',
        'Markus Test Planeringsfunktionär',
        '+46700000001',
        6
    ),
    (
        'f6ed3ac8-9902-5d3a-95ce-d9b5bfacefdc',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        'b7235adc-a125-5e79-ad36-3d28925747fa', -- Karaoke 2026-07-27
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Patrull Ugglan',
        'Markus Test Funktionär',
        '+46700000002',
        3
    ),
    (
        '482bc52a-ed60-594f-bd04-20628f5dba61',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        'b7235adc-a125-5e79-ad36-3d28925747fa', -- Karaoke 2026-07-27
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Hela avdelningen',
        'Erik Johansson',
        '+46709876543',
        8
    ),
    (
        '47813766-ef7d-5c4a-b56c-0f620f277ea4',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        'cf73f516-7167-513d-ab05-5ad6f958d69e', -- Spelkväll! 2026-07-27
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Hela avdelningen',
        'Markus Test Ledare',
        '+46700000003',
        10
    ),
    (
        '5fe3c01d-31c7-5bab-b3ab-6dcc28e06ca1',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        'cf73f516-7167-513d-ab05-5ad6f958d69e', -- Spelkväll! 2026-07-27
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Räven',
        'Petra Vikström',
        '+46702223344',
        5
    ),
    (
        '2d17248a-32ae-569e-8297-8a2461cc306d',
        'a1b2c3d4-e5f6-4a90-abcd-ef1234567890',
        'c743dad2-75e2-5870-8367-389485d79ea5', -- Folkhögskolan tar över ledarhänget 2026-07-27
        'Anna Svensson',
        101,
        'Sjöscoutkåren Dansen',
        'Patrull Räven',
        'Anna Svensson',
        '+46701234567',
        7
    ),
    (
        'b03d5202-94c3-5d12-a064-30ef057abab4',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        'ba62753e-ace6-5ea7-815c-5355dca33497', -- Gospel Gudtjänst 2026-07-27
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Patrull Vargen',
        'Erik Johansson',
        '+46709876543',
        4
    ),
    (
        '46063c80-09e4-5951-ab68-bd3eca0d7a17',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        'ba62753e-ace6-5ea7-815c-5355dca33497', -- Gospel Gudtjänst 2026-07-27
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Patrull Lodjuret',
        'Sara Öberg',
        '+46706667788',
        9
    ),
    (
        '1db82eba-24a2-5a47-9ba7-3d320967fd61',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '81fd232c-9acd-5f53-9f59-d4c4d22918b4', -- Gudstjänst 2026-07-27
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Lodjuret',
        'Petra Vikström',
        '+46702223344',
        11
    ),
    (
        '26f0b678-f058-50e9-8e6b-3d2a91e3174e',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        '81fd232c-9acd-5f53-9f59-d4c4d22918b4', -- Gudstjänst 2026-07-27
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Bävern',
        'Lena Holm',
        '+46708889900',
        6
    ),
    (
        'b75b8790-7237-544b-ac01-8c6c7b749c24',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        '81fd232c-9acd-5f53-9f59-d4c4d22918b4', -- Gudstjänst 2026-07-27
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Ugglan',
        'Markus Test Ledare',
        '+46700000003',
        11
    ),
    (
        '04990db4-7d8a-5898-9ed6-b2cc30c46dd2',
        'd4e5f6a7-b8c9-4d23-9ef0-234567890123',
        '751041eb-638b-58d8-b8b1-073554dac7c0', -- Familjescoutsamtal 2026-07-27
        'Johan Nilsson',
        303,
        'Scoutkåren Norrsken',
        'Patrull Bävern',
        'Johan Nilsson',
        '+46703334455',
        8
    ),
    (
        '05e59293-ab70-5ae0-a90a-1c858fb7af7e',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        '928bac10-8819-5e75-887e-c412e38e8a1b', -- Spårarsamtal 2026-07-27
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Hela avdelningen',
        'Markus Test Funktionär',
        '+46700000002',
        10
    ),
    (
        '32aac622-a140-555a-9182-910f3941cd03',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        'd61cc0ed-dde9-5a95-874f-6a394d470fb7', -- Utmanarsamtal 2026-07-27
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Hela avdelningen',
        'Lena Holm',
        '+46708889900',
        12
    ),
    (
        '070d322e-78aa-5d5a-b692-75609cc36743',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        'd61cc0ed-dde9-5a95-874f-6a394d470fb7', -- Utmanarsamtal 2026-07-27
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Räven',
        'Markus Test Ledare',
        '+46700000003',
        7
    ),
    (
        'e6f592e3-3245-5182-94de-43b6ee8b8558',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        'd61cc0ed-dde9-5a95-874f-6a394d470fb7', -- Utmanarsamtal 2026-07-27
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Vargen',
        'Petra Vikström',
        '+46702223344',
        12
    ),
    (
        'd62cd400-ce61-599a-978d-f265addae355',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        'a9f73bb3-1833-59c7-b061-cc71f236a1a4', -- RUNCLUB 2026-07-27
        'Markus Test Planeringsfunktionär',
        NULL,
        NULL,
        'Patrull Räven',
        'Markus Test Planeringsfunktionär',
        '+46700000001',
        9
    ),
    (
        '22e52ada-4f67-5bf2-95ca-0772462c9456',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        '1377d746-b0c3-5ec7-b903-81903fd3ca55', -- Leda Scouting - Kåsa del 1 2026-07-27
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Patrull Vargen',
        'Markus Test Funktionär',
        '+46700000002',
        6
    ),
    (
        'd4bb2b63-6d95-5f0e-bd3d-f86f0aad60c8',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        '1377d746-b0c3-5ec7-b903-81903fd3ca55', -- Leda Scouting - Kåsa del 1 2026-07-27
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Patrull Lodjuret',
        'Erik Johansson',
        '+46709876543',
        11
    ),
    (
        '0eb28600-2f4f-5843-932a-61031cc40b9a',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        'd5380b5b-9d81-54b7-b3cf-054603ee33cd', -- Speedfriending 2026-07-27
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Bävern',
        'Petra Vikström',
        '+46702223344',
        8
    ),
    (
        '1f1e9645-c41e-5113-a3f5-3f0fb68efc29',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        'd5380b5b-9d81-54b7-b3cf-054603ee33cd', -- Speedfriending 2026-07-27
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Ugglan',
        'Lena Holm',
        '+46708889900',
        3
    ),
    (
        'c6216d33-9fd3-53d2-8b53-af8e4953bb32',
        'a1b2c3d4-e5f6-4a90-abcd-ef1234567890',
        '471e7101-bac5-54a5-93ab-1c57addf4105', -- DJ Lingon Groove 2026-07-27
        'Anna Svensson',
        101,
        'Sjöscoutkåren Dansen',
        'Patrull Bävern',
        'Anna Svensson',
        '+46701234567',
        10
    ),
    (
        'bc36229e-4d4f-57a7-9c89-1561d7297cea',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        '27793f1c-f0cf-582f-a2cc-984ccd421417', -- Roverpoängjakt med de regionala roverarrangemangsutskotten! 2026-07-27
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Patrull Ugglan',
        'Erik Johansson',
        '+46709876543',
        7
    ),
    (
        'b24bddf4-a74e-5c3c-9a3a-0e9809ddb24b',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        '27793f1c-f0cf-582f-a2cc-984ccd421417', -- Roverpoängjakt med de regionala roverarrangemangsutskotten! 2026-07-27
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Hela avdelningen',
        'Sara Öberg',
        '+46706667788',
        12
    ),
    (
        '918bdcb5-7993-5143-b315-96ce0dfb4d7e',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        'a98b2543-6025-5462-b449-bf810ebce753', -- Projektledning för roverscouter 2026-07-27
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Hela avdelningen',
        'Petra Vikström',
        '+46702223344',
        4
    ),
    (
        '1f2069ca-ce43-5385-98c2-e13a072e1109',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        'a98b2543-6025-5462-b449-bf810ebce753', -- Projektledning för roverscouter 2026-07-27
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Räven',
        'Lena Holm',
        '+46708889900',
        9
    ),
    (
        '3f8b42d8-23ce-5b33-9786-4c464d14a668',
        'd4e5f6a7-b8c9-4d23-9ef0-234567890123',
        'b5eb6a48-0a1f-5e2b-8848-f6880c4a7d55', -- Stand-up kväll! 2026-07-27
        'Johan Nilsson',
        303,
        'Scoutkåren Norrsken',
        'Patrull Räven',
        'Johan Nilsson',
        '+46703334455',
        11
    ),
    (
        '1c002bd0-8acf-5a60-b530-0f8c11050819',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        'b8961dd7-94d3-5faa-8539-28d23be901a1', -- Quiz: Om scouter, Skåne och lägerskoj 2026-07-27
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Patrull Vargen',
        'Sara Öberg',
        '+46706667788',
        8
    ),
    (
        'f8d6d07c-b196-53e2-8072-ee3015878ff5',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        'b8961dd7-94d3-5faa-8539-28d23be901a1', -- Quiz: Om scouter, Skåne och lägerskoj 2026-07-27
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Patrull Lodjuret',
        'Markus Test Funktionär',
        '+46700000002',
        3
    ),
    (
        '75373fdc-4c0f-5ef1-be14-5ea8731575e3',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        '93cb71c7-13b9-5a05-8112-161e8c30c1e1', -- Roverhinderbana 2026-07-27
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Lodjuret',
        'Lena Holm',
        '+46708889900',
        5
    ),
    (
        '59512074-5cf5-5d56-9da4-432473d7e1e1',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        '93cb71c7-13b9-5a05-8112-161e8c30c1e1', -- Roverhinderbana 2026-07-27
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Bävern',
        'Markus Test Ledare',
        '+46700000003',
        10
    ),
    (
        'bbb426f3-fdcb-5836-abf0-f5b66269ab40',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '93cb71c7-13b9-5a05-8112-161e8c30c1e1', -- Roverhinderbana 2026-07-27
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Ugglan',
        'Petra Vikström',
        '+46702223344',
        5
    ),
    (
        '1e375d5c-15c3-5fb5-85ed-54c6e6c323c0',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        'dcbe3520-35fd-5bf1-bc01-3bf4420c7f3a', -- Roverhinderbana 2026-07-27
        'Markus Test Planeringsfunktionär',
        NULL,
        NULL,
        'Patrull Bävern',
        'Markus Test Planeringsfunktionär',
        '+46700000001',
        12
    ),
    (
        '36b08583-9921-57fc-b36a-4a5a70d396ef',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        '7272a920-5a32-5747-ad7f-3878aeece0ad', -- Sagostund 2026-07-27
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Hela avdelningen',
        'Erik Johansson',
        '+46709876543',
        4
    ),
    (
        '8fecbfd9-a02b-5007-b5e6-a8283729a2ac',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        'a371cfb1-38a6-5be9-a02d-0e5d373d5012', -- Kvällsbön 2026-07-27
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Hela avdelningen',
        'Markus Test Ledare',
        '+46700000003',
        6
    ),
    (
        '52d61cef-3f1a-5460-b4c0-27aed0cb1c88',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        'a371cfb1-38a6-5be9-a02d-0e5d373d5012', -- Kvällsbön 2026-07-27
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Räven',
        'Petra Vikström',
        '+46702223344',
        11
    ),
    (
        '7ced60f0-7c7e-5b05-96ba-40e030a9d800',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        'a371cfb1-38a6-5be9-a02d-0e5d373d5012', -- Kvällsbön 2026-07-27
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Vargen',
        'Lena Holm',
        '+46708889900',
        6
    ),
    (
        '2cfd691e-b6ee-54b0-bb70-330dcdfa4964',
        'a1b2c3d4-e5f6-4a90-abcd-ef1234567890',
        'ffcc33c5-3e99-52ea-924b-56e7269e3a4b', -- 27/7 – Midsommar 🌼 2026-07-27
        'Anna Svensson',
        101,
        'Sjöscoutkåren Dansen',
        'Patrull Räven',
        'Anna Svensson',
        '+46701234567',
        3
    ),
    (
        '6679030b-714a-534f-94b7-2d371523e5cf',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        'f04f2856-0477-53a0-9e44-0e2ad5fbb70d', -- Dagens lek 2026-07-27
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Patrull Vargen',
        'Erik Johansson',
        '+46709876543',
        10
    ),
    (
        'e4c409f3-0470-5450-a27f-c79825c52eb9',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        'f04f2856-0477-53a0-9e44-0e2ad5fbb70d', -- Dagens lek 2026-07-27
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Patrull Lodjuret',
        'Sara Öberg',
        '+46706667788',
        5
    ),
    (
        '21ec84f6-46b5-5103-a2b8-79728f1f9e46',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        '419a5558-d525-5f10-a9f3-467c8d860321', -- Hand the Ball 2026-07-27
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Bävern',
        'Lena Holm',
        '+46708889900',
        12
    ),
    (
        '5598c7b6-1b43-5ce5-8995-665425233bab',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        '419a5558-d525-5f10-a9f3-467c8d860321', -- Hand the Ball 2026-07-27
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Ugglan',
        'Markus Test Ledare',
        '+46700000003',
        7
    ),
    (
        'd0210bf9-fde2-54d5-8302-925666b4aff1',
        'd4e5f6a7-b8c9-4d23-9ef0-234567890123',
        'b327ec08-141c-5c24-8e0c-6c57cbe914a9', -- Kubbturnering 2026-07-27
        'Johan Nilsson',
        303,
        'Scoutkåren Norrsken',
        'Patrull Bävern',
        'Johan Nilsson',
        '+46703334455',
        4
    ),
    (
        'f430a37a-afaa-5f5d-8392-47d447934bad',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        '340bf173-a87f-5fc4-8101-06d9ffcdf112', -- Kubbturnering 2026-07-27
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Patrull Ugglan',
        'Sara Öberg',
        '+46706667788',
        11
    ),
    (
        'afb2c384-c1ea-5ac5-a27e-c12a79a02196',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        '340bf173-a87f-5fc4-8101-06d9ffcdf112', -- Kubbturnering 2026-07-27
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Hela avdelningen',
        'Markus Test Funktionär',
        '+46700000002',
        6
    ),
    (
        '6c397e03-4571-5259-85fd-1f0d03efe498',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        'bd47dc77-2923-5247-8d41-6f2988fc9d42', -- Disko! 2026-07-27
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Hela avdelningen',
        'Lena Holm',
        '+46708889900',
        8
    ),
    (
        'f803fc74-d3a4-5c03-a66d-ed921c5a90aa',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        'bd47dc77-2923-5247-8d41-6f2988fc9d42', -- Disko! 2026-07-27
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Räven',
        'Markus Test Ledare',
        '+46700000003',
        3
    ),
    (
        '053507f5-9e60-5d17-bac9-9da39520b811',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        'ab7e0f8c-d271-51c9-8f20-144f2b28fd6c', -- Lekaktiviteter 2026-07-27
        'Markus Test Planeringsfunktionär',
        NULL,
        NULL,
        'Patrull Räven',
        'Markus Test Planeringsfunktionär',
        '+46700000001',
        5
    ),
    (
        '26f626f4-6dd8-534b-9c30-034343567798',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        '697113d8-32f1-5248-acd9-5d4f21d2b815', -- Bubbelballs 2026-07-27
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Patrull Vargen',
        'Markus Test Funktionär',
        '+46700000002',
        12
    ),
    (
        '7384a471-9dec-5f75-98e1-cbab4b68bb78',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        '697113d8-32f1-5248-acd9-5d4f21d2b815', -- Bubbelballs 2026-07-27
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Patrull Lodjuret',
        'Erik Johansson',
        '+46709876543',
        7
    ),
    (
        '82ca92ce-6f6e-5d15-aaca-ae1af31c228b',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        '8cf6c9a5-0572-5fb7-97e8-f2a0b86f970f', -- Godnattsaga 2026-07-27
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Lodjuret',
        'Markus Test Ledare',
        '+46700000003',
        9
    ),
    (
        'c19cace6-481f-54f8-9c04-e43fcff1bbdc',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '8cf6c9a5-0572-5fb7-97e8-f2a0b86f970f', -- Godnattsaga 2026-07-27
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Bävern',
        'Petra Vikström',
        '+46702223344',
        4
    ),
    (
        '1c5f6276-3cf2-58ed-8e71-c1e8bd9c502a',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        '8cf6c9a5-0572-5fb7-97e8-f2a0b86f970f', -- Godnattsaga 2026-07-27
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Ugglan',
        'Lena Holm',
        '+46708889900',
        9
    ),
    (
        'ea809754-1039-5658-9210-85a23c29f6b1',
        'a1b2c3d4-e5f6-4a90-abcd-ef1234567890',
        'a15d66d0-7cca-50de-a4b0-717651865798', -- Kåsan 2026-07-27
        'Anna Svensson',
        101,
        'Sjöscoutkåren Dansen',
        'Patrull Bävern',
        'Anna Svensson',
        '+46701234567',
        6
    ),
    (
        '9fd16513-7960-5131-a7f5-36f769ca7265',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        '610885be-25c9-51f7-b3aa-4abb9f1a4b73', -- Känslokartan 2026-07-27
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Hela avdelningen',
        'Sara Öberg',
        '+46706667788',
        8
    ),
    (
        '6b92b4d0-b468-53c6-b37b-119d18b869c3',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        'c7dce563-ead5-5d00-ade9-cc7796b5f2b3', -- Brädspel 2026-07-27
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Hela avdelningen',
        'Petra Vikström',
        '+46702223344',
        10
    ),
    (
        '41075f2e-bc03-5257-807b-830538279fee',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        'c7dce563-ead5-5d00-ade9-cc7796b5f2b3', -- Brädspel 2026-07-27
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Räven',
        'Lena Holm',
        '+46708889900',
        5
    ),
    (
        'c70b7519-c44d-5ef0-8f76-0700187e9cac',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        'c7dce563-ead5-5d00-ade9-cc7796b5f2b3', -- Brädspel 2026-07-27
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Vargen',
        'Markus Test Ledare',
        '+46700000003',
        10
    ),
    (
        '1903c471-5fc4-59ba-8aa7-08ba9e0e436d',
        'd4e5f6a7-b8c9-4d23-9ef0-234567890123',
        'e392b8e1-350c-5a6b-87c9-bd98f96558f3', -- Cybersäkerhet med Unga forskare 2026-07-27
        'Johan Nilsson',
        303,
        'Scoutkåren Norrsken',
        'Patrull Räven',
        'Johan Nilsson',
        '+46703334455',
        7
    ),
    (
        '94171179-2ce6-507a-8778-e15cfef788e9',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        '87e1b1cb-9009-546b-955a-c1756d87737f', -- Hantverksfokus: Täljning 2026-07-27
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Patrull Vargen',
        'Sara Öberg',
        '+46706667788',
        4
    ),
    (
        '6183bd39-3164-547b-ad41-3d04fc9b9a43',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        '87e1b1cb-9009-546b-955a-c1756d87737f', -- Hantverksfokus: Täljning 2026-07-27
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Patrull Lodjuret',
        'Markus Test Funktionär',
        '+46700000002',
        9
    ),
    (
        '81880000-b689-5d82-bf1a-8b35902e735d',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        '9e60857a-fe9c-56b0-95da-eac7249b4d07', -- Knoprep 2026-07-27
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Bävern',
        'Markus Test Ledare',
        '+46700000003',
        6
    ),
    (
        'ca694959-0484-5260-bdb2-599bc638b468',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '9e60857a-fe9c-56b0-95da-eac7249b4d07', -- Knoprep 2026-07-27
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Ugglan',
        'Petra Vikström',
        '+46702223344',
        11
    ),
    (
        '73c17f9a-fdea-508d-96a2-7dcae5ec0f09',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '973ad700-673a-5f3a-b186-3bb43e890bb3', -- Tillsammans målning 2026-07-27
        'Markus Test Planeringsfunktionär',
        NULL,
        NULL,
        'Patrull Bävern',
        'Markus Test Planeringsfunktionär',
        '+46700000001',
        8
    ),
    (
        'f58a9195-e4bd-51ba-a38a-95376237147b',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        'e8084f74-02e6-52b8-83c3-3919e0701795', -- Halmpool 2026-07-27
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Patrull Ugglan',
        'Markus Test Funktionär',
        '+46700000002',
        5
    ),
    (
        '2f939006-e6bc-58cd-95bc-edd0a1749aec',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        'e8084f74-02e6-52b8-83c3-3919e0701795', -- Halmpool 2026-07-27
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Hela avdelningen',
        'Erik Johansson',
        '+46709876543',
        10
    ),
    (
        '1f1b3d80-0c53-505a-943b-d9982f11cad7',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        'bc6ab101-53ed-5514-a44e-bdf5ddd57962', -- Slankaruseller 2026-07-27
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Hela avdelningen',
        'Markus Test Ledare',
        '+46700000003',
        12
    ),
    (
        '104744f9-62cd-569b-8574-9b0961b57bce',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        'bc6ab101-53ed-5514-a44e-bdf5ddd57962', -- Slankaruseller 2026-07-27
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Räven',
        'Petra Vikström',
        '+46702223344',
        7
    ),
    (
        'ba57a543-c0e7-5917-80ff-d8f0245f18d5',
        'a1b2c3d4-e5f6-4a90-abcd-ef1234567890',
        '9cf4dfd8-d2d6-58aa-be42-2bffdc4488ac', -- Svensk klassiker 2026-07-27
        'Anna Svensson',
        101,
        'Sjöscoutkåren Dansen',
        'Patrull Räven',
        'Anna Svensson',
        '+46701234567',
        9
    ),
    (
        '1166efbf-afcf-58e4-9e3a-ba43345b4fb8',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        '2250b265-08b5-5ada-ac0c-d982c9a4a0e4', -- Svensk klassiker 2026-07-27
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Patrull Vargen',
        'Erik Johansson',
        '+46709876543',
        6
    ),
    (
        '8076fdb0-134e-5c85-96a0-48e2ae705044',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        '2250b265-08b5-5ada-ac0c-d982c9a4a0e4', -- Svensk klassiker 2026-07-27
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Patrull Lodjuret',
        'Sara Öberg',
        '+46706667788',
        11
    ),
    (
        '7383bb1f-c2eb-532c-8c66-f3aa46075a9e',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '894b794e-82be-510f-ace5-f7ada9983f04', -- Våga utmana normerna 2026-07-27
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Lodjuret',
        'Petra Vikström',
        '+46702223344',
        3
    ),
    (
        'afe7ddf2-7740-58cd-a901-d527ab4f08e7',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        '894b794e-82be-510f-ace5-f7ada9983f04', -- Våga utmana normerna 2026-07-27
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Bävern',
        'Lena Holm',
        '+46708889900',
        8
    ),
    (
        'd0743c78-79eb-5993-9df7-cfe6ba6457c1',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        '894b794e-82be-510f-ace5-f7ada9983f04', -- Våga utmana normerna 2026-07-27
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Ugglan',
        'Markus Test Ledare',
        '+46700000003',
        3
    ),
    (
        'b3cfbbbe-dcb1-5a6b-b672-72a9bdd4f4d6',
        'd4e5f6a7-b8c9-4d23-9ef0-234567890123',
        '0d878812-5868-5f0a-bab4-2001c0fafcdc', -- Hand the Ball 2026-07-27
        'Johan Nilsson',
        303,
        'Scoutkåren Norrsken',
        'Patrull Bävern',
        'Johan Nilsson',
        '+46703334455',
        10
    ),
    (
        'a95d161e-7c6f-576b-bcce-82edf545eae2',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        '4e3821d7-8615-5f3e-8829-7000f05c9711', -- Våga utmana normerna 2026-07-27
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Hela avdelningen',
        'Markus Test Funktionär',
        '+46700000002',
        12
    ),
    (
        '10f8b2b5-7df2-5330-a6cb-04457c0bf3f4',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        'a6700f46-99c8-57f6-b195-df8de00b2a99', -- Trygghetsspelet 2026-07-27
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Hela avdelningen',
        'Lena Holm',
        '+46708889900',
        4
    ),
    (
        '08694e7d-5ba4-594e-bb9f-27ae323ac9f4',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        'a6700f46-99c8-57f6-b195-df8de00b2a99', -- Trygghetsspelet 2026-07-27
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Räven',
        'Markus Test Ledare',
        '+46700000003',
        9
    ),
    (
        'fa05a718-e251-5916-b53e-21ed38b8fa96',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        'a6700f46-99c8-57f6-b195-df8de00b2a99', -- Trygghetsspelet 2026-07-27
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Vargen',
        'Petra Vikström',
        '+46702223344',
        1
    ),
    (
        '779fb736-6904-55d0-95af-0ddd1acd3359',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '9e29c220-5584-5735-b757-27f5f9b5d57e', -- Musikquiz 2026-07-27
        'Markus Test Planeringsfunktionär',
        NULL,
        NULL,
        'Patrull Räven',
        'Markus Test Planeringsfunktionär',
        '+46700000001',
        11
    ),
    (
        '86ab142e-f96b-5a79-b194-037825c67e3f',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        '6da1cb24-e376-514e-a5d5-7da3c4c45660', -- Musikquiz 2026-07-27
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Patrull Vargen',
        'Markus Test Funktionär',
        '+46700000002',
        8
    ),
    (
        '3cfcd14f-13bb-53e1-a82a-250fb0b0279f',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        '6da1cb24-e376-514e-a5d5-7da3c4c45660', -- Musikquiz 2026-07-27
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Patrull Lodjuret',
        'Erik Johansson',
        '+46709876543',
        3
    ),
    (
        'cdc72e89-91ac-57f5-bc90-aef305a6247c',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '9c14b462-2c71-5f6d-8b04-59300e848a77', -- Mekanisk tjur 2026-07-27
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Bävern',
        'Petra Vikström',
        '+46702223344',
        10
    ),
    (
        '716b7981-2f35-51c8-9fc3-9a50602d2afa',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        '9c14b462-2c71-5f6d-8b04-59300e848a77', -- Mekanisk tjur 2026-07-27
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Ugglan',
        'Lena Holm',
        '+46708889900',
        5
    ),
    (
        '2a44a6de-19b7-511c-b052-320c3517ef25',
        'a1b2c3d4-e5f6-4a90-abcd-ef1234567890',
        'f9be63fd-339d-559e-9591-0c9ef66e9e2a', -- Femkamp 2026-07-27
        'Anna Svensson',
        101,
        'Sjöscoutkåren Dansen',
        'Patrull Bävern',
        'Anna Svensson',
        '+46701234567',
        12
    ),
    (
        'ff9f3a31-5a6b-527a-9968-af72daf9ce1f',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        'a32d19c5-987d-5fca-a48a-39d55d8bdc16', -- Unga forskare 2026-07-27
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Patrull Ugglan',
        'Erik Johansson',
        '+46709876543',
        9
    ),
    (
        'd8993154-2a73-59ca-9031-7c6df9012251',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        'a32d19c5-987d-5fca-a48a-39d55d8bdc16', -- Unga forskare 2026-07-27
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Hela avdelningen',
        'Sara Öberg',
        '+46706667788',
        4
    ),
    (
        'da84e97c-2c66-5bf0-9c0c-15c0f0fc8ad0',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '5e5bd9f4-bd09-5802-9d8b-5cf077f5332a', -- Hand the Ball 2026-07-27
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Hela avdelningen',
        'Petra Vikström',
        '+46702223344',
        6
    ),
    (
        '4e744f31-5fe7-5362-98d7-8a25f23317c5',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        '5e5bd9f4-bd09-5802-9d8b-5cf077f5332a', -- Hand the Ball 2026-07-27
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Räven',
        'Lena Holm',
        '+46708889900',
        11
    ),
    (
        '26c2afc8-63f2-5787-9bcd-dabc4b467a12',
        'd4e5f6a7-b8c9-4d23-9ef0-234567890123',
        'fbc1da73-3032-5b07-81c3-834b369cdbb4', -- The Great Migration of Birds with THE HERDS 2026-07-28
        'Johan Nilsson',
        303,
        'Scoutkåren Norrsken',
        'Patrull Räven',
        'Johan Nilsson',
        '+46703334455',
        3
    ),
    (
        '370b3e14-917d-5514-8c97-4526d9a94d3c',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        '4c9b890c-63bb-55b1-89e4-6935d327a556', -- Henrik Wahlström – Uppochner: Att leva med och tala om psykisk ohälsa 2026-07-28
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Patrull Vargen',
        'Sara Öberg',
        '+46706667788',
        10
    ),
    (
        'f29a0d5c-e8ec-52f0-9ccd-58c9373c7083',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        '4c9b890c-63bb-55b1-89e4-6935d327a556', -- Henrik Wahlström – Uppochner: Att leva med och tala om psykisk ohälsa 2026-07-28
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Patrull Lodjuret',
        'Markus Test Funktionär',
        '+46700000002',
        5
    ),
    (
        '2d8cc613-60a1-5b56-878a-9873d9dbdf8c',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        '9677d2d0-534a-5834-bb70-8357fe094083', -- En organsation av och för unga, med stöd av vuxna. Eller? 2026-07-28
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Lodjuret',
        'Lena Holm',
        '+46708889900',
        7
    ),
    (
        '157caa43-fd4a-529a-97fd-5be416b8779a',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        '9677d2d0-534a-5834-bb70-8357fe094083', -- En organsation av och för unga, med stöd av vuxna. Eller? 2026-07-28
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Bävern',
        'Markus Test Ledare',
        '+46700000003',
        12
    ),
    (
        '8c16e3b8-a1ee-5ec4-b5ad-4125168ca724',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '9677d2d0-534a-5834-bb70-8357fe094083', -- En organsation av och för unga, med stöd av vuxna. Eller? 2026-07-28
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Ugglan',
        'Petra Vikström',
        '+46702223344',
        7
    ),
    (
        '062bf384-4db2-5f7f-be48-7cc1de90fe1e',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '58e738bf-54ce-553f-8c01-9322a4f60b11', -- Vad tycker makten om dig som ung? KFUM har svaret! 2026-07-28
        'Markus Test Planeringsfunktionär',
        NULL,
        NULL,
        'Patrull Bävern',
        'Markus Test Planeringsfunktionär',
        '+46700000001',
        4
    ),
    (
        'ace7af62-ed73-5812-9101-2f4f13701247',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        'f492b12d-c637-5616-85bb-2a5eed4ad3a3', -- Desinformation, demokrati och sköldpaddor 2026-07-28
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Hela avdelningen',
        'Erik Johansson',
        '+46709876543',
        6
    ),
    (
        'fbd27565-cd27-5d6b-bfa6-a7f3a0a29ad5',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        '7ca65d9b-1b5a-57c5-8b9f-af5689290f07', -- Treskablinoll: Små beteenden, stor skillnad – om normer och att skapa ett tryggare klimat 2026-07-28
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Hela avdelningen',
        'Markus Test Ledare',
        '+46700000003',
        8
    ),
    (
        '633c4546-29b3-5bd5-abd5-88d33f3c51be',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '7ca65d9b-1b5a-57c5-8b9f-af5689290f07', -- Treskablinoll: Små beteenden, stor skillnad – om normer och att skapa ett tryggare klimat 2026-07-28
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Räven',
        'Petra Vikström',
        '+46702223344',
        3
    ),
    (
        'f4c689c1-7324-5998-81be-a0ff76711a82',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        '7ca65d9b-1b5a-57c5-8b9f-af5689290f07', -- Treskablinoll: Små beteenden, stor skillnad – om normer och att skapa ett tryggare klimat 2026-07-28
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Vargen',
        'Lena Holm',
        '+46708889900',
        8
    ),
    (
        '2e0138d7-ab13-5eac-bb0a-1f77b42c23eb',
        'a1b2c3d4-e5f6-4a90-abcd-ef1234567890',
        'ea9ade84-ef31-5f6e-830c-93008709c11a', -- Quiz 2026-07-28
        'Anna Svensson',
        101,
        'Sjöscoutkåren Dansen',
        'Patrull Räven',
        'Anna Svensson',
        '+46701234567',
        5
    ),
    (
        'fa1e1bae-7688-5862-afee-7b5644b02db3',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        'c9eb6f09-a37c-50b9-abb7-1dd54c98a49f', -- Äventyrararsamtal 2026-07-28
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Patrull Vargen',
        'Erik Johansson',
        '+46709876543',
        12
    ),
    (
        '00a60dff-eb94-5623-a475-f20fbbe3b7da',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        'c9eb6f09-a37c-50b9-abb7-1dd54c98a49f', -- Äventyrararsamtal 2026-07-28
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Patrull Lodjuret',
        'Sara Öberg',
        '+46706667788',
        7
    ),
    (
        'ec93cb95-ae6a-5db1-92cc-f1b5c40cf35d',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        '43550c20-55bc-5f9a-a8fd-a260997e1759', -- Upptäckarsamtal 2026-07-28
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Bävern',
        'Lena Holm',
        '+46708889900',
        4
    ),
    (
        '5e5a48d7-ddc0-57ca-a243-a1efd182fbf6',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        '43550c20-55bc-5f9a-a8fd-a260997e1759', -- Upptäckarsamtal 2026-07-28
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Ugglan',
        'Markus Test Ledare',
        '+46700000003',
        9
    ),
    (
        '117ca42b-91e2-58b6-a2a8-eaaa03cd9eea',
        'd4e5f6a7-b8c9-4d23-9ef0-234567890123',
        '76fd5ec7-3097-52af-a625-fdbc403797d9', -- Leda Scouting - Kåsa del 2 2026-07-28
        'Johan Nilsson',
        303,
        'Scoutkåren Norrsken',
        'Patrull Bävern',
        'Johan Nilsson',
        '+46703334455',
        6
    ),
    (
        'd1aa091e-1741-5ad1-a7d1-3767c6014d8a',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        '24d1ae2b-6f15-5b63-92fe-3c01cf5151e5', -- Svenska Freds 2026-07-28
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Patrull Ugglan',
        'Sara Öberg',
        '+46706667788',
        3
    ),
    (
        'ee8e5e27-b572-560c-a629-981c6763ef86',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        '24d1ae2b-6f15-5b63-92fe-3c01cf5151e5', -- Svenska Freds 2026-07-28
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Hela avdelningen',
        'Markus Test Funktionär',
        '+46700000002',
        8
    ),
    (
        'bb2c09ac-f14e-5af0-ac4d-66e1ee0b58cd',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        '35249f33-50d1-57b2-8f12-fd99ce64cf47', -- Bris 2026-07-28
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Hela avdelningen',
        'Lena Holm',
        '+46708889900',
        10
    ),
    (
        '9da9c085-0247-5d17-b7ef-e3773170ae49',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        '35249f33-50d1-57b2-8f12-fd99ce64cf47', -- Bris 2026-07-28
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Räven',
        'Markus Test Ledare',
        '+46700000003',
        5
    ),
    (
        '432856a6-53b1-5068-8a2c-3ab5f9718ef0',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '82cc345e-54ce-569a-9c23-73dab334769a', -- Kan vi vara scouter och aktivister samtidigt? 2026-07-28
        'Markus Test Planeringsfunktionär',
        NULL,
        NULL,
        'Patrull Räven',
        'Markus Test Planeringsfunktionär',
        '+46700000001',
        7
    ),
    (
        '641c0aee-e086-5427-a4f1-4b359d9715a6',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        '784116ea-ea92-5a89-b5b4-1c9060b8b157', -- Certifierad kurs i kramande 2026-07-28
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Patrull Vargen',
        'Markus Test Funktionär',
        '+46700000002',
        4
    ),
    (
        '730d0026-d67a-5589-9e5a-05f5fb94ccd4',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        '784116ea-ea92-5a89-b5b4-1c9060b8b157', -- Certifierad kurs i kramande 2026-07-28
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Patrull Lodjuret',
        'Erik Johansson',
        '+46709876543',
        9
    ),
    (
        '1c22cd3e-cc04-5472-8b7d-04c9c599d5fd',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        'f40c0dff-d0e6-5b3a-aa19-a445c03d54e1', -- Speedfriending 2026-07-28
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Lodjuret',
        'Markus Test Ledare',
        '+46700000003',
        11
    ),
    (
        '0fc4568d-4f3e-58b7-9fdc-388ea2a102d9',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        'f40c0dff-d0e6-5b3a-aa19-a445c03d54e1', -- Speedfriending 2026-07-28
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Bävern',
        'Petra Vikström',
        '+46702223344',
        6
    ),
    (
        'fe90309c-2eae-5f32-b14a-cbd596a842a2',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        'f40c0dff-d0e6-5b3a-aa19-a445c03d54e1', -- Speedfriending 2026-07-28
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Ugglan',
        'Lena Holm',
        '+46708889900',
        11
    ),
    (
        '8b8b62f8-0313-5e2c-bd25-b816975eb9d0',
        'a1b2c3d4-e5f6-4a90-abcd-ef1234567890',
        'a62f1b5d-e3c4-5038-bf8c-20ac8cd32658', -- Speeddejting 2026-07-28
        'Anna Svensson',
        101,
        'Sjöscoutkåren Dansen',
        'Patrull Bävern',
        'Anna Svensson',
        '+46701234567',
        8
    ),
    (
        'e0f4ebe8-2cc7-5007-adb1-0e9b838b9e84',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        'efa3894a-48c1-5122-a5dd-1fb9d38caa76', -- Tillsammans bygger vi Sverige 2026-07-28
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Hela avdelningen',
        'Sara Öberg',
        '+46706667788',
        10
    ),
    (
        '3ac8dde5-a223-529c-927d-980cb4519c3f',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '1afdb52a-3c28-5aa6-88f3-87c059d4d6f4', -- Tillsammans bygger vi Sverige 2026-07-28
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Hela avdelningen',
        'Petra Vikström',
        '+46702223344',
        12
    ),
    (
        '71dec408-a2c3-5774-9433-7521adcce4b0',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        '1afdb52a-3c28-5aa6-88f3-87c059d4d6f4', -- Tillsammans bygger vi Sverige 2026-07-28
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Räven',
        'Lena Holm',
        '+46708889900',
        7
    ),
    (
        '2a9b824a-6914-567a-aced-de4befdc1b74',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        '1afdb52a-3c28-5aa6-88f3-87c059d4d6f4', -- Tillsammans bygger vi Sverige 2026-07-28
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Vargen',
        'Markus Test Ledare',
        '+46700000003',
        12
    ),
    (
        '922ea0d3-f641-5019-8a9c-c612190f0fa8',
        'd4e5f6a7-b8c9-4d23-9ef0-234567890123',
        '145c51dd-fb96-5a8a-8f2b-0a83aa4ee067', -- Tillsammans bygger vi Sverige 2026-07-28
        'Johan Nilsson',
        303,
        'Scoutkåren Norrsken',
        'Patrull Räven',
        'Johan Nilsson',
        '+46703334455',
        9
    ),
    (
        'f88d069b-3254-5817-9aee-e6714b5c12f8',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        'ef6cff35-bb58-58d6-9ad5-74d373d01035', -- Tillsammans bygger vi Sverige 2026-07-28
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Patrull Vargen',
        'Sara Öberg',
        '+46706667788',
        6
    ),
    (
        '1a709987-ab4b-5f0e-afca-3cf5f9f948c9',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        'ef6cff35-bb58-58d6-9ad5-74d373d01035', -- Tillsammans bygger vi Sverige 2026-07-28
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Patrull Lodjuret',
        'Markus Test Funktionär',
        '+46700000002',
        11
    ),
    (
        '0e810ae0-a728-5ac0-a16d-7e2ea4eeb110',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        'fbae3f1c-2b9a-55c4-9a46-43f90201c1d1', -- Sagostund 2026-07-28
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Bävern',
        'Markus Test Ledare',
        '+46700000003',
        8
    ),
    (
        'a7f43dac-2f2f-53d2-b5b1-86a8370b42c2',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        'fbae3f1c-2b9a-55c4-9a46-43f90201c1d1', -- Sagostund 2026-07-28
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Ugglan',
        'Petra Vikström',
        '+46702223344',
        3
    ),
    (
        '1f73d591-4776-5877-8991-2959b65aa8b5',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '6b0a98a1-1c86-5fb8-a5c0-d2a1b40510a2', -- Kvällsbön 2026-07-28
        'Markus Test Planeringsfunktionär',
        NULL,
        NULL,
        'Patrull Bävern',
        'Markus Test Planeringsfunktionär',
        '+46700000001',
        10
    ),
    (
        'c2285911-fe3a-5f19-b486-6f92620ed6a5',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        '4c41a1ac-f0cf-5f7a-b87c-41dd760c976b', -- 28/7 – Kräftskiva 🦞 2026-07-28
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Patrull Ugglan',
        'Markus Test Funktionär',
        '+46700000002',
        7
    ),
    (
        '296655dd-2c8d-5b7b-9756-6547f690d3ca',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        '4c41a1ac-f0cf-5f7a-b87c-41dd760c976b', -- 28/7 – Kräftskiva 🦞 2026-07-28
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Hela avdelningen',
        'Erik Johansson',
        '+46709876543',
        12
    ),
    (
        'a7b3ffff-0302-5e07-9d32-61ba0606486e',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        'c65ebccd-58df-5af6-9536-7bace9994258', -- Parad till lägerbål 2026-07-28
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Hela avdelningen',
        'Markus Test Ledare',
        '+46700000003',
        3000
    ),
    (
        '329afd0b-4a00-5aa1-9bfe-c34ab401eea9',
        'a1b2c3d4-e5f6-4a90-abcd-ef1234567890',
        'e188aa7c-da5f-505a-96b4-f169416df98d', -- Dagens lek 2026-07-28
        'Anna Svensson',
        101,
        'Sjöscoutkåren Dansen',
        'Patrull Räven',
        'Anna Svensson',
        '+46701234567',
        11
    ),
    (
        'b3f99c86-2f36-573c-ab5f-9d68deefc266',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        '3e0bd307-6448-5c91-9ae5-f434a64a9247', -- Brottning 2026-07-28
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Patrull Vargen',
        'Erik Johansson',
        '+46709876543',
        8
    ),
    (
        'afa5c3f8-d48c-5c9c-8390-aa0be00ff04e',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        '3e0bd307-6448-5c91-9ae5-f434a64a9247', -- Brottning 2026-07-28
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Patrull Lodjuret',
        'Sara Öberg',
        '+46706667788',
        3
    ),
    (
        '2a5d4665-c808-5cff-95ef-cd9e0bd11222',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '619ef56a-a375-5507-83e0-b3d7433492e5', -- Brottning 2026-07-28
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Lodjuret',
        'Petra Vikström',
        '+46702223344',
        5
    ),
    (
        '2d233582-db42-58fb-b59d-2b18ca1c7e4f',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        '619ef56a-a375-5507-83e0-b3d7433492e5', -- Brottning 2026-07-28
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Bävern',
        'Lena Holm',
        '+46708889900',
        10
    ),
    (
        'ea2744be-9abb-5fb2-9ba9-d0bb2024790d',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        '619ef56a-a375-5507-83e0-b3d7433492e5', -- Brottning 2026-07-28
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Ugglan',
        'Markus Test Ledare',
        '+46700000003',
        5
    ),
    (
        '4cac4ca3-4b39-52c5-9221-4353f2e215db',
        'd4e5f6a7-b8c9-4d23-9ef0-234567890123',
        'f8d327b2-b0fc-551c-a985-22e3469b4315', -- Brottning 2026-07-28
        'Johan Nilsson',
        303,
        'Scoutkåren Norrsken',
        'Patrull Bävern',
        'Johan Nilsson',
        '+46703334455',
        12
    ),
    (
        '9f0b4056-22f6-5c7b-a534-691828589c38',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        'f9dde14c-4518-5ba5-9b6b-79f5b75d5799', -- Brottning 2026-07-28
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Hela avdelningen',
        'Markus Test Funktionär',
        '+46700000002',
        4
    ),
    (
        '204dfc93-9d1f-5a81-a1d1-1793e29f96f2',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        '8e8ba3a7-bedb-5473-97ac-a8e34f6a3b2a', -- Brottning 2026-07-28
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Hela avdelningen',
        'Lena Holm',
        '+46708889900',
        6
    ),
    (
        '5790eaa6-694c-5532-beed-e0ac52b7639f',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        '8e8ba3a7-bedb-5473-97ac-a8e34f6a3b2a', -- Brottning 2026-07-28
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Räven',
        'Markus Test Ledare',
        '+46700000003',
        11
    ),
    (
        '9a7df930-bcab-5592-b472-4c562abd2968',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '8e8ba3a7-bedb-5473-97ac-a8e34f6a3b2a', -- Brottning 2026-07-28
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Vargen',
        'Petra Vikström',
        '+46702223344',
        6
    ),
    (
        'ec494541-cf6e-59bc-84d3-2052d5f4479e',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        'c3b747f0-650f-5322-a010-e7b4853d91a6', -- Brottning 2026-07-28
        'Markus Test Planeringsfunktionär',
        NULL,
        NULL,
        'Patrull Räven',
        'Markus Test Planeringsfunktionär',
        '+46700000001',
        3
    ),
    (
        '60a6af4f-c296-5d68-8d99-9c26adbc66e8',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        '2343ac25-6632-5756-9f35-54cb001e1ecf', -- Lekaktiviteter 2026-07-28
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Patrull Vargen',
        'Markus Test Funktionär',
        '+46700000002',
        10
    ),
    (
        '6e35a5cf-2ae3-55a0-a5b9-3c8edce9d5ad',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        '2343ac25-6632-5756-9f35-54cb001e1ecf', -- Lekaktiviteter 2026-07-28
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Patrull Lodjuret',
        'Erik Johansson',
        '+46709876543',
        5
    ),
    (
        '79dd22b8-7757-5ad2-bf4f-7fde4b4ba1c0',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '70b9d463-b701-51a2-8dfc-bc9cd4960320', -- Bubbelballs 2026-07-28
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Bävern',
        'Petra Vikström',
        '+46702223344',
        12
    ),
    (
        '0e18c152-f4dd-5bb2-95e2-57064624c585',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        '70b9d463-b701-51a2-8dfc-bc9cd4960320', -- Bubbelballs 2026-07-28
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Ugglan',
        'Lena Holm',
        '+46708889900',
        7
    ),
    (
        '5e81831a-479d-5741-b9b5-4edf2283f066',
        'a1b2c3d4-e5f6-4a90-abcd-ef1234567890',
        '380d1a87-c218-54de-9786-798274eb5886', -- Kåsan 2026-07-28
        'Anna Svensson',
        101,
        'Sjöscoutkåren Dansen',
        'Patrull Bävern',
        'Anna Svensson',
        '+46701234567',
        4
    ),
    (
        'e827972c-72f3-5ce1-b0f2-607adac98cad',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        'd62cbeb2-5c7b-5973-9d04-582e7c9ddfaa', -- Känslokartan 2026-07-28
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Patrull Ugglan',
        'Erik Johansson',
        '+46709876543',
        11
    ),
    (
        'cf6c4f9c-824e-5b34-ba71-4756ac1923f5',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        'd62cbeb2-5c7b-5973-9d04-582e7c9ddfaa', -- Känslokartan 2026-07-28
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Hela avdelningen',
        'Sara Öberg',
        '+46706667788',
        6
    ),
    (
        '5f9b8899-3b21-51d8-a4db-f681947f0024',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        'c03d4b03-d5bd-5390-bff7-67ee16b7504b', -- Brädspel 2026-07-28
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Hela avdelningen',
        'Petra Vikström',
        '+46702223344',
        8
    ),
    (
        'ee64a0ee-ec95-55be-a068-5e8d54b8e48a',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        'c03d4b03-d5bd-5390-bff7-67ee16b7504b', -- Brädspel 2026-07-28
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Räven',
        'Lena Holm',
        '+46708889900',
        3
    ),
    (
        'a1c0d01c-da22-5a3f-b1a3-aa0509994618',
        'd4e5f6a7-b8c9-4d23-9ef0-234567890123',
        'c647db8f-e85b-5c1d-baf6-1d32df54ca96', -- Cybersäkerhet med Unga forskare 2026-07-28
        'Johan Nilsson',
        303,
        'Scoutkåren Norrsken',
        'Patrull Räven',
        'Johan Nilsson',
        '+46703334455',
        5
    ),
    (
        '8dfa2e8f-acbe-5a17-85bb-7a17486bfe3e',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        'bfef2b35-d06e-5cf5-8e9e-bf1d12faa9bb', -- Pyssla med BRIS 2026-07-28
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Patrull Vargen',
        'Sara Öberg',
        '+46706667788',
        12
    ),
    (
        'e934db2a-6d92-5594-91b6-ea4f5387f930',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        'bfef2b35-d06e-5cf5-8e9e-bf1d12faa9bb', -- Pyssla med BRIS 2026-07-28
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Patrull Lodjuret',
        'Markus Test Funktionär',
        '+46700000002',
        7
    ),
    (
        '17373811-87e9-5e91-8bcf-3d65784e887e',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        '7cd36315-ac11-5140-8246-001bbf59a88e', -- Hantverksfokus: Paracord 2026-07-28
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Lodjuret',
        'Lena Holm',
        '+46708889900',
        9
    ),
    (
        '1b9fc4a7-2bf1-5716-b975-95519803089f',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        '7cd36315-ac11-5140-8246-001bbf59a88e', -- Hantverksfokus: Paracord 2026-07-28
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Bävern',
        'Markus Test Ledare',
        '+46700000003',
        4
    ),
    (
        'ba32519b-cb73-5a63-9e7c-fa7e82d6856c',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '7cd36315-ac11-5140-8246-001bbf59a88e', -- Hantverksfokus: Paracord 2026-07-28
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Ugglan',
        'Petra Vikström',
        '+46702223344',
        9
    ),
    (
        'eeb9222c-7093-561a-b929-246f607c1c54',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '7637587e-3fd0-56a5-a50f-3ac0dbe9782d', -- Knoprep 2026-07-28
        'Markus Test Planeringsfunktionär',
        NULL,
        NULL,
        'Patrull Bävern',
        'Markus Test Planeringsfunktionär',
        '+46700000001',
        6
    ),
    (
        '9b2d7ad4-6e4f-5c38-9e84-4900a5c336b6',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        '909fa919-6960-51dd-89a8-40c634e2402d', -- Tillsammans målning 2026-07-28
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Hela avdelningen',
        'Erik Johansson',
        '+46709876543',
        8
    ),
    (
        'ed9e7ed9-21ea-5539-9839-f64704c54ee6',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        '073013fb-eefa-5d10-8b29-9c9a2d5db212', -- Live musik på hubben 2026-07-28
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Hela avdelningen',
        'Markus Test Ledare',
        '+46700000003',
        10
    ),
    (
        '843068ee-e7f8-5e44-a9a5-81705122a32d',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '073013fb-eefa-5d10-8b29-9c9a2d5db212', -- Live musik på hubben 2026-07-28
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Räven',
        'Petra Vikström',
        '+46702223344',
        5
    ),
    (
        '20328636-c530-5be0-b38d-3cac9a0418a1',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        '073013fb-eefa-5d10-8b29-9c9a2d5db212', -- Live musik på hubben 2026-07-28
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Vargen',
        'Lena Holm',
        '+46708889900',
        10
    ),
    (
        'c5599223-8f33-5818-8e6d-655772a2d30e',
        'a1b2c3d4-e5f6-4a90-abcd-ef1234567890',
        '33bc3fdc-c019-5662-94cb-ba847f705003', -- Live musik på hubben 2026-07-28
        'Anna Svensson',
        101,
        'Sjöscoutkåren Dansen',
        'Patrull Räven',
        'Anna Svensson',
        '+46701234567',
        7
    ),
    (
        '5d7586fc-c104-502a-a2dc-41e0e40d9964',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        '08227519-604d-5213-b662-d0c9078d6a13', -- Bubbligt pyssel 2026-07-28
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Patrull Vargen',
        'Erik Johansson',
        '+46709876543',
        4
    ),
    (
        '9f1b3938-29ac-5bdf-8163-6e8584ce073e',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        '08227519-604d-5213-b662-d0c9078d6a13', -- Bubbligt pyssel 2026-07-28
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Patrull Lodjuret',
        'Sara Öberg',
        '+46706667788',
        9
    ),
    (
        '1e2ac062-12cc-5b3e-a45e-f2073406aca3',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        'bc01d960-a456-526f-8a09-2bb217741930', -- Bubbligt pyssel 2026-07-28
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Bävern',
        'Lena Holm',
        '+46708889900',
        6
    ),
    (
        'cd0e8eb4-4a87-5d34-94f6-9e1ebf4524be',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        'bc01d960-a456-526f-8a09-2bb217741930', -- Bubbligt pyssel 2026-07-28
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Ugglan',
        'Markus Test Ledare',
        '+46700000003',
        11
    ),
    (
        '34eacca0-4b2b-5e8c-8d00-99406815a5d7',
        'd4e5f6a7-b8c9-4d23-9ef0-234567890123',
        'e0dd114e-6e53-5a2e-b89a-9fc8501a83af', -- Halmpool 2026-07-28
        'Johan Nilsson',
        303,
        'Scoutkåren Norrsken',
        'Patrull Bävern',
        'Johan Nilsson',
        '+46703334455',
        8
    ),
    (
        'bac3f4a3-e7ea-5620-8873-af2f660ccf97',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        'a57d9076-80c7-57bf-9c21-7d47bf7b6990', -- Slankaruseller 2026-07-28
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Patrull Ugglan',
        'Sara Öberg',
        '+46706667788',
        5
    ),
    (
        '62c27e24-daf8-5135-afc1-316f37758257',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        'a57d9076-80c7-57bf-9c21-7d47bf7b6990', -- Slankaruseller 2026-07-28
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Hela avdelningen',
        'Markus Test Funktionär',
        '+46700000002',
        10
    ),
    (
        '14fa1236-e614-5bdd-bced-b2530c8c6f30',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        'c260a43e-e518-5808-9eea-6251e4dd2065', -- Hand the Ball 2026-07-28
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Hela avdelningen',
        'Lena Holm',
        '+46708889900',
        12
    ),
    (
        '54a1383f-1795-56cc-a9f4-f9c40d478c4e',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        'c260a43e-e518-5808-9eea-6251e4dd2065', -- Hand the Ball 2026-07-28
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Räven',
        'Markus Test Ledare',
        '+46700000003',
        7
    ),
    (
        '648369e3-f1c5-50b5-82a6-4bd0c0ff0b83',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        'e0585eff-e1cd-5169-93ee-6b224f613663', -- Knopmästerskap 2026-07-28
        'Markus Test Planeringsfunktionär',
        NULL,
        NULL,
        'Patrull Räven',
        'Markus Test Planeringsfunktionär',
        '+46700000001',
        9
    ),
    (
        'd9436cea-8fb3-5bf2-8ee3-1631ad14eabe',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        '276b27f4-f554-5dcc-b9fa-d384dae614fe', -- Knopmästerskap 2026-07-28
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Patrull Vargen',
        'Markus Test Funktionär',
        '+46700000002',
        6
    ),
    (
        'f3db7edd-e219-55c8-81b8-0e31cbf17cfc',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        '276b27f4-f554-5dcc-b9fa-d384dae614fe', -- Knopmästerskap 2026-07-28
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Patrull Lodjuret',
        'Erik Johansson',
        '+46709876543',
        11
    ),
    (
        '86dceda7-cffe-5977-a6c6-7ddcc22d749b',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        '90a098a3-be20-50a4-b5e7-5bfa026b5e77', -- Mekanisk tjur 2026-07-28
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Lodjuret',
        'Markus Test Ledare',
        '+46700000003',
        3
    ),
    (
        '5b34c168-514a-5c2c-8961-f6be592200ae',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '90a098a3-be20-50a4-b5e7-5bfa026b5e77', -- Mekanisk tjur 2026-07-28
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Bävern',
        'Petra Vikström',
        '+46702223344',
        8
    ),
    (
        '92703f6c-7a73-56b0-a533-cc73e493c1d2',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        '90a098a3-be20-50a4-b5e7-5bfa026b5e77', -- Mekanisk tjur 2026-07-28
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Ugglan',
        'Lena Holm',
        '+46708889900',
        3
    ),
    (
        'b4577fb4-b099-5656-95d2-a132e35b2211',
        'a1b2c3d4-e5f6-4a90-abcd-ef1234567890',
        'b24d3224-214e-5f79-885b-9cf85acb4841', -- Femkamp 2026-07-28
        'Anna Svensson',
        101,
        'Sjöscoutkåren Dansen',
        'Patrull Bävern',
        'Anna Svensson',
        '+46701234567',
        10
    ),
    (
        '594c61ce-864f-5a84-9dde-409bc14e40b5',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        '32569674-216f-531f-b365-64759879094f', -- Unga forskare 2026-07-28
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Hela avdelningen',
        'Sara Öberg',
        '+46706667788',
        12
    ),
    (
        '457376fc-017b-576f-8552-4fed51c45594',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '53774fe1-7833-5af2-9252-6c605c05ed8e', -- Trygghetsspelet med Treskablinoll 2026-07-28
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Hela avdelningen',
        'Petra Vikström',
        '+46702223344',
        4
    ),
    (
        '9ccadc8d-f76b-5c0c-b8bc-f5385ed8025d',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        '53774fe1-7833-5af2-9252-6c605c05ed8e', -- Trygghetsspelet med Treskablinoll 2026-07-28
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Räven',
        'Lena Holm',
        '+46708889900',
        9
    ),
    (
        '2323d6b1-c73c-5789-a819-8a26afd298dd',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        '53774fe1-7833-5af2-9252-6c605c05ed8e', -- Trygghetsspelet med Treskablinoll 2026-07-28
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Vargen',
        'Markus Test Ledare',
        '+46700000003',
        4
    ),
    (
        '81fe17c7-2444-5e0d-897f-edcf70648b45',
        'd4e5f6a7-b8c9-4d23-9ef0-234567890123',
        'a90af9f6-1ed7-5ca0-b78f-7881802014e7', -- Trygghetsspelet med Treskablinoll 2026-07-28
        'Johan Nilsson',
        303,
        'Scoutkåren Norrsken',
        'Patrull Räven',
        'Johan Nilsson',
        '+46703334455',
        11
    ),
    (
        'aa601cc8-b6b3-569e-b035-906176c6c37f',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        '1138b934-57c6-5be0-8a3c-c81e7f830f5d', -- Hand the Ball 2026-07-28
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Patrull Vargen',
        'Sara Öberg',
        '+46706667788',
        8
    ),
    (
        '8ede6da0-c023-513f-bd64-b319bfab214b',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        '1138b934-57c6-5be0-8a3c-c81e7f830f5d', -- Hand the Ball 2026-07-28
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Patrull Lodjuret',
        'Markus Test Funktionär',
        '+46700000002',
        3
    ),
    (
        '7183662e-728f-5876-a350-9ac0eafc11d9',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        '1248befb-2ca1-5015-af90-cf1fc04ee2b7', -- Uppdrag Självkänsla 2026-07-28
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Bävern',
        'Markus Test Ledare',
        '+46700000003',
        10
    ),
    (
        'cdb93b19-687b-56e8-b444-ee4017b9a1d3',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '1248befb-2ca1-5015-af90-cf1fc04ee2b7', -- Uppdrag Självkänsla 2026-07-28
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Ugglan',
        'Petra Vikström',
        '+46702223344',
        5
    ),
    (
        '1701862d-094b-5282-88e0-f34b17b72b44',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '10cd9866-3857-57cf-8aca-07ca36dffa21', -- Uppdrag Självkänsla 2026-07-28
        'Markus Test Planeringsfunktionär',
        NULL,
        NULL,
        'Patrull Bävern',
        'Markus Test Planeringsfunktionär',
        '+46700000001',
        12
    ),
    (
        '8afc79c2-c115-59cb-99f3-25dd95782bcf',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        '9d875675-f251-509e-92d5-4ccc462477a3', -- Äventyrare berättar: Henrik Wahlström 2026-07-28
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Patrull Ugglan',
        'Markus Test Funktionär',
        '+46700000002',
        9
    ),
    (
        '73edd32c-f1e4-50af-9cb8-b2aded646e6a',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        '9d875675-f251-509e-92d5-4ccc462477a3', -- Äventyrare berättar: Henrik Wahlström 2026-07-28
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Hela avdelningen',
        'Erik Johansson',
        '+46709876543',
        4
    ),
    (
        '85fbcfd5-c00f-5a5c-b0be-66d65249f570',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        '3b7a85a7-cf33-518a-8032-638a56a534db', -- Disco 2026-07-29
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Hela avdelningen',
        'Markus Test Ledare',
        '+46700000003',
        6
    ),
    (
        '1511b7a7-7410-5f9b-8186-6ac899cc9c94',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '3b7a85a7-cf33-518a-8032-638a56a534db', -- Disco 2026-07-29
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Räven',
        'Petra Vikström',
        '+46702223344',
        11
    ),
    (
        '399e09a7-b32d-54b0-a979-63988193ad12',
        'a1b2c3d4-e5f6-4a90-abcd-ef1234567890',
        'd35950e9-41a4-5468-ae1b-dafc93d3bf2f', -- Återträff Explorer Belt 2026-07-29
        'Anna Svensson',
        101,
        'Sjöscoutkåren Dansen',
        'Patrull Räven',
        'Anna Svensson',
        '+46701234567',
        3
    ),
    (
        '49bb789d-0058-5d74-9a74-db6ac853487c',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        '75ee78d9-01f9-5863-bae4-9be72bf86405', -- Återträff för Världscenter (volontär & funktionär) 2026-07-29
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Patrull Vargen',
        'Erik Johansson',
        '+46709876543',
        10
    ),
    (
        'f62e1c8d-2b3c-562c-9af8-ccf8d14a8a0f',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        '75ee78d9-01f9-5863-bae4-9be72bf86405', -- Återträff för Världscenter (volontär & funktionär) 2026-07-29
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Patrull Lodjuret',
        'Sara Öberg',
        '+46706667788',
        5
    ),
    (
        '26b6ce95-a50b-562e-85eb-88b5363f175f',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '6b81f3fa-9d1a-50a4-9e81-1f38f2de5c89', -- Återträff Världskonferenser 2026-07-29
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Lodjuret',
        'Petra Vikström',
        '+46702223344',
        7
    ),
    (
        'b0167eca-b70d-50b3-a9f3-a455a42168ea',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        '6b81f3fa-9d1a-50a4-9e81-1f38f2de5c89', -- Återträff Världskonferenser 2026-07-29
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Bävern',
        'Lena Holm',
        '+46708889900',
        12
    ),
    (
        '4c41a32e-f7d1-5dea-87f7-6fdc3948452f',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        '6b81f3fa-9d1a-50a4-9e81-1f38f2de5c89', -- Återträff Världskonferenser 2026-07-29
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Ugglan',
        'Markus Test Ledare',
        '+46700000003',
        7
    ),
    (
        '3be0816d-d85c-57d9-a3de-a122462e01d4',
        'd4e5f6a7-b8c9-4d23-9ef0-234567890123',
        '68194d4b-0e01-5e3f-93be-ae88cb1935a2', -- Återträff Europakonferenser 2026-07-29
        'Johan Nilsson',
        303,
        'Scoutkåren Norrsken',
        'Patrull Bävern',
        'Johan Nilsson',
        '+46703334455',
        4
    ),
    (
        '8941fbf4-8156-57f0-b8e8-7912422b7b9d',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        'a328db88-45f5-5d3d-ad31-da470eacac3c', -- Äventyrararsamtal 2026-07-29
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Hela avdelningen',
        'Markus Test Funktionär',
        '+46700000002',
        6
    ),
    (
        'a30171c9-0776-5dfb-aa37-c2df8ac2d62e',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        'fb72df50-3d9e-54d6-b0ff-40a16c6c4816', -- Utmanarsamtal 2026-07-29
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Hela avdelningen',
        'Lena Holm',
        '+46708889900',
        8
    ),
    (
        '1b91f06c-9d7c-5ae2-b4f1-68518ff1f3cc',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        'fb72df50-3d9e-54d6-b0ff-40a16c6c4816', -- Utmanarsamtal 2026-07-29
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Räven',
        'Markus Test Ledare',
        '+46700000003',
        3
    ),
    (
        '5bbc74dd-5c98-52f6-a90a-7d825c8f6600',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        'fb72df50-3d9e-54d6-b0ff-40a16c6c4816', -- Utmanarsamtal 2026-07-29
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Vargen',
        'Petra Vikström',
        '+46702223344',
        8
    ),
    (
        '6d966239-4eec-55cb-87ea-4cc7197fa930',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '2db5db3b-b409-5d32-bc8d-1f83bb0e32a4', -- Ledarsamtal 2026-07-29
        'Markus Test Planeringsfunktionär',
        NULL,
        NULL,
        'Patrull Räven',
        'Markus Test Planeringsfunktionär',
        '+46700000001',
        5
    ),
    (
        'd7f54659-17a3-5f48-a4db-1c8661e00f41',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        '94eb5680-d26f-5005-8b5f-abd600188086', -- Utbildarträff 2026-07-29
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Patrull Vargen',
        'Markus Test Funktionär',
        '+46700000002',
        12
    ),
    (
        'e00b7a51-1867-56e5-970a-029ff5c56ee8',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        '94eb5680-d26f-5005-8b5f-abd600188086', -- Utbildarträff 2026-07-29
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Patrull Lodjuret',
        'Erik Johansson',
        '+46709876543',
        7
    ),
    (
        '8524b1ca-02c3-5009-a913-3fafb83f8b07',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '8531aec5-e2af-570f-9862-f47ff334b16a', -- Nyfiken på Treklöver Gilwell 2026-07-29
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Bävern',
        'Petra Vikström',
        '+46702223344',
        4
    ),
    (
        '45c9514c-2ea4-5c97-bb9c-4a54462ec641',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        '8531aec5-e2af-570f-9862-f47ff334b16a', -- Nyfiken på Treklöver Gilwell 2026-07-29
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Ugglan',
        'Lena Holm',
        '+46708889900',
        9
    ),
    (
        '58ba355f-a373-5394-ba89-918f81fdb361',
        'a1b2c3d4-e5f6-4a90-abcd-ef1234567890',
        'b2fabd42-6e29-501e-9eed-8466de08d564', -- Treklöver Gilwell Reunion 2026-07-29
        'Anna Svensson',
        101,
        'Sjöscoutkåren Dansen',
        'Patrull Bävern',
        'Anna Svensson',
        '+46701234567',
        6
    ),
    (
        'b94ab28e-4dff-59de-a2c5-f884b19ec770',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        '50d8a427-22aa-5b2e-ab5a-75dec3f92898', -- Mingelträff för avdelningsledare till WSJ 2026-07-29
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Patrull Ugglan',
        'Erik Johansson',
        '+46709876543',
        3
    ),
    (
        'b484477e-def2-5514-a2d7-983fae60ba16',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        '50d8a427-22aa-5b2e-ab5a-75dec3f92898', -- Mingelträff för avdelningsledare till WSJ 2026-07-29
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Hela avdelningen',
        'Sara Öberg',
        '+46706667788',
        8
    ),
    (
        '45c5ea23-3863-525d-9c1f-964ec5729e4f',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '9f92c566-bb26-583a-a238-7664cbdb0be5', -- Upptäck dina värderingar: Testa på Värdebaserat ledarskap 2026-07-29
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Hela avdelningen',
        'Petra Vikström',
        '+46702223344',
        10
    ),
    (
        '3621fdba-bb2e-515f-a182-02c9c6a2cdd9',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        '9f92c566-bb26-583a-a238-7664cbdb0be5', -- Upptäck dina värderingar: Testa på Värdebaserat ledarskap 2026-07-29
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Räven',
        'Lena Holm',
        '+46708889900',
        5
    ),
    (
        'aed91b9d-60a0-59de-9fa5-71a4f23e3134',
        'd4e5f6a7-b8c9-4d23-9ef0-234567890123',
        'f0483b2a-3524-595e-9786-03b393d3ed2e', -- Frisk och fri 2026-07-29
        'Johan Nilsson',
        303,
        'Scoutkåren Norrsken',
        'Patrull Räven',
        'Johan Nilsson',
        '+46703334455',
        7
    ),
    (
        'f5de3d59-5ccd-5656-a4eb-696085fb62e1',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        'ee4826a1-73cd-5516-a7a3-4f92df69f119', -- Upp-och-ner med Henrik Wahlström 2026-07-29
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Patrull Vargen',
        'Sara Öberg',
        '+46706667788',
        4
    ),
    (
        'ceada3ec-51a9-583c-807c-c5ae09f9e0f7',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        'ee4826a1-73cd-5516-a7a3-4f92df69f119', -- Upp-och-ner med Henrik Wahlström 2026-07-29
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Patrull Lodjuret',
        'Markus Test Funktionär',
        '+46700000002',
        9
    ),
    (
        '2a6d2a75-55fe-5018-997f-bd6d386fe809',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        '64e66343-8863-595d-940e-382b0d6d67c0', -- Karaoke 2026-07-29
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Lodjuret',
        'Lena Holm',
        '+46708889900',
        11
    ),
    (
        'b645cda9-5d04-54ba-bf90-661bf170f55c',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        '64e66343-8863-595d-940e-382b0d6d67c0', -- Karaoke 2026-07-29
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Bävern',
        'Markus Test Ledare',
        '+46700000003',
        6
    ),
    (
        '8c99cd74-afdf-574b-aef2-d5042d7f6319',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '64e66343-8863-595d-940e-382b0d6d67c0', -- Karaoke 2026-07-29
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Ugglan',
        'Petra Vikström',
        '+46702223344',
        11
    ),
    (
        'fd1fae51-668e-54e9-ab75-b95d9dd0730e',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        'ac7bdad8-2c9a-5cd4-894b-1ac3b0f23ae1', -- Volleybollturnering 2026-07-29
        'Markus Test Planeringsfunktionär',
        NULL,
        NULL,
        'Patrull Bävern',
        'Markus Test Planeringsfunktionär',
        '+46700000001',
        8
    ),
    (
        'f8d81d76-0d51-5348-ba37-bbdd1d8b3e90',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        'b3a5cfde-4ef9-5798-a797-7d4da88bfc60', -- The HERDS 2026-07-29
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Hela avdelningen',
        'Erik Johansson',
        '+46709876543',
        10
    ),
    (
        '75d1a71b-b4ee-518d-8908-14662020d5cd',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        '81a0dbf5-a073-5253-9e66-6c6b2290e57d', -- The HERDS 2026-07-29
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Hela avdelningen',
        'Markus Test Ledare',
        '+46700000003',
        12
    ),
    (
        '0140d176-8624-59e7-985b-8f1e201cb6cd',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '81a0dbf5-a073-5253-9e66-6c6b2290e57d', -- The HERDS 2026-07-29
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Räven',
        'Petra Vikström',
        '+46702223344',
        7
    ),
    (
        '8339ebf7-614b-50ad-b07a-70a5d984a865',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        '81a0dbf5-a073-5253-9e66-6c6b2290e57d', -- The HERDS 2026-07-29
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Vargen',
        'Lena Holm',
        '+46708889900',
        12
    ),
    (
        '08f15f0d-60f4-5d00-8dd0-7bd5beb76a51',
        'a1b2c3d4-e5f6-4a90-abcd-ef1234567890',
        'e08132d4-7c5c-55de-8cba-9950dbc24b6f', -- The HERDS 2026-07-29
        'Anna Svensson',
        101,
        'Sjöscoutkåren Dansen',
        'Patrull Räven',
        'Anna Svensson',
        '+46701234567',
        45
    ),
    (
        '980f3a17-0a68-5d8e-bb5a-e46de5d9c8ce',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        'fa638d98-af78-5ba2-ab0d-93a97de9cd24', -- The HERDS 2026-07-29
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Patrull Vargen',
        'Erik Johansson',
        '+46709876543',
        6
    ),
    (
        '63de96b2-6976-5fd2-889a-72bc16a06b92',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        'fa638d98-af78-5ba2-ab0d-93a97de9cd24', -- The HERDS 2026-07-29
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Patrull Lodjuret',
        'Sara Öberg',
        '+46706667788',
        11
    ),
    (
        'd2162127-f427-56d1-bd4b-d28ee2b93bb3',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        '5f3cc3b0-092f-5ef5-b8e8-2ed141bbd017', -- Slappna av som Linné 2026-07-29
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Bävern',
        'Lena Holm',
        '+46708889900',
        8
    ),
    (
        '333d6234-1303-53e7-b424-2194b1c30f88',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        '5f3cc3b0-092f-5ef5-b8e8-2ed141bbd017', -- Slappna av som Linné 2026-07-29
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Ugglan',
        'Markus Test Ledare',
        '+46700000003',
        3
    ),
    (
        'ed453d34-acb9-5bc8-8545-d7b036f697f4',
        'd4e5f6a7-b8c9-4d23-9ef0-234567890123',
        '99d7c656-ce54-53b4-bb3f-d182f80be36d', -- Lägerbålspepp 2026-07-29
        'Johan Nilsson',
        303,
        'Scoutkåren Norrsken',
        'Patrull Bävern',
        'Johan Nilsson',
        '+46703334455',
        10
    ),
    (
        '7164f171-5df3-5021-94ca-73177daf11a0',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        '87f009ea-2475-5721-a86e-6c4558b5af89', -- Pyssla med BRIS 2026-07-29
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Patrull Ugglan',
        'Sara Öberg',
        '+46706667788',
        7
    ),
    (
        '9638e7ca-063e-561b-889b-5b43040eea7f',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        '87f009ea-2475-5721-a86e-6c4558b5af89', -- Pyssla med BRIS 2026-07-29
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Hela avdelningen',
        'Markus Test Funktionär',
        '+46700000002',
        12
    ),
    (
        'c2d26449-8e3a-5974-8614-a77ded707f1f',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        '79e1275a-b7f3-5681-91b4-76568de7d94b', -- Hantverksfokus: Banderoller/vimplar 2026-07-29
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Hela avdelningen',
        'Lena Holm',
        '+46708889900',
        4
    ),
    (
        'bfbe6b79-b697-56f9-968d-7518cfd84fd3',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        '79e1275a-b7f3-5681-91b4-76568de7d94b', -- Hantverksfokus: Banderoller/vimplar 2026-07-29
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Räven',
        'Markus Test Ledare',
        '+46700000003',
        9
    ),
    (
        'b077910d-0a8b-56df-89be-dcce4a176156',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        'dd628ebd-59b3-5ef9-89a4-9d33b9196bb8', -- Lägerbålsparad 2026-07-29
        'Markus Test Planeringsfunktionär',
        NULL,
        NULL,
        'Patrull Räven',
        'Markus Test Planeringsfunktionär',
        '+46700000001',
        11
    ),
    (
        '6c511cd9-a396-5723-8b3a-fabef57a5c4a',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        '41e6f075-60f6-5052-9207-113fab7b7fb2', -- Dagens lek: Kom alla djur 2026-07-29
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Patrull Vargen',
        'Markus Test Funktionär',
        '+46700000002',
        8
    ),
    (
        'beb0269c-0e84-5cd3-b7c0-d56ae2d4a721',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        '41e6f075-60f6-5052-9207-113fab7b7fb2', -- Dagens lek: Kom alla djur 2026-07-29
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Patrull Lodjuret',
        'Erik Johansson',
        '+46709876543',
        3
    ),
    (
        '43d1383d-d281-5ce3-aaaa-285e348d29d2',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        '3e76f15b-bcf7-5323-a2c4-754d743d0dc4', -- Mekanisk tjur 2026-07-29
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Lodjuret',
        'Markus Test Ledare',
        '+46700000003',
        5
    ),
    (
        'e406b597-994b-5583-8141-753f17ff8c90',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '3e76f15b-bcf7-5323-a2c4-754d743d0dc4', -- Mekanisk tjur 2026-07-29
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Bävern',
        'Petra Vikström',
        '+46702223344',
        10
    ),
    (
        'da091579-a983-5c8e-89f9-f52219ee6b7c',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        '3e76f15b-bcf7-5323-a2c4-754d743d0dc4', -- Mekanisk tjur 2026-07-29
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Ugglan',
        'Lena Holm',
        '+46708889900',
        5
    ),
    (
        '0e145d59-4dec-565e-8ca7-0e5d9b5af951',
        'a1b2c3d4-e5f6-4a90-abcd-ef1234567890',
        '8614f89b-7841-57b4-b93c-b200a05cf8ec', -- Brottning 2026-07-29
        'Anna Svensson',
        101,
        'Sjöscoutkåren Dansen',
        'Patrull Bävern',
        'Anna Svensson',
        '+46701234567',
        12
    ),
    (
        '1d225f9f-5324-5ff2-a3a0-89bc490a61a2',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        '81118bd1-7e58-5f07-8c45-6aa9d688b8de', -- Brottning 2026-07-29
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Hela avdelningen',
        'Sara Öberg',
        '+46706667788',
        4
    ),
    (
        '7740e15e-7418-54a7-b9a9-888c899110da',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '6abcca52-a574-56cd-9608-0d415bd1de32', -- Brottning 2026-07-29
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Hela avdelningen',
        'Petra Vikström',
        '+46702223344',
        40
    ),
    (
        'e3a85c31-2f5f-5e0e-ab54-edbf2c1bdc99',
        'd4e5f6a7-b8c9-4d23-9ef0-234567890123',
        '674e1c40-cfc0-5caa-962d-9036998468cf', -- Brottning 2026-07-29
        'Johan Nilsson',
        303,
        'Scoutkåren Norrsken',
        'Patrull Räven',
        'Johan Nilsson',
        '+46703334455',
        3
    ),
    (
        '805f78b5-cbba-5e20-9d1b-72781d4edf1f',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        'fbc1df7c-38e8-598c-a997-1d65a8e7c8da', -- Brottning 2026-07-29
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Patrull Vargen',
        'Sara Öberg',
        '+46706667788',
        10
    ),
    (
        'b2652c85-cfff-54c0-a2e4-7935b95985db',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        'fbc1df7c-38e8-598c-a997-1d65a8e7c8da', -- Brottning 2026-07-29
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Patrull Lodjuret',
        'Markus Test Funktionär',
        '+46700000002',
        5
    ),
    (
        'c2d159a8-84d0-5475-8c82-7df95a0fb4a9',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        '09a0eaa2-2077-5847-b154-01bb25840b93', -- Brottning 2026-07-29
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Bävern',
        'Markus Test Ledare',
        '+46700000003',
        12
    ),
    (
        '7e4c254c-f07b-590e-9c60-4020ba8cbc9d',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '09a0eaa2-2077-5847-b154-01bb25840b93', -- Brottning 2026-07-29
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Ugglan',
        'Petra Vikström',
        '+46702223344',
        7
    ),
    (
        'fb205733-8cd1-5d06-8d94-32fe5910934f',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '565af28c-9f99-54db-a882-011358f07ef6', -- Brottning 2026-07-29
        'Markus Test Planeringsfunktionär',
        NULL,
        NULL,
        'Patrull Bävern',
        'Markus Test Planeringsfunktionär',
        '+46700000001',
        4
    ),
    (
        '9cac4001-b230-5c55-8727-740d7b058eec',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        'd0b88c03-dc38-5da4-b2cf-a2512546d498', -- Brottning 2026-07-29
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Patrull Ugglan',
        'Markus Test Funktionär',
        '+46700000002',
        11
    ),
    (
        '74a57ca0-7feb-50b5-8e60-1a058f9971b6',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        'd0b88c03-dc38-5da4-b2cf-a2512546d498', -- Brottning 2026-07-29
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Hela avdelningen',
        'Erik Johansson',
        '+46709876543',
        6
    ),
    (
        'a2ee0fa9-75aa-5533-b4f0-83f03f46c232',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        '06e7491d-377b-5a3b-bfca-20755677c656', -- Godnattsaga 2026-07-29
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Hela avdelningen',
        'Markus Test Ledare',
        '+46700000003',
        8
    ),
    (
        'd3994d3a-a4a7-5de3-9b30-d332bff1ddf1',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '06e7491d-377b-5a3b-bfca-20755677c656', -- Godnattsaga 2026-07-29
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Räven',
        'Petra Vikström',
        '+46702223344',
        3
    ),
    (
        '0c8f2c55-6290-537b-8eab-902c8b7f2b56',
        'a1b2c3d4-e5f6-4a90-abcd-ef1234567890',
        '23bb111a-592f-59cb-85a9-6fdf62534a63', -- Sagostund 2026-07-29
        'Anna Svensson',
        101,
        'Sjöscoutkåren Dansen',
        'Patrull Räven',
        'Anna Svensson',
        '+46701234567',
        5
    ),
    (
        '601d2a83-8d29-5bc1-a201-d45c17956a66',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        '0b90f227-37ab-5e86-94da-e2863a470917', -- Kvällsbön 2026-07-29
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Patrull Vargen',
        'Erik Johansson',
        '+46709876543',
        12
    ),
    (
        '9ba9c781-e335-5348-97df-f79af08aca3b',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        '0b90f227-37ab-5e86-94da-e2863a470917', -- Kvällsbön 2026-07-29
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Patrull Lodjuret',
        'Sara Öberg',
        '+46706667788',
        7
    ),
    (
        '64f1520a-ce72-5b70-a26f-ace4cea8e4ce',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        'af6d8ec5-8916-5714-aa67-0fa9b9925312', -- Existens - Maria Hammar 2026-07-29
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Lodjuret',
        'Petra Vikström',
        '+46702223344',
        9
    ),
    (
        'a5a3af5c-5552-5bf9-88cf-cee28f316f32',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        'af6d8ec5-8916-5714-aa67-0fa9b9925312', -- Existens - Maria Hammar 2026-07-29
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Bävern',
        'Lena Holm',
        '+46708889900',
        4
    ),
    (
        '9ba01724-95d6-57e8-8b14-8cfd1e2996b3',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        'af6d8ec5-8916-5714-aa67-0fa9b9925312', -- Existens - Maria Hammar 2026-07-29
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Ugglan',
        'Markus Test Ledare',
        '+46700000003',
        9
    ),
    (
        'd7f3380b-789a-52b9-9138-e6d6ba51bf29',
        'd4e5f6a7-b8c9-4d23-9ef0-234567890123',
        '5cb3bcd2-f8c2-51d2-9261-f7ad3c0000c2', -- Bröllop - Vigsel 2026-07-29
        'Johan Nilsson',
        303,
        'Scoutkåren Norrsken',
        'Patrull Bävern',
        'Johan Nilsson',
        '+46703334455',
        6
    ),
    (
        '503a211c-50f3-5df3-b360-3baf6b9bdaf2',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        'e5fb15f7-1844-513d-943f-2450746da7f9', -- Poetry Slam 2026-07-29
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Hela avdelningen',
        'Markus Test Funktionär',
        '+46700000002',
        8
    ),
    (
        'f0200fb7-fcb1-5469-93d5-53828e40f0e8',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        '149851bf-369e-525c-8824-7597c22174f0', -- RUNCLUB 2026-07-29
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Hela avdelningen',
        'Lena Holm',
        '+46708889900',
        10
    ),
    (
        '8c8b2f71-6d48-52aa-8142-60a16868751f',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        '149851bf-369e-525c-8824-7597c22174f0', -- RUNCLUB 2026-07-29
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Räven',
        'Markus Test Ledare',
        '+46700000003',
        5
    ),
    (
        'c485a4c7-6a40-564f-8c01-b9bcb97264d7',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '149851bf-369e-525c-8824-7597c22174f0', -- RUNCLUB 2026-07-29
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Vargen',
        'Petra Vikström',
        '+46702223344',
        10
    ),
    (
        '13b97aba-c6ae-5fea-bb2c-d41d773ed53d',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        'cc04bc2c-ab64-5c1d-bb44-b975e0505e22', -- Frisk och Fri – Riksföreningen mot ätstörningar 2026-07-29
        'Markus Test Planeringsfunktionär',
        NULL,
        NULL,
        'Patrull Räven',
        'Markus Test Planeringsfunktionär',
        '+46700000001',
        7
    ),
    (
        '40f920ff-2439-5183-b1f3-a914e40271cb',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        '948a4833-877a-5b55-bfa5-45726bddd1a4', -- Välkomna internationella scoutgäster! 2026-07-29
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Patrull Vargen',
        'Markus Test Funktionär',
        '+46700000002',
        4
    ),
    (
        '6d3617bd-616e-5967-a3f6-33df615d2518',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        '948a4833-877a-5b55-bfa5-45726bddd1a4', -- Välkomna internationella scoutgäster! 2026-07-29
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Patrull Lodjuret',
        'Erik Johansson',
        '+46709876543',
        9
    ),
    (
        '2ba85594-2fd3-5486-9b36-c03a8a0ce46b',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        'e6895bcd-a245-5aa8-a3ca-218c70574d59', -- Lasse Berg 2026-07-29
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Bävern',
        'Petra Vikström',
        '+46702223344',
        6
    ),
    (
        '26f4f4b5-5edd-57ba-89ba-e9826d4417e9',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        'e6895bcd-a245-5aa8-a3ca-218c70574d59', -- Lasse Berg 2026-07-29
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Ugglan',
        'Lena Holm',
        '+46708889900',
        11
    ),
    (
        'e9d03344-22f5-5f17-9f54-a4f4813cf147',
        'a1b2c3d4-e5f6-4a90-abcd-ef1234567890',
        '48fa8c42-11fb-5cf3-b2b9-2d02fe281ec7', -- Bildstödspinne - anpassat ledarskap 2026-07-29
        'Anna Svensson',
        101,
        'Sjöscoutkåren Dansen',
        'Patrull Bävern',
        'Anna Svensson',
        '+46701234567',
        8
    ),
    (
        '87da4b1a-a39c-5f38-994d-e932815bc461',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        'b392ad26-4118-5fe3-999b-21e5a7733f7c', -- MOOT 2026-07-29
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Patrull Ugglan',
        'Erik Johansson',
        '+46709876543',
        5
    ),
    (
        '4ca36450-60b8-58e7-8b14-55876d597d71',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        'b392ad26-4118-5fe3-999b-21e5a7733f7c', -- MOOT 2026-07-29
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Hela avdelningen',
        'Sara Öberg',
        '+46706667788',
        10
    ),
    (
        '622125fe-ccdc-582c-b143-2bdec0b0f600',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '7cf2fff2-3b9d-5b29-89df-4877d83e7015', -- Linedance 2026-07-29
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Hela avdelningen',
        'Petra Vikström',
        '+46702223344',
        12
    ),
    (
        '58600fa8-6c91-5fe1-9dd1-8ffaa4143fb8',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        '7cf2fff2-3b9d-5b29-89df-4877d83e7015', -- Linedance 2026-07-29
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Räven',
        'Lena Holm',
        '+46708889900',
        7
    ),
    (
        '5c98de7e-da90-5ea6-bfe5-1ddf5e0008f6',
        'd4e5f6a7-b8c9-4d23-9ef0-234567890123',
        'acbcca83-ac2d-5fed-b550-f75ceb39dee8', -- Bugg 2026-07-29
        'Johan Nilsson',
        303,
        'Scoutkåren Norrsken',
        'Patrull Räven',
        'Johan Nilsson',
        '+46703334455',
        9
    ),
    (
        'eab37681-41b4-50a9-a3c2-5b7e9f90f71d',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        '5e4dc1bc-b8f9-5159-b8c9-9c883e895dc7', -- Treskablinoll: Trygga scouter - nytt materiaö med fokus på inegritet 2026-07-29
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Patrull Vargen',
        'Sara Öberg',
        '+46706667788',
        6
    ),
    (
        'cf8f8475-3e97-5495-ae47-c7a0f42a7bd0',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        '5e4dc1bc-b8f9-5159-b8c9-9c883e895dc7', -- Treskablinoll: Trygga scouter - nytt materiaö med fokus på inegritet 2026-07-29
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Patrull Lodjuret',
        'Markus Test Funktionär',
        '+46700000002',
        11
    ),
    (
        '2ee97fdb-84f3-554b-930c-c2a0892e61f3',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        '8af18041-d1ff-5d91-8f12-de04f9840d2a', -- Internationella Strategin 2026-07-29
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Lodjuret',
        'Lena Holm',
        '+46708889900',
        3
    ),
    (
        'b7bf02bb-7d71-5ca0-ad61-4dddddfc813e',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        '8af18041-d1ff-5d91-8f12-de04f9840d2a', -- Internationella Strategin 2026-07-29
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Bävern',
        'Markus Test Ledare',
        '+46700000003',
        8
    ),
    (
        '97ea6515-b99a-528d-b076-768557cd6952',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '8af18041-d1ff-5d91-8f12-de04f9840d2a', -- Internationella Strategin 2026-07-29
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Ugglan',
        'Petra Vikström',
        '+46702223344',
        3
    ),
    (
        'adc91384-7763-5148-89ce-a94ba00b04bb',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '18c52c53-1a29-537e-8525-90827cd5aa6b', -- Samtal mellan partiföreträdare och scouter om frågor som rör ungas framtid 2026-07-29
        'Markus Test Planeringsfunktionär',
        NULL,
        NULL,
        'Patrull Bävern',
        'Markus Test Planeringsfunktionär',
        '+46700000001',
        10
    ),
    (
        '286a5a03-7ca0-58b6-ad1f-4e70ea8306a2',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        'fa2cb116-9f29-59aa-a59b-597bec8a9dc5', -- Folkhögskolan workshop 2026-07-29
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Hela avdelningen',
        'Erik Johansson',
        '+46709876543',
        12
    ),
    (
        'bef7fd3f-72d8-5c2d-af3b-db743c5cdda5',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        'd98fdcad-156d-5086-898a-56c4e7d71dbf', -- Äventyrare berättar: Henrik Wahlström 2026-07-29
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Hela avdelningen',
        'Markus Test Ledare',
        '+46700000003',
        4
    ),
    (
        '6fdb011e-864e-57aa-bd1e-5cc3790128b2',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        'd98fdcad-156d-5086-898a-56c4e7d71dbf', -- Äventyrare berättar: Henrik Wahlström 2026-07-29
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Räven',
        'Petra Vikström',
        '+46702223344',
        9
    ),
    (
        '9c6d3539-116e-52ff-a373-c0b04e5340b9',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        'd98fdcad-156d-5086-898a-56c4e7d71dbf', -- Äventyrare berättar: Henrik Wahlström 2026-07-29
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Vargen',
        'Lena Holm',
        '+46708889900',
        4
    ),
    (
        'e47a618d-3219-5fc8-abb9-e06ce39170d5',
        'a1b2c3d4-e5f6-4a90-abcd-ef1234567890',
        'e9794be1-af8b-5270-80c2-1271b5490c99', -- Äventyrare berättar: Idun och Nikita 2026-07-29
        'Anna Svensson',
        101,
        'Sjöscoutkåren Dansen',
        'Patrull Räven',
        'Anna Svensson',
        '+46701234567',
        11
    ),
    (
        '4bed063f-a6b1-5894-8224-49ea8d7871a3',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        'c8dbd187-cbd0-5365-b090-6b21dd6b76a9', -- Unga forskare 2026-07-29
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Patrull Vargen',
        'Erik Johansson',
        '+46709876543',
        8
    ),
    (
        'da4e54f8-942c-5c75-be2b-a7f0495c003a',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        'c8dbd187-cbd0-5365-b090-6b21dd6b76a9', -- Unga forskare 2026-07-29
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Patrull Lodjuret',
        'Sara Öberg',
        '+46706667788',
        3
    ),
    (
        'e6a7f600-c848-5c4c-bb87-d2431fed1457',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        '2afce3cb-dd2d-57e5-bb4e-e171005f3914', -- Tillsammans i ledarteamet 2026-07-29
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Bävern',
        'Lena Holm',
        '+46708889900',
        10
    ),
    (
        'fbc3a3eb-2499-5fa3-a49f-01836d84eb04',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        '2afce3cb-dd2d-57e5-bb4e-e171005f3914', -- Tillsammans i ledarteamet 2026-07-29
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Ugglan',
        'Markus Test Ledare',
        '+46700000003',
        5
    ),
    (
        '800443d3-d0f6-5b8e-8798-7f6b9420caa7',
        'd4e5f6a7-b8c9-4d23-9ef0-234567890123',
        '61a36783-7dc3-510a-a53f-a2a2f24b35a0', -- Tim Bergling Foundation 2026-07-29
        'Johan Nilsson',
        303,
        'Scoutkåren Norrsken',
        'Patrull Bävern',
        'Johan Nilsson',
        '+46703334455',
        12
    ),
    (
        'af31d3c0-c448-5afc-9806-b22f4c544e39',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        'b519a75c-6406-5102-a671-4098ad6463ef', -- Upp- och nedmärket 2026-07-29
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Patrull Ugglan',
        'Sara Öberg',
        '+46706667788',
        9
    ),
    (
        '738d6ae5-2ce7-567b-81e8-6328e02db012',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        'b519a75c-6406-5102-a671-4098ad6463ef', -- Upp- och nedmärket 2026-07-29
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Hela avdelningen',
        'Markus Test Funktionär',
        '+46700000002',
        4
    ),
    (
        'c7c807ac-eea6-5cfd-a288-2f754c227ead',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        '83ea5ea3-fca8-5dad-80f8-cdedb0efc686', -- Upp- och nedmärket 2026-07-29
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Hela avdelningen',
        'Lena Holm',
        '+46708889900',
        6
    ),
    (
        '5ba47392-a1d8-541e-abc8-dd9d2c276dbc',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        '83ea5ea3-fca8-5dad-80f8-cdedb0efc686', -- Upp- och nedmärket 2026-07-29
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Räven',
        'Markus Test Ledare',
        '+46700000003',
        11
    ),
    (
        '696a9b4b-111b-5c28-8d11-49cc3fd2d65c',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '721a6e2d-6e74-5fbe-84d4-3172d6129d1d', -- Tim Bergling Foundation 2026-07-29
        'Markus Test Planeringsfunktionär',
        NULL,
        NULL,
        'Patrull Räven',
        'Markus Test Planeringsfunktionär',
        '+46700000001',
        3
    ),
    (
        'cf4389e1-a3a3-511e-bd81-01426d3e3bd6',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        'b8365222-0727-59cf-9fca-f8f256c3aa12', -- Uppdrag Självkänsla 2026-07-29
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Patrull Vargen',
        'Markus Test Funktionär',
        '+46700000002',
        10
    ),
    (
        'ec4eb7b1-17ca-5fdd-a8b4-76cedce2ae8d',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        'b8365222-0727-59cf-9fca-f8f256c3aa12', -- Uppdrag Självkänsla 2026-07-29
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Patrull Lodjuret',
        'Erik Johansson',
        '+46709876543',
        5
    ),
    (
        '64f5d0a4-262c-5e23-93f8-fcf52c85c569',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        '89f7a5d2-daae-52a4-8834-dc1167ab94db', -- Fladdermussafari 2026-07-29
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Lodjuret',
        'Markus Test Ledare',
        '+46700000003',
        30
    ),
    (
        'bcc92380-1d36-59ee-b775-d9d3fff2deec',
        'a1b2c3d4-e5f6-4a90-abcd-ef1234567890',
        '2bc55212-040d-57a5-8477-bdb7e8d3ece1', -- Frisk & Fri: Stärk din självkänsla - få mod att förändra 2026-07-29
        'Anna Svensson',
        101,
        'Sjöscoutkåren Dansen',
        'Patrull Bävern',
        'Anna Svensson',
        '+46701234567',
        4
    ),
    (
        '3afa6cc2-f3c4-54d3-a929-0cac4cd6213d',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        '9c64cbe6-27f8-5c79-af5e-7b903c19ed3e', -- Frisk & Fri: Hur förändrar vi snacket om kropp och utseende? 2026-07-29
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Hela avdelningen',
        'Sara Öberg',
        '+46706667788',
        6
    ),
    (
        '63a95301-9c09-51e9-b1b0-036d6961b8c2',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '20cb80f6-c27c-51d7-b750-61c62b629800', -- Influencern Henrik Wahlström: Från frustration till förändring 2026-07-29
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Hela avdelningen',
        'Petra Vikström',
        '+46702223344',
        8
    ),
    (
        '7579de1e-6f00-56ca-95fb-0ff9d0eb1d49',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        '20cb80f6-c27c-51d7-b750-61c62b629800', -- Influencern Henrik Wahlström: Från frustration till förändring 2026-07-29
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Räven',
        'Lena Holm',
        '+46708889900',
        3
    ),
    (
        '9ae210ba-2e81-52db-93d8-99a0c46f272c',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        '20cb80f6-c27c-51d7-b750-61c62b629800', -- Influencern Henrik Wahlström: Från frustration till förändring 2026-07-29
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Vargen',
        'Markus Test Ledare',
        '+46700000003',
        8
    ),
    (
        'f58eaa72-df97-5735-9173-ea83e81eae9c',
        'd4e5f6a7-b8c9-4d23-9ef0-234567890123',
        'ab29cf58-58fe-51cf-a826-eeefa2e8aead', -- Deep talk: Har AI gått för långt? 2026-07-29
        'Johan Nilsson',
        303,
        'Scoutkåren Norrsken',
        'Patrull Räven',
        'Johan Nilsson',
        '+46703334455',
        5
    ),
    (
        'd760f34c-13e3-54c6-808a-16340050f6fb',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        '13688a1f-f48c-5ea5-beae-a471c25e907e', -- Ledarskap som lyfter unga 2026-07-29
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Patrull Vargen',
        'Sara Öberg',
        '+46706667788',
        12
    ),
    (
        '5551937c-40b8-58a6-b715-c67195bae14d',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        '13688a1f-f48c-5ea5-beae-a471c25e907e', -- Ledarskap som lyfter unga 2026-07-29
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Patrull Lodjuret',
        'Markus Test Funktionär',
        '+46700000002',
        7
    ),
    (
        'c89e7c22-269f-5167-8caf-d8e0996f4327',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        'c7a54b16-96f0-5eef-a2b0-e3e9923e1175', -- Quiz 2026-07-29
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Bävern',
        'Markus Test Ledare',
        '+46700000003',
        4
    ),
    (
        'ab39450a-9782-54a6-a819-7ecfdae31bc3',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        'c7a54b16-96f0-5eef-a2b0-e3e9923e1175', -- Quiz 2026-07-29
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Ugglan',
        'Petra Vikström',
        '+46702223344',
        9
    ),
    (
        '55b6e0d7-9903-5fc9-9180-e42cc5d1a563',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '9a276b95-608c-5f7c-bea5-7be1881d6763', -- Stand up 2026-07-29
        'Markus Test Planeringsfunktionär',
        NULL,
        NULL,
        'Patrull Bävern',
        'Markus Test Planeringsfunktionär',
        '+46700000001',
        6
    ),
    (
        '557f4db8-5418-5375-b81c-b01bb301c3b9',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        'db77625e-6ea0-5bf9-a4ac-32a1d00f9b06', -- Quiz: Disney 2026-07-29
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Patrull Ugglan',
        'Markus Test Funktionär',
        '+46700000002',
        3
    ),
    (
        'ae4c18fb-52e8-5f6b-b3cc-46d0b4d8d87f',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        'db77625e-6ea0-5bf9-a4ac-32a1d00f9b06', -- Quiz: Disney 2026-07-29
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Hela avdelningen',
        'Erik Johansson',
        '+46709876543',
        8
    ),
    (
        'd57895e6-fcfb-5769-8b72-1b5fbdfd63d0',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        'cc767b60-2cea-594b-be67-4b1e5d0fa504', -- Quiz: Disney 2026-07-29
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Hela avdelningen',
        'Markus Test Ledare',
        '+46700000003',
        10
    ),
    (
        '749d4e03-f2e3-5d34-8a58-92c6a1a4bc42',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        'cc767b60-2cea-594b-be67-4b1e5d0fa504', -- Quiz: Disney 2026-07-29
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Räven',
        'Petra Vikström',
        '+46702223344',
        5
    ),
    (
        '7bf761ab-fa38-5ea4-89a1-03898de9714c',
        'a1b2c3d4-e5f6-4a90-abcd-ef1234567890',
        '8c4dccb0-861b-5dfc-bb28-31050a9aecde', -- Turnering: Settlers of Catan 2026-07-29
        'Anna Svensson',
        101,
        'Sjöscoutkåren Dansen',
        'Patrull Räven',
        'Anna Svensson',
        '+46701234567',
        7
    ),
    (
        'c8fb4e7c-209d-5831-a3c8-414f10563cb8',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        'dbf084f0-62ea-51d7-a1fe-07590a0b6094', -- Quiz: The Price is Right - Internationell scouting edition! 2026-07-29
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Patrull Vargen',
        'Erik Johansson',
        '+46709876543',
        4
    ),
    (
        '758b4d2a-70c9-5b85-a624-55430309ab0e',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        'dbf084f0-62ea-51d7-a1fe-07590a0b6094', -- Quiz: The Price is Right - Internationell scouting edition! 2026-07-29
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Patrull Lodjuret',
        'Sara Öberg',
        '+46706667788',
        9
    ),
    (
        '84d36363-9762-515a-8ee0-887a8b4a982e',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '871e861c-aea4-58bd-abe2-c3a61ed921d2', -- Pyssla bildstödspinne och prata om Anpassat ledarskap 2026-07-29
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Lodjuret',
        'Petra Vikström',
        '+46702223344',
        11
    ),
    (
        'e0d9f0f8-c778-5e02-8528-02e601e3e24d',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        '871e861c-aea4-58bd-abe2-c3a61ed921d2', -- Pyssla bildstödspinne och prata om Anpassat ledarskap 2026-07-29
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Bävern',
        'Lena Holm',
        '+46708889900',
        6
    ),
    (
        'c2f5aa84-73d3-5e64-91d8-008fa6dc4793',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        '871e861c-aea4-58bd-abe2-c3a61ed921d2', -- Pyssla bildstödspinne och prata om Anpassat ledarskap 2026-07-29
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Ugglan',
        'Markus Test Ledare',
        '+46700000003',
        11
    ),
    (
        'f719212d-c21a-5758-91fc-dab0be221c75',
        'd4e5f6a7-b8c9-4d23-9ef0-234567890123',
        'cfbcf58c-a1a0-58bc-a50a-17b43ea299e6', -- 29/7 – Lucia 🕯️ 2026-07-29
        'Johan Nilsson',
        303,
        'Scoutkåren Norrsken',
        'Patrull Bävern',
        'Johan Nilsson',
        '+46703334455',
        8
    ),
    (
        'e66403e6-7fff-5760-bd7d-b7d52d50f09f',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        'ba51e8fe-ce4e-5d9b-8439-08e85efbc63f', -- Lekaktiviteter 2026-07-29
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Hela avdelningen',
        'Markus Test Funktionär',
        '+46700000002',
        10
    ),
    (
        'd4bf1841-b795-5bb3-831e-bdc1ddfb3c3e',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        'c905335b-63d6-562a-81e6-0d5dbba2ff7e', -- Bubbelballs 2026-07-29
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Hela avdelningen',
        'Lena Holm',
        '+46708889900',
        12
    ),
    (
        '6a7ea5a0-669a-5994-890f-75bc8e231006',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        'c905335b-63d6-562a-81e6-0d5dbba2ff7e', -- Bubbelballs 2026-07-29
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Räven',
        'Markus Test Ledare',
        '+46700000003',
        7
    ),
    (
        '9cc2f0d6-3ea0-546c-b58b-3eccb1ff3930',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        'c905335b-63d6-562a-81e6-0d5dbba2ff7e', -- Bubbelballs 2026-07-29
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Vargen',
        'Petra Vikström',
        '+46702223344',
        12
    ),
    (
        'bf3d5734-f682-50e4-9e62-8a78baf1b707',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        'a03d0ba9-b294-5822-b584-67a47f10cbb1', -- Kåsan 2026-07-29
        'Markus Test Planeringsfunktionär',
        NULL,
        NULL,
        'Patrull Räven',
        'Markus Test Planeringsfunktionär',
        '+46700000001',
        9
    ),
    (
        'd86e032c-faf1-518f-9611-108a0e4d23fc',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        'd0d060b3-20aa-5183-823c-a3f9336a7f45', -- Känslokartan 2026-07-29
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Patrull Vargen',
        'Markus Test Funktionär',
        '+46700000002',
        6
    ),
    (
        '3ee55487-da46-578e-b509-b808d4965970',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        'd0d060b3-20aa-5183-823c-a3f9336a7f45', -- Känslokartan 2026-07-29
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Patrull Lodjuret',
        'Erik Johansson',
        '+46709876543',
        11
    ),
    (
        '6b425bf8-1524-5398-bd93-2778c95a3049',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '6ee37d9e-29be-55d0-8ea0-4a7455bb23cc', -- Brädspel 2026-07-29
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Bävern',
        'Petra Vikström',
        '+46702223344',
        8
    ),
    (
        '3343c0b1-5050-5e8d-b72e-b677aa2cb275',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        '6ee37d9e-29be-55d0-8ea0-4a7455bb23cc', -- Brädspel 2026-07-29
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Ugglan',
        'Lena Holm',
        '+46708889900',
        3
    ),
    (
        '0a9a2fb1-e2fd-5e5a-8c27-a60574c5cffc',
        'a1b2c3d4-e5f6-4a90-abcd-ef1234567890',
        '1cc1fda1-ef8c-5304-ba7e-22b5f717228a', -- Cybersäkerhet med Unga forskare 2026-07-29
        'Anna Svensson',
        101,
        'Sjöscoutkåren Dansen',
        'Patrull Bävern',
        'Anna Svensson',
        '+46701234567',
        10
    ),
    (
        'c8561bae-3da2-5d82-a95c-b88a4155a896',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        'bacd0080-f649-5395-9a58-c19a9d7c00f4', -- Knoprep 2026-07-29
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Patrull Ugglan',
        'Erik Johansson',
        '+46709876543',
        7
    ),
    (
        'adcf8819-23df-5951-8826-08d0b368f96e',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        'bacd0080-f649-5395-9a58-c19a9d7c00f4', -- Knoprep 2026-07-29
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Hela avdelningen',
        'Sara Öberg',
        '+46706667788',
        12
    ),
    (
        '3653d400-cdc8-51a1-994d-e76366f0fa7b',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '8dcfb880-4593-5c83-8dc3-39334cdadbed', -- Tillsammans målning 2026-07-29
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Hela avdelningen',
        'Petra Vikström',
        '+46702223344',
        4
    ),
    (
        '2f118c00-a842-5fb4-8ebc-ed7ee683dc2f',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        '8dcfb880-4593-5c83-8dc3-39334cdadbed', -- Tillsammans målning 2026-07-29
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Räven',
        'Lena Holm',
        '+46708889900',
        9
    ),
    (
        'e126b8c7-6ebc-5c4a-8de7-c4718ca4ffb5',
        'd4e5f6a7-b8c9-4d23-9ef0-234567890123',
        '42cd3402-33a3-53d7-9b8d-fcf95901bdf3', -- Halmpool 2026-07-29
        'Johan Nilsson',
        303,
        'Scoutkåren Norrsken',
        'Patrull Räven',
        'Johan Nilsson',
        '+46703334455',
        11
    ),
    (
        '9c5677e9-ec79-5017-9e6d-5e625c621df9',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        'e97b73f4-4d5a-5b18-a71f-680319e10eef', -- Slankaruseller 2026-07-29
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Patrull Vargen',
        'Sara Öberg',
        '+46706667788',
        8
    ),
    (
        '39df1696-7a4a-5b84-9dc4-56a835be2e10',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        'e97b73f4-4d5a-5b18-a71f-680319e10eef', -- Slankaruseller 2026-07-29
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Patrull Lodjuret',
        'Markus Test Funktionär',
        '+46700000002',
        3
    ),
    (
        '260191ed-e31c-5f28-9631-5d8e7851621e',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        '83b9605b-6d8f-56c2-8d06-aa8c4948f16d', -- Trygga möten fördjupning 2026-07-30
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Lodjuret',
        'Lena Holm',
        '+46708889900',
        5
    ),
    (
        '6a2bf5c0-3b7b-54c7-bc6e-0658c9424c62',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        '83b9605b-6d8f-56c2-8d06-aa8c4948f16d', -- Trygga möten fördjupning 2026-07-30
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Bävern',
        'Markus Test Ledare',
        '+46700000003',
        10
    ),
    (
        'bac7f8bb-068b-5b11-91b3-79dddda79f46',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '83b9605b-6d8f-56c2-8d06-aa8c4948f16d', -- Trygga möten fördjupning 2026-07-30
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Ugglan',
        'Petra Vikström',
        '+46702223344',
        5
    ),
    (
        '1bbb1968-ffcc-5adc-a4ba-a85da1cf5c36',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        'd1bef4f0-215c-5728-8360-a8bca5bab180', -- Bris 2026-07-30
        'Markus Test Planeringsfunktionär',
        NULL,
        NULL,
        'Patrull Bävern',
        'Markus Test Planeringsfunktionär',
        '+46700000001',
        12
    ),
    (
        'bdb2afcb-efc8-553f-a4ae-a4a3240d0e49',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        '87c58b36-0673-56b5-b1bd-3d6fdb36e9c6', -- Inspiration för kårer som vill åka utomlands 2026-07-30
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Hela avdelningen',
        'Erik Johansson',
        '+46709876543',
        4
    ),
    (
        '8967dccd-0757-5e33-a409-e7b8328928bc',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        'eead6a68-1f2b-53c5-bc82-f7b928d8beec', -- Folkhögskolan workshop 2026-07-30
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Hela avdelningen',
        'Markus Test Ledare',
        '+46700000003',
        6
    ),
    (
        '69d2be5a-68fa-5b75-96d4-59d2b85658ce',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        'eead6a68-1f2b-53c5-bc82-f7b928d8beec', -- Folkhögskolan workshop 2026-07-30
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Räven',
        'Petra Vikström',
        '+46702223344',
        11
    ),
    (
        'd0723046-60dd-5a17-8eb7-7a49c3c5f3b0',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        'eead6a68-1f2b-53c5-bc82-f7b928d8beec', -- Folkhögskolan workshop 2026-07-30
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Vargen',
        'Lena Holm',
        '+46708889900',
        6
    ),
    (
        'a0c83f2a-a169-5dd4-a0cb-460ffbb203d9',
        'a1b2c3d4-e5f6-4a90-abcd-ef1234567890',
        'c0ed0f3b-e9bd-5640-b053-ae5dab461678', -- Nyfiken på Leda Avdelning 2026-07-30
        'Anna Svensson',
        101,
        'Sjöscoutkåren Dansen',
        'Patrull Räven',
        'Anna Svensson',
        '+46701234567',
        3
    ),
    (
        '722c5137-d358-5c5a-93e5-5d0d56120b91',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        '40fab5e2-18ee-5a75-9b37-5dea0d33bc9f', -- Så jobbar en EU-korrespondent 2026-07-30
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Patrull Vargen',
        'Erik Johansson',
        '+46709876543',
        10
    ),
    (
        'd623193b-ced7-5c9c-bd83-7fc5717c0799',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        '40fab5e2-18ee-5a75-9b37-5dea0d33bc9f', -- Så jobbar en EU-korrespondent 2026-07-30
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Patrull Lodjuret',
        'Sara Öberg',
        '+46706667788',
        5
    ),
    (
        '03ddb1f6-9180-5740-8fb6-753bcf7e0fa7',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        '50cd5135-1530-5fb4-b27f-92d48428fd68', -- Nedmontera skiten - hur skapar vi den sämsta möjliga skolan? 2026-07-30
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Bävern',
        'Lena Holm',
        '+46708889900',
        12
    ),
    (
        'ebe4a9bd-f7d6-5a7f-8f3f-472b57d5bcbd',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        '50cd5135-1530-5fb4-b27f-92d48428fd68', -- Nedmontera skiten - hur skapar vi den sämsta möjliga skolan? 2026-07-30
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Ugglan',
        'Markus Test Ledare',
        '+46700000003',
        7
    ),
    (
        '00deccf2-b4c9-58ae-8aa7-9aaf29e87a5d',
        'd4e5f6a7-b8c9-4d23-9ef0-234567890123',
        '850fe1e2-1a9c-5f27-90ae-e1a188056e6d', -- Bris: Att aldrig riktigt räcka till 2026-07-30
        'Johan Nilsson',
        303,
        'Scoutkåren Norrsken',
        'Patrull Bävern',
        'Johan Nilsson',
        '+46703334455',
        4
    ),
    (
        '9cb548eb-5386-5d07-bcd8-8003cb887a65',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        'bd46e4be-166b-53aa-98d6-8c64f006b706', -- Rektorn på besök: Hur mycket kan du egentligen påverka? 2026-07-30
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Patrull Ugglan',
        'Sara Öberg',
        '+46706667788',
        11
    ),
    (
        '9fcf9d04-fe35-594e-8011-81452e22b6de',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        'bd46e4be-166b-53aa-98d6-8c64f006b706', -- Rektorn på besök: Hur mycket kan du egentligen påverka? 2026-07-30
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Hela avdelningen',
        'Markus Test Funktionär',
        '+46700000002',
        6
    ),
    (
        'e57aed4d-2c5b-5ce0-bb07-1daa343b624c',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        'd9b9d7fb-1634-5580-a328-495883dd5428', -- Deep talk - Rösta i Gnistan på tema! 2026-07-30
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Hela avdelningen',
        'Lena Holm',
        '+46708889900',
        8
    ),
    (
        '776f3226-e866-53e6-b856-f36cc387a430',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        'd9b9d7fb-1634-5580-a328-495883dd5428', -- Deep talk - Rösta i Gnistan på tema! 2026-07-30
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Räven',
        'Markus Test Ledare',
        '+46700000003',
        3
    ),
    (
        '7b03334b-d0e6-506c-af4a-76246b7fcc28',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '0aba5b9b-9b61-52a7-a218-967cf33484f3', -- Ledarskap som lyfter unga 2026-07-30
        'Markus Test Planeringsfunktionär',
        NULL,
        NULL,
        'Patrull Räven',
        'Markus Test Planeringsfunktionär',
        '+46700000001',
        5
    ),
    (
        '96737caf-88a6-5659-9490-54430e2ffedf',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        '8ddfc7e3-652f-5d35-8b4e-c2fd9f7b9bd4', -- Återträff WSJ - World Scout Jamboree 2026-07-30
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Patrull Vargen',
        'Markus Test Funktionär',
        '+46700000002',
        12
    ),
    (
        '65db2357-7424-55db-91da-d80fd2e67bcc',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        '8ddfc7e3-652f-5d35-8b4e-c2fd9f7b9bd4', -- Återträff WSJ - World Scout Jamboree 2026-07-30
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Patrull Lodjuret',
        'Erik Johansson',
        '+46709876543',
        7
    ),
    (
        '633b9807-90cc-5574-a168-9679a40f9360',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        'dd4bb037-abf9-5b64-a1e9-29cb8e45a1e0', -- Återträff World Scout Moot 2026-07-30
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Lodjuret',
        'Markus Test Ledare',
        '+46700000003',
        9
    ),
    (
        'd466e64f-3bbb-566f-a863-66353c2c58a0',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        'dd4bb037-abf9-5b64-a1e9-29cb8e45a1e0', -- Återträff World Scout Moot 2026-07-30
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Bävern',
        'Petra Vikström',
        '+46702223344',
        4
    ),
    (
        '3196b759-cad4-5197-babe-d186ce23b77d',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        'dd4bb037-abf9-5b64-a1e9-29cb8e45a1e0', -- Återträff World Scout Moot 2026-07-30
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Ugglan',
        'Lena Holm',
        '+46708889900',
        9
    ),
    (
        '91840c66-384e-529c-a909-a0f08caa3ca7',
        'a1b2c3d4-e5f6-4a90-abcd-ef1234567890',
        'd37bf222-75ed-58d0-b382-449875c35eef', -- Återträff Roverway 2026-07-30
        'Anna Svensson',
        101,
        'Sjöscoutkåren Dansen',
        'Patrull Bävern',
        'Anna Svensson',
        '+46701234567',
        6
    ),
    (
        'aba58666-ca3b-59dd-93a0-7e1066ac9be2',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        'a10bf42e-79ec-554a-8571-1ab2a3daea1c', -- Quiz 2026-07-30
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Hela avdelningen',
        'Sara Öberg',
        '+46706667788',
        8
    ),
    (
        '324024f9-6dde-514b-9000-529bd3ba8c6d',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        'a0675bed-8d38-5222-acbf-d9719f19296c', -- Open mic night 2026-07-30
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Hela avdelningen',
        'Petra Vikström',
        '+46702223344',
        10
    ),
    (
        '5a62bf3e-6359-5328-8ce0-84c2e2c320ee',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        'a0675bed-8d38-5222-acbf-d9719f19296c', -- Open mic night 2026-07-30
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Räven',
        'Lena Holm',
        '+46708889900',
        5
    ),
    (
        'cb82bb88-ee88-5c50-bbd9-319a6a9b1f0e',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        'a0675bed-8d38-5222-acbf-d9719f19296c', -- Open mic night 2026-07-30
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Vargen',
        'Markus Test Ledare',
        '+46700000003',
        10
    ),
    (
        '399f0a97-fd5d-5dc7-b274-9f40a2670419',
        'd4e5f6a7-b8c9-4d23-9ef0-234567890123',
        '5c34806a-8cb6-5ac8-939c-e50667086f37', -- Internationella gruppen tar över ledarhänget 2026-07-30
        'Johan Nilsson',
        303,
        'Scoutkåren Norrsken',
        'Patrull Räven',
        'Johan Nilsson',
        '+46703334455',
        7
    ),
    (
        'e2b43f34-6d63-55d0-990d-761a601de858',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        'a7510cf9-536f-54bc-ac43-4e43d4623d67', -- Upptäckarsamtal 2026-07-30
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Patrull Vargen',
        'Sara Öberg',
        '+46706667788',
        4
    ),
    (
        '8e51e7a8-7f72-5f76-8ff2-b31378a00a93',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        'a7510cf9-536f-54bc-ac43-4e43d4623d67', -- Upptäckarsamtal 2026-07-30
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Patrull Lodjuret',
        'Markus Test Funktionär',
        '+46700000002',
        9
    ),
    (
        '182fa8bd-1bc5-53e4-ab07-b93ec13a4603',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        '065b36e9-4127-5495-9ae3-16cb4a177ef9', -- Familjescoutsamtal 2026-07-30
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Bävern',
        'Markus Test Ledare',
        '+46700000003',
        6
    ),
    (
        '6b58e382-0237-5721-a68e-4671ba34dd06',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '065b36e9-4127-5495-9ae3-16cb4a177ef9', -- Familjescoutsamtal 2026-07-30
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Ugglan',
        'Petra Vikström',
        '+46702223344',
        11
    ),
    (
        'ffa92ac9-467d-5b76-bd76-b9de05ff63c4',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '87018007-7156-5f30-ab55-74746d60ac5c', -- Spårarsamtal 2026-07-30
        'Markus Test Planeringsfunktionär',
        NULL,
        NULL,
        'Patrull Bävern',
        'Markus Test Planeringsfunktionär',
        '+46700000001',
        8
    ),
    (
        '3e3e0a06-df22-5c73-916d-76a7955ea5dc',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        'e8f319ab-0851-520a-966e-b3fe63beef09', -- NSF 2026-07-30
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Patrull Ugglan',
        'Markus Test Funktionär',
        '+46700000002',
        5
    ),
    (
        '49ce8e64-3743-5ae5-832e-c97c2825e654',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        'e8f319ab-0851-520a-966e-b3fe63beef09', -- NSF 2026-07-30
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Hela avdelningen',
        'Erik Johansson',
        '+46709876543',
        10
    ),
    (
        '6eb391a4-08e7-57bd-9d17-afa37fccfb9b',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        '665b6442-3ee5-5064-b728-e07a4f1b8e26', -- Speedfriending 2026-07-30
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Hela avdelningen',
        'Markus Test Ledare',
        '+46700000003',
        12
    ),
    (
        '057d08ab-fa40-5469-be56-a85eeebf2b3f',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '665b6442-3ee5-5064-b728-e07a4f1b8e26', -- Speedfriending 2026-07-30
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Räven',
        'Petra Vikström',
        '+46702223344',
        7
    ),
    (
        'fe4ec3fa-241d-54c0-9879-3a709f49a8ed',
        'a1b2c3d4-e5f6-4a90-abcd-ef1234567890',
        '7669c2c7-538f-5d2b-bc09-3e562a4768de', -- Bildstödspinne - anpassat ledarskap 2026-07-30
        'Anna Svensson',
        101,
        'Sjöscoutkåren Dansen',
        'Patrull Räven',
        'Anna Svensson',
        '+46701234567',
        9
    ),
    (
        'fbc57f0b-a1cd-5598-a835-9b54a21e6824',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        'cc405766-4f25-5b04-9020-90b1693609e3', -- Bachata 2026-07-30
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Patrull Vargen',
        'Erik Johansson',
        '+46709876543',
        6
    ),
    (
        '1cfe8d96-2e53-5201-928d-991c810684c4',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        'cc405766-4f25-5b04-9020-90b1693609e3', -- Bachata 2026-07-30
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Patrull Lodjuret',
        'Sara Öberg',
        '+46706667788',
        11
    ),
    (
        '126cd35f-cb5c-5c6e-85a3-502da4cc1a4a',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        'd600ef16-5a89-51fb-8169-5336aeddc7d4', -- Bachata 2026-07-30
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Lodjuret',
        'Petra Vikström',
        '+46702223344',
        3
    ),
    (
        '0b44bd8e-e91a-5da1-8f2d-7144544b2274',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        'd600ef16-5a89-51fb-8169-5336aeddc7d4', -- Bachata 2026-07-30
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Bävern',
        'Lena Holm',
        '+46708889900',
        8
    ),
    (
        'e80b5a92-d7a0-577d-b60a-2810cf1a873e',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        'd600ef16-5a89-51fb-8169-5336aeddc7d4', -- Bachata 2026-07-30
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Ugglan',
        'Markus Test Ledare',
        '+46700000003',
        3
    ),
    (
        'f49f02c7-e626-5b7d-bc84-62001e8fb7b1',
        'd4e5f6a7-b8c9-4d23-9ef0-234567890123',
        '6afa33b0-c429-56f1-a7fc-f49f33d2ea7c', -- Bachata 2026-07-30
        'Johan Nilsson',
        303,
        'Scoutkåren Norrsken',
        'Patrull Bävern',
        'Johan Nilsson',
        '+46703334455',
        10
    ),
    (
        '7a03d842-e436-5451-adcc-462c72374c3d',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        'aff5625b-7de7-5246-938d-ae374c0a9416', -- Klubb Fiesta med DJ Måns 2026-07-30
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Hela avdelningen',
        'Markus Test Funktionär',
        '+46700000002',
        12
    ),
    (
        '6f7ff3bf-8b64-53aa-bb00-2c52fb64685c',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        'fd514c87-6151-50b6-9a28-893a562b7eff', -- Volleybollturnering 2026-07-30
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Hela avdelningen',
        'Lena Holm',
        '+46708889900',
        4
    ),
    (
        '6f95dd21-6274-5db0-bd43-66ec2f31e945',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        'fd514c87-6151-50b6-9a28-893a562b7eff', -- Volleybollturnering 2026-07-30
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Räven',
        'Markus Test Ledare',
        '+46700000003',
        9
    ),
    (
        'de0bac1b-06ae-5fe3-9b97-e4bf70a236e3',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        'fd514c87-6151-50b6-9a28-893a562b7eff', -- Volleybollturnering 2026-07-30
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Vargen',
        'Petra Vikström',
        '+46702223344',
        4
    ),
    (
        'a92a32d4-7437-553e-bd8b-73c21197842f',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '5cf47cfb-215d-5a70-87e1-4944ff4ccd4f', -- Hur bygger vi fred lokalt när det pågår krig globalt? 2026-07-30
        'Markus Test Planeringsfunktionär',
        NULL,
        NULL,
        'Patrull Räven',
        'Markus Test Planeringsfunktionär',
        '+46700000001',
        11
    ),
    (
        'c32af991-f6fe-5af4-89f0-d7bc8fdb8f31',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        '6ea2063b-d301-5d16-975c-9c7f2f176408', -- På Spåret: Internationell scouting edition! 2026-07-30
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Patrull Vargen',
        'Markus Test Funktionär',
        '+46700000002',
        8
    ),
    (
        '16024e0f-2de9-58cd-94a2-134a5846cc1d',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        '6ea2063b-d301-5d16-975c-9c7f2f176408', -- På Spåret: Internationell scouting edition! 2026-07-30
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Patrull Lodjuret',
        'Erik Johansson',
        '+46709876543',
        3
    ),
    (
        'f82ec6e5-0bab-53c5-814e-7b9ef420f8fe',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '8cac8501-366f-5eee-aa6f-5fc63a9a7193', -- Karaoke 2026-07-30
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Bävern',
        'Petra Vikström',
        '+46702223344',
        10
    ),
    (
        '19f5e231-876d-5394-a4d5-0d2135f144d1',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        '8cac8501-366f-5eee-aa6f-5fc63a9a7193', -- Karaoke 2026-07-30
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Ugglan',
        'Lena Holm',
        '+46708889900',
        5
    ),
    (
        'a1fbef13-3ce7-5337-af12-045e0c4e8d62',
        'a1b2c3d4-e5f6-4a90-abcd-ef1234567890',
        '412c2b5e-f6dc-5d65-a818-d3a96117c17b', -- Från Frankrike till Korea - på cykel! 2026-07-30
        'Anna Svensson',
        101,
        'Sjöscoutkåren Dansen',
        'Patrull Bävern',
        'Anna Svensson',
        '+46701234567',
        12
    ),
    (
        '8cb84613-55ba-54af-a9c4-baf6588963a1',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        'dc2e47e1-fea3-530a-84eb-5fc7d262767b', -- Tänk Till 2026-07-30
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Patrull Ugglan',
        'Erik Johansson',
        '+46709876543',
        9
    ),
    (
        'c6396be4-ae64-55be-a376-f568dd2a25cf',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        'dc2e47e1-fea3-530a-84eb-5fc7d262767b', -- Tänk Till 2026-07-30
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Hela avdelningen',
        'Sara Öberg',
        '+46706667788',
        4
    ),
    (
        '0c19f811-87a8-565d-a74e-f85c3e7bd076',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        'f094215c-5ef9-5b56-9750-7b111e25a829', -- Tänk Till 2026-07-30
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Hela avdelningen',
        'Petra Vikström',
        '+46702223344',
        6
    ),
    (
        '90da6101-f1a6-5a97-8ad9-ca1becb36bc0',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        'f094215c-5ef9-5b56-9750-7b111e25a829', -- Tänk Till 2026-07-30
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Räven',
        'Lena Holm',
        '+46708889900',
        11
    ),
    (
        '18f3b009-dd82-57fc-ab93-9876aff696e0',
        'd4e5f6a7-b8c9-4d23-9ef0-234567890123',
        '334d85ed-df16-5008-ab29-ca9dbb8d8ff6', -- Tänk Till 2026-07-30
        'Johan Nilsson',
        303,
        'Scoutkåren Norrsken',
        'Patrull Räven',
        'Johan Nilsson',
        '+46703334455',
        3
    ),
    (
        'aa0f2f9c-bfe5-5ca0-81f4-8d5c34f4f8e8',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        '622589b9-9fcc-52ca-b040-cb4d7040bbf9', -- Tänk Till 2026-07-30
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Patrull Vargen',
        'Sara Öberg',
        '+46706667788',
        10
    ),
    (
        '4964a57d-4d7b-56ff-acc7-caa0a6581df1',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        '622589b9-9fcc-52ca-b040-cb4d7040bbf9', -- Tänk Till 2026-07-30
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Patrull Lodjuret',
        'Markus Test Funktionär',
        '+46700000002',
        5
    ),
    (
        '9caf913f-63d9-53d8-bf5b-8bbe23cd0124',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        'c95183ae-acc1-5ccb-8e68-f934c65cd991', -- Sagostund 2026-07-30
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Lodjuret',
        'Lena Holm',
        '+46708889900',
        7
    ),
    (
        '98a88647-4c52-583d-b707-2d4f7fa5a4f4',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        'c95183ae-acc1-5ccb-8e68-f934c65cd991', -- Sagostund 2026-07-30
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Bävern',
        'Markus Test Ledare',
        '+46700000003',
        12
    ),
    (
        'aa1b355e-a405-57fb-90f7-c0263426e05e',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        'c95183ae-acc1-5ccb-8e68-f934c65cd991', -- Sagostund 2026-07-30
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Ugglan',
        'Petra Vikström',
        '+46702223344',
        7
    ),
    (
        '3a77440d-6a71-5b04-a81d-53c621101d5b',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '6e4327ee-465a-5f57-a90f-5f76b2fb1404', -- Kvällsbön 2026-07-30
        'Markus Test Planeringsfunktionär',
        NULL,
        NULL,
        'Patrull Bävern',
        'Markus Test Planeringsfunktionär',
        '+46700000001',
        4
    ),
    (
        '37f7e7ad-b528-59df-b238-c64db343cd8d',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        'd527706a-43de-5b01-8a48-7a2f819268f5', -- Meningen med mig 2026-07-30
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Hela avdelningen',
        'Erik Johansson',
        '+46709876543',
        6
    ),
    (
        '11645943-ebca-5624-8015-0ddea79a4938',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        '2b21ad81-9fec-5838-ae82-7ea271f22d5a', -- Meningen med mig 2026-07-30
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Hela avdelningen',
        'Markus Test Ledare',
        '+46700000003',
        8
    ),
    (
        'd564a252-1fb6-5d91-ae81-753afb77e575',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '2b21ad81-9fec-5838-ae82-7ea271f22d5a', -- Meningen med mig 2026-07-30
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Räven',
        'Petra Vikström',
        '+46702223344',
        3
    ),
    (
        '155a6e63-c872-545c-9980-dae4a6d71b14',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        '2b21ad81-9fec-5838-ae82-7ea271f22d5a', -- Meningen med mig 2026-07-30
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Vargen',
        'Lena Holm',
        '+46708889900',
        8
    ),
    (
        '18b0570d-e0df-5651-9a63-3af574365c0f',
        'a1b2c3d4-e5f6-4a90-abcd-ef1234567890',
        '612fb54e-a192-5dc0-97f7-81ab2bd663c3', -- Nattvard 2026-07-30
        'Anna Svensson',
        101,
        'Sjöscoutkåren Dansen',
        'Patrull Räven',
        'Anna Svensson',
        '+46701234567',
        5
    ),
    (
        'bd3cdfc6-91b5-5ce2-b322-190495432dad',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        'e424cff2-00d1-5e23-8ac4-16fbfedea28e', -- 30/7 – Julafton 🎄 2026-07-30
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Patrull Vargen',
        'Erik Johansson',
        '+46709876543',
        12
    ),
    (
        '7ecd4a9c-200e-5cbd-ac76-d583a9bf5205',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        'e424cff2-00d1-5e23-8ac4-16fbfedea28e', -- 30/7 – Julafton 🎄 2026-07-30
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Patrull Lodjuret',
        'Sara Öberg',
        '+46706667788',
        7
    ),
    (
        'dd277d3e-02d6-59d9-bb57-6073cdfc47d2',
        'd4e5f6a7-b8c9-4d23-9ef0-234567890123',
        '676d645a-e77b-5c21-b5ef-0081eedc0a6d', -- The HERDS 2026-07-30
        'Johan Nilsson',
        303,
        'Scoutkåren Norrsken',
        'Patrull Bävern',
        'Johan Nilsson',
        '+46703334455',
        6
    ),
    (
        'd10a1dac-67ab-57a9-b095-a5e2d76b4ad2',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        'c7a25147-3684-56f2-bdad-81bca271f881', -- The HERDS 2026-07-30
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Patrull Ugglan',
        'Sara Öberg',
        '+46706667788',
        3
    ),
    (
        '539cb794-3f67-586a-87bc-1fee1caef315',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        'c7a25147-3684-56f2-bdad-81bca271f881', -- The HERDS 2026-07-30
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Hela avdelningen',
        'Markus Test Funktionär',
        '+46700000002',
        8
    ),
    (
        'edd560bc-b762-5151-82a7-a31462069df9',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        'adca7be8-03cb-5e68-8fac-288b5599278e', -- The HERDS 2026-07-30
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Hela avdelningen',
        'Lena Holm',
        '+46708889900',
        10
    ),
    (
        '7d3705b9-88a5-5de7-9e9a-8c82e4920f68',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        'adca7be8-03cb-5e68-8fac-288b5599278e', -- The HERDS 2026-07-30
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Räven',
        'Markus Test Ledare',
        '+46700000003',
        5
    ),
    (
        '926a15c8-8c2d-5172-ab85-f7908891a98a',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '166dfba6-7cdf-5ae4-8a27-755d8617fee2', -- Kubbturnering Deltävling 1 2026-07-30
        'Markus Test Planeringsfunktionär',
        NULL,
        NULL,
        'Patrull Räven',
        'Markus Test Planeringsfunktionär',
        '+46700000001',
        7
    ),
    (
        '698d1a8b-2cee-524f-89f6-0397802253c4',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        '559b3071-76a4-58af-ab71-a6a26ac68f33', -- Dagens lek 2026-07-30
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Patrull Vargen',
        'Markus Test Funktionär',
        '+46700000002',
        4
    ),
    (
        'b2e4129d-cf95-5d4b-866b-7a3ba30df135',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        '559b3071-76a4-58af-ab71-a6a26ac68f33', -- Dagens lek 2026-07-30
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Patrull Lodjuret',
        'Erik Johansson',
        '+46709876543',
        9
    ),
    (
        '53d742ae-9b37-5b18-a4c2-07f643d1c868',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        'ab9f3402-0a49-5b62-aa5f-c4a7e999280a', -- Fotbollstunering Scouter vs. Ledare 2026-07-30
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Lodjuret',
        'Markus Test Ledare',
        '+46700000003',
        11
    ),
    (
        'e4c723ed-d7cb-5373-ba0d-53610869e4a7',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        'ab9f3402-0a49-5b62-aa5f-c4a7e999280a', -- Fotbollstunering Scouter vs. Ledare 2026-07-30
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Bävern',
        'Petra Vikström',
        '+46702223344',
        6
    ),
    (
        '8c3bc67b-77e2-526a-b320-7b56f9bc109b',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        'ab9f3402-0a49-5b62-aa5f-c4a7e999280a', -- Fotbollstunering Scouter vs. Ledare 2026-07-30
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Ugglan',
        'Lena Holm',
        '+46708889900',
        11
    ),
    (
        '88846bce-c0c6-55d5-8e84-fdc1bb6484fc',
        'a1b2c3d4-e5f6-4a90-abcd-ef1234567890',
        '3680858d-b5f5-5e65-b13f-32de1be4ca3a', -- Fotbollstunering Scouter vs. Ledare 2026-07-30
        'Anna Svensson',
        101,
        'Sjöscoutkåren Dansen',
        'Patrull Bävern',
        'Anna Svensson',
        '+46701234567',
        8
    ),
    (
        'dd92bf61-5496-5243-9b41-04e27712c082',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        '67672c4c-9045-5d48-9b85-2ffa9b1038b1', -- Pyjamasparty med talangshow 2026-07-30
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Hela avdelningen',
        'Sara Öberg',
        '+46706667788',
        10
    ),
    (
        '920c1b40-de1b-5f07-aec8-6ebac82466c1',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        'bc750540-bfb8-51e9-b775-cd44556f9b51', -- Lekaktiviteter 2026-07-30
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Hela avdelningen',
        'Petra Vikström',
        '+46702223344',
        12
    ),
    (
        'af1c8e12-ec95-5319-889a-6ee1011b577b',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        'bc750540-bfb8-51e9-b775-cd44556f9b51', -- Lekaktiviteter 2026-07-30
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Räven',
        'Lena Holm',
        '+46708889900',
        7
    ),
    (
        '19995b02-c003-5b30-bcc1-0c84b19c1a4e',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        'bc750540-bfb8-51e9-b775-cd44556f9b51', -- Lekaktiviteter 2026-07-30
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Vargen',
        'Markus Test Ledare',
        '+46700000003',
        12
    ),
    (
        'ca7cf5bb-80bd-5f68-8373-7b0b6559fc5e',
        'd4e5f6a7-b8c9-4d23-9ef0-234567890123',
        'ef7dd134-f00c-5de5-9e0a-af5d5a5046c4', -- Bubbelballs 2026-07-30
        'Johan Nilsson',
        303,
        'Scoutkåren Norrsken',
        'Patrull Räven',
        'Johan Nilsson',
        '+46703334455',
        9
    ),
    (
        '9614d82f-12dd-5d38-aa8e-ef371df2838d',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        'aa88395b-2f90-5410-96cb-322ff85d63dc', -- Godnattsaga 2026-07-30
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Patrull Vargen',
        'Sara Öberg',
        '+46706667788',
        6
    ),
    (
        'ab954e76-c1e0-5bf8-989e-a44b49936937',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        'aa88395b-2f90-5410-96cb-322ff85d63dc', -- Godnattsaga 2026-07-30
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Patrull Lodjuret',
        'Markus Test Funktionär',
        '+46700000002',
        11
    ),
    (
        '9df416d3-b0db-5275-9160-c8980608b4e5',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        '12c6fd16-9b78-59f8-a2e1-f0ed8d0aeb56', -- Kåsan 2026-07-30
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Bävern',
        'Markus Test Ledare',
        '+46700000003',
        8
    ),
    (
        'fff398ba-3d00-5d76-8610-66523f638b84',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '12c6fd16-9b78-59f8-a2e1-f0ed8d0aeb56', -- Kåsan 2026-07-30
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Ugglan',
        'Petra Vikström',
        '+46702223344',
        3
    ),
    (
        'b2ee2e4a-0947-5413-8b21-6a5c5cd3c9dd',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        'd9c943cd-395c-505d-9f89-65d47a0333c5', -- Känslokartan 2026-07-30
        'Markus Test Planeringsfunktionär',
        NULL,
        NULL,
        'Patrull Bävern',
        'Markus Test Planeringsfunktionär',
        '+46700000001',
        10
    ),
    (
        '03e74701-5dd3-53b5-b5af-dfae9399a939',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        '5c917534-d54b-5837-ae81-b654d1f01b64', -- Brädspel 2026-07-30
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Patrull Ugglan',
        'Markus Test Funktionär',
        '+46700000002',
        7
    ),
    (
        'bde81e15-5c06-5e7a-aa4f-14c2b84ae2db',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        '5c917534-d54b-5837-ae81-b654d1f01b64', -- Brädspel 2026-07-30
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Hela avdelningen',
        'Erik Johansson',
        '+46709876543',
        12
    ),
    (
        'bb593870-5220-54cd-8a0b-30ed714e8fb7',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        '99182452-c33e-5e68-b734-587562646d7e', -- Cybersäkerhet med Unga forskare 2026-07-30
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Hela avdelningen',
        'Markus Test Ledare',
        '+46700000003',
        4
    ),
    (
        '47c29380-a4ba-5ba8-bf2c-6c87bdede23a',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '99182452-c33e-5e68-b734-587562646d7e', -- Cybersäkerhet med Unga forskare 2026-07-30
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Räven',
        'Petra Vikström',
        '+46702223344',
        9
    ),
    (
        '986a804e-3c98-53b0-bf85-8971fae9fae0',
        'a1b2c3d4-e5f6-4a90-abcd-ef1234567890',
        'b93325a4-6e22-5fab-b75b-e8b89a9b75f6', -- Hantverk fokus: Pärldjur 2026-07-30
        'Anna Svensson',
        101,
        'Sjöscoutkåren Dansen',
        'Patrull Räven',
        'Anna Svensson',
        '+46701234567',
        11
    ),
    (
        'b41bf588-8344-53c1-bb9b-7294ffebb47c',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        '6e717191-08a7-5cba-9ae1-b0032d0e6b24', -- The HERDS 2026-07-30
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Patrull Vargen',
        'Erik Johansson',
        '+46709876543',
        8
    ),
    (
        'eae37d23-8b01-5e4f-8e79-7bb5da93437b',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        '6e717191-08a7-5cba-9ae1-b0032d0e6b24', -- The HERDS 2026-07-30
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Patrull Lodjuret',
        'Sara Öberg',
        '+46706667788',
        3
    ),
    (
        'd14a201f-5aa2-5f50-92c3-ac81523d7570',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        'ef47c6f3-c408-5dc8-9042-048ea1309885', -- The HERDS 2026-07-30
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Lodjuret',
        'Petra Vikström',
        '+46702223344',
        5
    ),
    (
        '10fa0460-aad2-5e55-b01a-facca15e8358',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        'ef47c6f3-c408-5dc8-9042-048ea1309885', -- The HERDS 2026-07-30
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Bävern',
        'Lena Holm',
        '+46708889900',
        10
    ),
    (
        'fdb431d4-7ba1-5429-9fbc-6ea80309b04f',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        'ef47c6f3-c408-5dc8-9042-048ea1309885', -- The HERDS 2026-07-30
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Ugglan',
        'Markus Test Ledare',
        '+46700000003',
        5
    ),
    (
        '7454a02f-7677-5bc4-ab63-7d3dc292727b',
        'd4e5f6a7-b8c9-4d23-9ef0-234567890123',
        'd9d22c58-034e-5412-b8a1-e8cccd4548f4', -- Knoprep 2026-07-30
        'Johan Nilsson',
        303,
        'Scoutkåren Norrsken',
        'Patrull Bävern',
        'Johan Nilsson',
        '+46703334455',
        12
    ),
    (
        '87b997f4-ebeb-54db-896f-14feb5c5b3a5',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        '27b97594-1254-59e9-b12c-64f108bef1ee', -- Tillsammans målning 2026-07-30
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Hela avdelningen',
        'Markus Test Funktionär',
        '+46700000002',
        4
    ),
    (
        '4785e1f3-59f1-51cb-8812-6c49da9babd2',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        '48a0110c-7d2a-520f-9a21-324131dff26b', -- Halmpool 2026-07-30
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Hela avdelningen',
        'Lena Holm',
        '+46708889900',
        6
    ),
    (
        '79eadc70-0bde-5d15-ba41-af5b8d7d9294',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        '48a0110c-7d2a-520f-9a21-324131dff26b', -- Halmpool 2026-07-30
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Räven',
        'Markus Test Ledare',
        '+46700000003',
        11
    ),
    (
        'b1dae7d8-41c9-5020-b659-9e0458306d53',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '48a0110c-7d2a-520f-9a21-324131dff26b', -- Halmpool 2026-07-30
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Vargen',
        'Petra Vikström',
        '+46702223344',
        6
    ),
    (
        'c433d734-831a-5a31-9f7b-28f5a14d25cc',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '792f0166-12f7-5bd8-87f7-ea87887712c2', -- Slankaruseller 2026-07-30
        'Markus Test Planeringsfunktionär',
        NULL,
        NULL,
        'Patrull Räven',
        'Markus Test Planeringsfunktionär',
        '+46700000001',
        3
    ),
    (
        'e85be69d-4475-520b-9e04-090fee08f7aa',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        '22ca920e-e797-507e-9d46-f947b1665fd5', -- Bris 2026-07-30
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Patrull Vargen',
        'Markus Test Funktionär',
        '+46700000002',
        10
    ),
    (
        'f5870f76-0669-58b3-8283-fa35d80d6115',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        '22ca920e-e797-507e-9d46-f947b1665fd5', -- Bris 2026-07-30
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Patrull Lodjuret',
        'Erik Johansson',
        '+46709876543',
        5
    ),
    (
        'ce63ea57-f9c0-56e1-bb10-917d9f2cdec8',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        'b64b42bd-0008-53c5-ac1b-6a1789fd0f4d', -- Fladdermussafari 2026-07-30
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Bävern',
        'Petra Vikström',
        '+46702223344',
        12
    ),
    (
        '600f66f0-4270-5f0e-bd4d-ae505ef745b9',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        'b64b42bd-0008-53c5-ac1b-6a1789fd0f4d', -- Fladdermussafari 2026-07-30
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Ugglan',
        'Lena Holm',
        '+46708889900',
        7
    ),
    (
        '636c55e6-8fcb-5784-8089-d9a9ac9af18a',
        'a1b2c3d4-e5f6-4a90-abcd-ef1234567890',
        '5c1f2d3f-4e11-5563-9a62-dfcb0e5812a7', -- Tim Bergling Foundation 2026-07-30
        'Anna Svensson',
        101,
        'Sjöscoutkåren Dansen',
        'Patrull Bävern',
        'Anna Svensson',
        '+46701234567',
        4
    ),
    (
        '123c6a00-7878-5487-aa7c-0e682c010ea2',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        '946e9644-2b60-5546-95f2-fbf87dd7abe5', -- Upptäck dina värderingar 2026-07-30
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Patrull Ugglan',
        'Erik Johansson',
        '+46709876543',
        11
    ),
    (
        '2a17da6d-c413-5fc7-93e2-d053edefec3e',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        '946e9644-2b60-5546-95f2-fbf87dd7abe5', -- Upptäck dina värderingar 2026-07-30
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Hela avdelningen',
        'Sara Öberg',
        '+46706667788',
        6
    ),
    (
        'f78550cc-bed1-5b10-800f-9d0f89762b89',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '17965407-ce84-5770-8ace-166f630e29b7', -- Upptäck dina värderingar 2026-07-30
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Hela avdelningen',
        'Petra Vikström',
        '+46702223344',
        8
    ),
    (
        '33cde018-9d68-5fd6-b803-bd0ca277f4ba',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        '17965407-ce84-5770-8ace-166f630e29b7', -- Upptäck dina värderingar 2026-07-30
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Räven',
        'Lena Holm',
        '+46708889900',
        3
    ),
    (
        '8e9f49dd-0d09-55e8-adda-bc598db79776',
        'd4e5f6a7-b8c9-4d23-9ef0-234567890123',
        'c69e0ddf-996e-511b-ad7e-ec63fa23a452', -- Tim Bergling Foundation 2026-07-30
        'Johan Nilsson',
        303,
        'Scoutkåren Norrsken',
        'Patrull Räven',
        'Johan Nilsson',
        '+46703334455',
        5
    ),
    (
        '65ab58ad-05b9-5219-9f3a-489be651e253',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        '04bf5403-9b6f-5520-ab76-1db67a0910a7', -- Mekanisk tjur 2026-07-30
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Patrull Vargen',
        'Sara Öberg',
        '+46706667788',
        12
    ),
    (
        '6357d39a-71bc-5e76-8f03-51fd82fc35ad',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        '04bf5403-9b6f-5520-ab76-1db67a0910a7', -- Mekanisk tjur 2026-07-30
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Patrull Lodjuret',
        'Markus Test Funktionär',
        '+46700000002',
        7
    ),
    (
        '077a5fb8-78eb-5313-b6dd-2ac32841d958',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        '2bb67276-c2c3-5801-9269-0e5f9bc02750', -- Schackturnering 2026-07-30
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Lodjuret',
        'Lena Holm',
        '+46708889900',
        9
    ),
    (
        'bf3f8514-b49f-5b29-afb5-2ca024324776',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        '2bb67276-c2c3-5801-9269-0e5f9bc02750', -- Schackturnering 2026-07-30
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Bävern',
        'Markus Test Ledare',
        '+46700000003',
        4
    ),
    (
        '469fe4ba-0240-5826-ac80-2f6bda336a0c',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '2bb67276-c2c3-5801-9269-0e5f9bc02750', -- Schackturnering 2026-07-30
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Ugglan',
        'Petra Vikström',
        '+46702223344',
        9
    ),
    (
        '4ca57a62-1ee7-5b90-ad3e-6465155df023',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '17a5e3c0-2db6-5642-87a5-debf030d9532', -- Unga forskare 2026-07-30
        'Markus Test Planeringsfunktionär',
        NULL,
        NULL,
        'Patrull Bävern',
        'Markus Test Planeringsfunktionär',
        '+46700000001',
        6
    ),
    (
        '12cbdbab-bce8-5c2b-aa26-681721067695',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        'eb07b45f-6915-5bfc-8215-4a095fe75559', -- Äventyrare berättar: Per Eriksson 2026-07-30
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Hela avdelningen',
        'Erik Johansson',
        '+46709876543',
        8
    ),
    (
        'cb54f4d0-8373-5d24-bee0-cefec1e35f1c',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        'd58d93ed-0497-5eae-88c7-dc12c6d7d8b0', -- Psykologisk beredskap 2026-07-30
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Hela avdelningen',
        'Markus Test Ledare',
        '+46700000003',
        10
    ),
    (
        'c318fe4d-36a0-50c7-96cc-a7ab38ea8b11',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        'd58d93ed-0497-5eae-88c7-dc12c6d7d8b0', -- Psykologisk beredskap 2026-07-30
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Räven',
        'Petra Vikström',
        '+46702223344',
        5
    ),
    (
        '9c89a0c5-96d5-5a9d-87ff-24987d73ce09',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        'd58d93ed-0497-5eae-88c7-dc12c6d7d8b0', -- Psykologisk beredskap 2026-07-30
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Vargen',
        'Lena Holm',
        '+46708889900',
        10
    ),
    (
        '1f1a40e8-ff43-5715-b660-abbf83bb28d7',
        'a1b2c3d4-e5f6-4a90-abcd-ef1234567890',
        '711ba1cb-05ba-55a3-8dfb-b7816e9dd83a', -- Psykologisk beredskap 2026-07-30
        'Anna Svensson',
        101,
        'Sjöscoutkåren Dansen',
        'Patrull Räven',
        'Anna Svensson',
        '+46701234567',
        7
    ),
    (
        '0ca1d70a-b81b-5c8f-884c-8800907a9bd8',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        'dc9d3482-8f0e-5604-9c68-268e7d3bc8b7', -- Äventyrare berättar: Per Eriksson 2026-07-30
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Patrull Vargen',
        'Erik Johansson',
        '+46709876543',
        4
    ),
    (
        'ba223ef6-fc05-5830-97bc-da0fc646620a',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        'dc9d3482-8f0e-5604-9c68-268e7d3bc8b7', -- Äventyrare berättar: Per Eriksson 2026-07-30
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Patrull Lodjuret',
        'Sara Öberg',
        '+46706667788',
        9
    ),
    (
        '97e3b95c-ed53-5ab1-a592-7cea5248591f',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        '0f4635a3-e4b9-50f8-831a-3c9e5c029489', -- Quiz 2026-07-30
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Bävern',
        'Lena Holm',
        '+46708889900',
        6
    ),
    (
        'b7f0eb92-18eb-5230-b4cf-de3473e5611f',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        '0f4635a3-e4b9-50f8-831a-3c9e5c029489', -- Quiz 2026-07-30
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Ugglan',
        'Markus Test Ledare',
        '+46700000003',
        11
    ),
    (
        '3c5a9864-295e-56cd-a7f1-e227339c3441',
        'd4e5f6a7-b8c9-4d23-9ef0-234567890123',
        'd42b0964-c9cb-5274-b101-f1888cd74205', -- Konsert 2026-07-30
        'Johan Nilsson',
        303,
        'Scoutkåren Norrsken',
        'Patrull Bävern',
        'Johan Nilsson',
        '+46703334455',
        8
    ),
    (
        'ecebe7a1-e14a-5296-823d-c81d68108e8a',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        '4b0500f1-ff30-55d8-a816-c70b07f5712d', -- BRIS 2026-07-30
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Patrull Ugglan',
        'Sara Öberg',
        '+46706667788',
        5
    ),
    (
        '32569cf3-3ada-5d54-bbbf-4f6ea7e86024',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        '4b0500f1-ff30-55d8-a816-c70b07f5712d', -- BRIS 2026-07-30
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Hela avdelningen',
        'Markus Test Funktionär',
        '+46700000002',
        10
    ),
    (
        '18a03472-a77e-5163-920e-d9deda63525f',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        '1d675389-6002-5fb2-805d-e9d8b27c2a33', -- BRIS 2026-07-30
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Hela avdelningen',
        'Lena Holm',
        '+46708889900',
        12
    ),
    (
        '31c56884-d2e3-5464-8eb2-b1cffd0d50c0',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        '1d675389-6002-5fb2-805d-e9d8b27c2a33', -- BRIS 2026-07-30
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Räven',
        'Markus Test Ledare',
        '+46700000003',
        7
    ),
    (
        '29993ecf-9a66-5723-8df9-144b827c922b',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '302d98fa-3b21-556e-9e94-7071c56b6644', -- Ledarsamtal 2026-07-31
        'Markus Test Planeringsfunktionär',
        NULL,
        NULL,
        'Patrull Räven',
        'Markus Test Planeringsfunktionär',
        '+46700000001',
        9
    ),
    (
        'bc293619-eb97-510e-be16-e92751b8f559',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        '786cf71f-5cd2-546b-848f-c8129a41999e', -- Utmanarsamtal 2026-07-31
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Patrull Vargen',
        'Markus Test Funktionär',
        '+46700000002',
        6
    ),
    (
        '0ecd2c4d-29ce-5727-840b-68e3f3a20b14',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        '786cf71f-5cd2-546b-848f-c8129a41999e', -- Utmanarsamtal 2026-07-31
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Patrull Lodjuret',
        'Erik Johansson',
        '+46709876543',
        11
    ),
    (
        '7c28ee31-a630-53d7-b25d-3439fe0265d4',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        'ee755d6d-b4d4-55dc-b588-594ba22a6ca0', -- Leda Scouting - Spork del 2 2026-07-31
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Lodjuret',
        'Markus Test Ledare',
        '+46700000003',
        3
    ),
    (
        '27bba04c-c603-5860-90b6-dc98b675a144',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        'ee755d6d-b4d4-55dc-b588-594ba22a6ca0', -- Leda Scouting - Spork del 2 2026-07-31
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Bävern',
        'Petra Vikström',
        '+46702223344',
        8
    ),
    (
        '5d0e205f-47f8-53fc-a96e-a97916283dd4',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        'ee755d6d-b4d4-55dc-b588-594ba22a6ca0', -- Leda Scouting - Spork del 2 2026-07-31
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Ugglan',
        'Lena Holm',
        '+46708889900',
        3
    ),
    (
        '5eb8ceb0-d99b-5d5a-a9b3-16b59930ecb3',
        'a1b2c3d4-e5f6-4a90-abcd-ef1234567890',
        'c57b3ec0-93ce-592d-97b2-d10dbb3de18e', -- Leda Scouting - Tamoj del 2 2026-07-31
        'Anna Svensson',
        101,
        'Sjöscoutkåren Dansen',
        'Patrull Bävern',
        'Anna Svensson',
        '+46701234567',
        10
    ),
    (
        '84bd8163-96b9-528c-ace9-80c8d7182c5d',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        '103efe17-3808-53af-9baf-d7ef382f5066', -- Nyfiken på att bli utbildare 2026-07-31
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Hela avdelningen',
        'Sara Öberg',
        '+46706667788',
        12
    ),
    (
        'e5e7319f-2f81-52d4-8d28-a6323468a8f4',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '5587614e-ce37-5a99-947e-151d62df8ad5', -- 31/7 – Nyår 🎉 2026-07-31
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Hela avdelningen',
        'Petra Vikström',
        '+46702223344',
        4
    ),
    (
        '744b60c9-aebd-5eb7-80c3-2dfb6ecc7f59',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        '5587614e-ce37-5a99-947e-151d62df8ad5', -- 31/7 – Nyår 🎉 2026-07-31
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Räven',
        'Lena Holm',
        '+46708889900',
        9
    ),
    (
        '2e19677d-9f97-5767-972d-78a1f6917a63',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        '5587614e-ce37-5a99-947e-151d62df8ad5', -- 31/7 – Nyår 🎉 2026-07-31
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Vargen',
        'Markus Test Ledare',
        '+46700000003',
        4
    ),
    (
        '9ea4a713-2d71-56a7-ae0f-63ebec09f496',
        'd4e5f6a7-b8c9-4d23-9ef0-234567890123',
        'bc5bfb95-4108-5cfe-abe2-fc0dc97ac7c1', -- Vad kan du göra för EU, och vad kan EU göra för dig? 2026-07-31
        'Johan Nilsson',
        303,
        'Scoutkåren Norrsken',
        'Patrull Räven',
        'Johan Nilsson',
        '+46703334455',
        11
    ),
    (
        'bc773c43-a311-5ea0-890a-91a0857c1257',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        '47c75641-ce75-54bb-bd02-57155d686087', -- Gör Scouterna skillnad på riktigt? 2026-07-31
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Patrull Vargen',
        'Sara Öberg',
        '+46706667788',
        8
    ),
    (
        'f79c3d46-7052-51be-8c48-1a17c151ee07',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        '47c75641-ce75-54bb-bd02-57155d686087', -- Gör Scouterna skillnad på riktigt? 2026-07-31
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Patrull Lodjuret',
        'Markus Test Funktionär',
        '+46700000002',
        3
    ),
    (
        'a7ec5087-ab1e-5f30-bc0f-ef52f872aab9',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        'bebef6a8-9539-5202-ac37-687a1a8d9b8a', -- Bli arrangemangsledare! 2026-07-31
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Bävern',
        'Markus Test Ledare',
        '+46700000003',
        10
    ),
    (
        'f7945af9-cfa7-5c57-a6cf-dc8a28f24232',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        'bebef6a8-9539-5202-ac37-687a1a8d9b8a', -- Bli arrangemangsledare! 2026-07-31
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Ugglan',
        'Petra Vikström',
        '+46702223344',
        5
    ),
    (
        '0443c59f-fae2-546f-a781-f7e3c817aa42',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        'e493f60f-1af6-5f49-adc4-6eede44b7888', -- Konsert: Old Carters Memory Lane 2026-07-31
        'Markus Test Planeringsfunktionär',
        NULL,
        NULL,
        'Patrull Bävern',
        'Markus Test Planeringsfunktionär',
        '+46700000001',
        12
    ),
    (
        '00c6f5b1-285c-527a-b5d3-02eeb7961395',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        'a3c5bce6-1715-5ce5-a0fb-06ddb9b1b8b5', -- The HERDS 2026-07-31
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Patrull Ugglan',
        'Markus Test Funktionär',
        '+46700000002',
        9
    ),
    (
        '2be4edea-f82a-5c9f-92e0-e4f80baa82e1',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        'a3c5bce6-1715-5ce5-a0fb-06ddb9b1b8b5', -- The HERDS 2026-07-31
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Hela avdelningen',
        'Erik Johansson',
        '+46709876543',
        4
    ),
    (
        'e5248657-fcf6-5b5e-bfa4-24b077de2df0',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        '452e7dd7-692d-5fe1-b5f6-31b4a7872e3f', -- The HERDS 2026-07-31
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Hela avdelningen',
        'Markus Test Ledare',
        '+46700000003',
        6
    ),
    (
        '9b795d1f-972a-5023-bb20-3a52bc1751ed',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '452e7dd7-692d-5fe1-b5f6-31b4a7872e3f', -- The HERDS 2026-07-31
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Räven',
        'Petra Vikström',
        '+46702223344',
        11
    ),
    (
        'c3917c46-1a3d-5726-8a51-1fe3764bcb63',
        'a1b2c3d4-e5f6-4a90-abcd-ef1234567890',
        'b6cc8ecb-95f6-5450-852e-d471f8854c7d', -- Vattenlek 2026-07-31
        'Anna Svensson',
        101,
        'Sjöscoutkåren Dansen',
        'Patrull Räven',
        'Anna Svensson',
        '+46701234567',
        3
    ),
    (
        '4e7cae66-faa1-5390-9987-3ead0dd4e1ce',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        '25defd23-b680-599a-b2a5-9e98deef7c63', -- Hantverk fokus: Kompisminnen 2026-07-31
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Patrull Vargen',
        'Erik Johansson',
        '+46709876543',
        10
    ),
    (
        '67a4bb55-eebf-5d53-a86d-49c0707d61b6',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        '25defd23-b680-599a-b2a5-9e98deef7c63', -- Hantverk fokus: Kompisminnen 2026-07-31
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Patrull Lodjuret',
        'Sara Öberg',
        '+46706667788',
        5
    ),
    (
        'e45d326c-422c-5c2c-a00b-748437ebda0c',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '92fefeed-9bcb-5bd2-b16b-ea5796468fc6', -- Mekanisk tjur 2026-07-31
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Lodjuret',
        'Petra Vikström',
        '+46702223344',
        7
    ),
    (
        'f8681e47-61b4-503c-a51a-6b34c52615c0',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        '92fefeed-9bcb-5bd2-b16b-ea5796468fc6', -- Mekanisk tjur 2026-07-31
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Bävern',
        'Lena Holm',
        '+46708889900',
        12
    ),
    (
        '65b637fa-c9cc-58be-ae29-cbed52b9a50a',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        '92fefeed-9bcb-5bd2-b16b-ea5796468fc6', -- Mekanisk tjur 2026-07-31
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Ugglan',
        'Markus Test Ledare',
        '+46700000003',
        7
    ),
    (
        '5bec8953-0f59-5d1f-957c-cf0c726f29ba',
        'd4e5f6a7-b8c9-4d23-9ef0-234567890123',
        '6a2fcf85-7a61-5790-a75a-94f9728d8d74', -- Dagens lek: Svanskull 2026-07-31
        'Johan Nilsson',
        303,
        'Scoutkåren Norrsken',
        'Patrull Bävern',
        'Johan Nilsson',
        '+46703334455',
        4
    ),
    (
        'e42dbd3c-987f-5fb7-8aa2-799839fd2403',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        'da3847f2-36c9-579f-9761-b33cbd97519f', -- BRIS 2026-07-31
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Hela avdelningen',
        'Markus Test Funktionär',
        '+46700000002',
        6
    ),
    (
        'f55415c3-7e79-515c-80a3-135893a81d4a',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        'a8b2dad9-a597-5ff5-afb5-a4e6a06e24f7', -- Tim Bergling Foundation 2026-07-31
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Hela avdelningen',
        'Lena Holm',
        '+46708889900',
        8
    ),
    (
        '4fa2da6e-3b78-55a3-afcd-c82d023a1bee',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        'a8b2dad9-a597-5ff5-afb5-a4e6a06e24f7', -- Tim Bergling Foundation 2026-07-31
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Räven',
        'Markus Test Ledare',
        '+46700000003',
        3
    ),
    (
        '63d85150-2bf9-5a9b-ab52-83158f84b571',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        'a8b2dad9-a597-5ff5-afb5-a4e6a06e24f7', -- Tim Bergling Foundation 2026-07-31
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Vargen',
        'Petra Vikström',
        '+46702223344',
        8
    ),
    (
        'c8d50405-8d49-5f73-b351-78a4307abaf2',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '5cbff712-b8ae-530e-81e0-654ccb636f2e', -- Fäktning 2026-07-31
        'Markus Test Planeringsfunktionär',
        NULL,
        NULL,
        'Patrull Räven',
        'Markus Test Planeringsfunktionär',
        '+46700000001',
        5
    ),
    (
        '03d014ae-c47a-501f-9de3-e7a4c7600082',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        '07c7d628-4b9b-5e8b-92c7-0c618d4c9433', -- Unga forskare 2026-07-31
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Patrull Vargen',
        'Markus Test Funktionär',
        '+46700000002',
        12
    ),
    (
        'a15ff774-66e1-506b-96cf-396ee4bb85a5',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        '07c7d628-4b9b-5e8b-92c7-0c618d4c9433', -- Unga forskare 2026-07-31
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Patrull Lodjuret',
        'Erik Johansson',
        '+46709876543',
        7
    ),
    (
        'd3bc74cd-5e0b-563e-af7d-cc4697bfce4d',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '559d040c-caf3-5c92-bb40-dcedb8ef7f19', -- Sagostund 2026-07-31
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Bävern',
        'Petra Vikström',
        '+46702223344',
        4
    ),
    (
        '38ce3b4c-933e-5f20-8d5a-8afdc2731842',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        '559d040c-caf3-5c92-bb40-dcedb8ef7f19', -- Sagostund 2026-07-31
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Ugglan',
        'Lena Holm',
        '+46708889900',
        9
    ),
    (
        '74712c1e-97da-5fa4-aab8-9c4a16890651',
        'a1b2c3d4-e5f6-4a90-abcd-ef1234567890',
        '3bb4fefa-2da3-5f0f-821a-18756c2adf27', -- Kvällsbön 2026-07-31
        'Anna Svensson',
        101,
        'Sjöscoutkåren Dansen',
        'Patrull Bävern',
        'Anna Svensson',
        '+46701234567',
        6
    ),
    (
        'e0713dd9-9fdd-56eb-ada6-807fdffaded4',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        '851aa737-8b37-5cca-af39-869e5065563c', -- Våga Lyssna fördjupning 2026-07-31
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Patrull Ugglan',
        'Erik Johansson',
        '+46709876543',
        3
    ),
    (
        'f7bffaf2-4183-566f-b17e-b075ad5317b0',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        '851aa737-8b37-5cca-af39-869e5065563c', -- Våga Lyssna fördjupning 2026-07-31
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Hela avdelningen',
        'Sara Öberg',
        '+46706667788',
        8
    ),
    (
        'a199bcd1-89e5-5725-8ac9-d6bd47c89466',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '5818ec53-6260-5cb7-867d-71585a74606b', -- Muslimsk tro - NAMN kommer 2026-07-31
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Hela avdelningen',
        'Petra Vikström',
        '+46702223344',
        10
    ),
    (
        '574ce8d5-a812-58ce-8c70-3a81a2786aae',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        '5818ec53-6260-5cb7-867d-71585a74606b', -- Muslimsk tro - NAMN kommer 2026-07-31
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Räven',
        'Lena Holm',
        '+46708889900',
        5
    ),
    (
        'ad4c7a82-242d-57a4-a2b5-b7bd50948a80',
        'd4e5f6a7-b8c9-4d23-9ef0-234567890123',
        'c1dfe740-cffc-5bc6-8746-fb7b7e49793d', -- Musikmosaik: Öppet Jam 2026-07-31
        'Johan Nilsson',
        303,
        'Scoutkåren Norrsken',
        'Patrull Räven',
        'Johan Nilsson',
        '+46703334455',
        7
    ),
    (
        '3f275c6d-95b2-594d-b32f-91c21d5d1ff5',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        '806abba6-b003-564b-99bf-ebc8ee10e52b', -- Poetry Slam 2026-07-31
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Patrull Vargen',
        'Sara Öberg',
        '+46706667788',
        4
    ),
    (
        'f00af900-f59e-5e3d-a5a7-57650aeecf02',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        '806abba6-b003-564b-99bf-ebc8ee10e52b', -- Poetry Slam 2026-07-31
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Patrull Lodjuret',
        'Markus Test Funktionär',
        '+46700000002',
        9
    ),
    (
        '0ae98d55-cfd6-5a43-a3b4-9ee3e5884525',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        'fe469e61-e63f-5229-8abb-0fd8f123594c', -- RUNCLUB 2026-07-31
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Lodjuret',
        'Lena Holm',
        '+46708889900',
        11
    ),
    (
        '3e4d839d-4f86-586a-a98c-a980f66469e5',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        'fe469e61-e63f-5229-8abb-0fd8f123594c', -- RUNCLUB 2026-07-31
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Bävern',
        'Markus Test Ledare',
        '+46700000003',
        6
    ),
    (
        '68fb9d64-09a9-5983-ae92-6bd8bcd403f4',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        'fe469e61-e63f-5229-8abb-0fd8f123594c', -- RUNCLUB 2026-07-31
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Ugglan',
        'Petra Vikström',
        '+46702223344',
        11
    ),
    (
        '11ee597e-530a-536e-8d9b-82bc82e8bf96',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '74978936-9917-5103-900d-cac3602cbbc0', -- Speedfriending 2026-07-31
        'Markus Test Planeringsfunktionär',
        NULL,
        NULL,
        'Patrull Bävern',
        'Markus Test Planeringsfunktionär',
        '+46700000001',
        8
    ),
    (
        'dd0ab594-fd5f-554f-acec-916ba8796adc',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        '0d3261ea-c2cd-5bbf-ae71-f02609f3c9d0', -- Lounge Solnedgång 2026-07-31
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Hela avdelningen',
        'Erik Johansson',
        '+46709876543',
        10
    ),
    (
        '319c6f13-8551-5ac8-b38b-9c59434c3344',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        '0fbdeebb-4a80-552d-b133-611139617834', -- BRIS 2026-07-31
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Hela avdelningen',
        'Markus Test Ledare',
        '+46700000003',
        12
    ),
    (
        '16b4c541-1a4e-5ee8-a08e-81163640cb93',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '0fbdeebb-4a80-552d-b133-611139617834', -- BRIS 2026-07-31
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Räven',
        'Petra Vikström',
        '+46702223344',
        7
    ),
    (
        '767038e1-005d-5732-b31b-f98aa7c0002a',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        '0fbdeebb-4a80-552d-b133-611139617834', -- BRIS 2026-07-31
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Vargen',
        'Lena Holm',
        '+46708889900',
        12
    ),
    (
        '2f0f46c6-6f61-5039-9136-fe71c762595b',
        'a1b2c3d4-e5f6-4a90-abcd-ef1234567890',
        '00f83fef-0443-5dd1-a80f-0b1a9538124d', -- Tim Bergling Foundation 2026-07-31
        'Anna Svensson',
        101,
        'Sjöscoutkåren Dansen',
        'Patrull Räven',
        'Anna Svensson',
        '+46701234567',
        9
    ),
    (
        'ea7398c7-480d-504a-b314-33f7b9fe5247',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        '6db832a3-f7de-5b0f-8adf-f7b0603c14cc', -- En Känsla av Fest 2026-07-31
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Patrull Vargen',
        'Erik Johansson',
        '+46709876543',
        6
    ),
    (
        '2d8ce505-a99c-5242-bb58-ff0d7c889829',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        '6db832a3-f7de-5b0f-8adf-f7b0603c14cc', -- En Känsla av Fest 2026-07-31
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Patrull Lodjuret',
        'Sara Öberg',
        '+46706667788',
        11
    ),
    (
        '443b878c-f57e-5c67-879c-ca3508ff7f00',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        '40587247-379a-572f-86eb-2460bd6043db', -- En Känsla av Fest 2026-07-31
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Bävern',
        'Lena Holm',
        '+46708889900',
        8
    ),
    (
        '6a8c2e2b-b13c-5f47-bdb8-820ea9f8ea44',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        '40587247-379a-572f-86eb-2460bd6043db', -- En Känsla av Fest 2026-07-31
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Ugglan',
        'Markus Test Ledare',
        '+46700000003',
        3
    ),
    (
        '6b2b828a-7689-5aff-9147-0a2c798fb201',
        'd4e5f6a7-b8c9-4d23-9ef0-234567890123',
        '2cbbf2d3-ab65-5e5f-8bb3-847c4265d0fc', -- BRIS 2026-07-31
        'Johan Nilsson',
        303,
        'Scoutkåren Norrsken',
        'Patrull Bävern',
        'Johan Nilsson',
        '+46703334455',
        10
    ),
    (
        '1581d1ea-9df2-51e4-96bc-bed39bacaa71',
        'e5f6a7b8-c9d0-4e34-af01-345678901234',
        '2eddc752-7956-5628-aab7-cf4ee261c157', -- Quiz 2026-07-31
        'Sara Öberg',
        404,
        'Fjällscouterna',
        'Patrull Ugglan',
        'Sara Öberg',
        '+46706667788',
        7
    ),
    (
        '9b735824-ac3f-5b89-aa88-edb38d060457',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        '2eddc752-7956-5628-aab7-cf4ee261c157', -- Quiz 2026-07-31
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Hela avdelningen',
        'Markus Test Funktionär',
        '+46700000002',
        12
    ),
    (
        '9a410253-e91c-5f21-addc-6b6e61a84d9f',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        'c01b2c7a-7547-51e7-9d04-74624badbfef', -- Quiz: Film/tvserie 2026-07-31
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Hela avdelningen',
        'Lena Holm',
        '+46708889900',
        4
    ),
    (
        '7df8eaa4-7b4e-5038-b406-92052220a2b6',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        'c01b2c7a-7547-51e7-9d04-74624badbfef', -- Quiz: Film/tvserie 2026-07-31
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Räven',
        'Markus Test Ledare',
        '+46700000003',
        9
    ),
    (
        '56341b8f-9cc0-5f68-918b-27a65e6c9e1c',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '84ebbc31-66aa-5814-948c-5999effba65f', -- Quiz: Film/tvserie 2026-07-31
        'Markus Test Planeringsfunktionär',
        NULL,
        NULL,
        'Patrull Räven',
        'Markus Test Planeringsfunktionär',
        '+46700000001',
        11
    ),
    (
        '86a3dedc-c196-5ea6-8aeb-3af6065ecf1a',
        '2c378f10-bbf5-4a32-b8f4-050dd552a447',
        '5543f089-bb63-5f5f-9d3a-ffd924526253', -- Midnattsföreläsning 2026-08-01
        'Markus Test Funktionär',
        NULL,
        NULL,
        'Patrull Vargen',
        'Markus Test Funktionär',
        '+46700000002',
        8
    ),
    (
        '3defa02c-8410-536c-9f72-602ac83b4eb8',
        'b2c3d4e5-f6a7-4b01-bcde-f12345678901',
        '5543f089-bb63-5f5f-9d3a-ffd924526253', -- Midnattsföreläsning 2026-08-01
        'Erik Johansson',
        202,
        'Scoutkåren Vansen',
        'Patrull Lodjuret',
        'Erik Johansson',
        '+46709876543',
        3
    ),
    (
        '26bce62c-2d9a-5c95-ac37-8efa1be85d77',
        '3ae85c94-5d76-4d43-ab18-a3521d9ed479',
        '5f1952c0-2ac7-5856-893f-d55bc26d07c9', -- Sagostund 2026-08-01
        'Markus Test Ledare',
        1386,
        'Kår 1386',
        'Patrull Lodjuret',
        'Markus Test Ledare',
        '+46700000003',
        5
    ),
    (
        '99744a49-82de-5c63-bdb6-47429d6185cb',
        'c3d4e5f6-a7b8-4c12-8def-123456789012',
        '5f1952c0-2ac7-5856-893f-d55bc26d07c9', -- Sagostund 2026-08-01
        'Petra Vikström',
        606,
        'Scoutkåren Kompassen',
        'Patrull Bävern',
        'Petra Vikström',
        '+46702223344',
        10
    ),
    (
        'ead80e1d-4681-5903-a082-1b94d1c0d7d0',
        'f6a7b8c9-d0e1-4f45-b012-456789012345',
        '5f1952c0-2ac7-5856-893f-d55bc26d07c9', -- Sagostund 2026-08-01
        'Lena Holm',
        505,
        'Scoutkåren Eken',
        'Patrull Ugglan',
        'Lena Holm',
        '+46708889900',
        5
    )
ON CONFLICT (id) DO NOTHING;

-- On-behalf bookings, all made by Markus Test Planeringsfunktionär for
-- other kårer (bookings:others:create).
INSERT INTO booking (
        id,
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
    )
VALUES
    (
        '09364548-5a05-5ebf-a80a-8510f731b163',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        'a5cd670d-4c43-5400-8f5f-bf4da7113ac8', -- Speed date - vad vill du förändra i samhället? 2026-07-25
        'Markus Test Planeringsfunktionär',
        1102,
        'Adolf Fredriks Scoutkår',
        'Patrull Ugglan',
        'Karin Berg',
        '+46700000001',
        11,
        TRUE
    ),
    (
        'bd6c3bda-41a3-598d-a560-58892e562d91',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        'b2bac4bb-2eac-5205-9326-f21c7701cae2', -- Brädspel 2026-07-25
        'Markus Test Planeringsfunktionär',
        2007,
        'Huddinge Scoutkår',
        'Patrull Lodjuret',
        'Mona Ström',
        '+46700000001',
        9,
        TRUE
    ),
    (
        '23188244-d7e3-5919-9532-65aa9f3ec600',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '1b0ad30f-07f7-599f-b0ed-f52358c885e2', -- Cybersäkerhet med Unga forskare 2026-07-25
        'Markus Test Planeringsfunktionär',
        1310,
        'Tullinge Scoutkår',
        'Patrull Vargen',
        'Ali Rezai',
        '+46700000001',
        10,
        TRUE
    ),
    (
        'fa83771b-cecf-5c14-957e-10c3934ea0dc',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '49f455f9-9b5c-5bc2-8db3-b80189e30a26', -- Våga lyssna fördjupning 2026-07-26
        'Markus Test Planeringsfunktionär',
        1124,
        'Scoutkåren Vikingarna',
        'Patrull Ugglan',
        'Lars Ek',
        '+46700000001',
        5,
        TRUE
    ),
    (
        '79d8142c-0f0c-5bef-bab4-a56c4d893b5e',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        'fd6b5c43-abd1-54da-8012-c4eba92dea0b', -- Upptäckarsamtal 2026-07-26
        'Markus Test Planeringsfunktionär',
        1102,
        'Adolf Fredriks Scoutkår',
        'Patrull Lodjuret',
        'Karin Berg',
        '+46700000001',
        3,
        TRUE
    ),
    (
        '47988ff5-41a0-5035-8d03-fb815e5bc355',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        'afa104af-7392-57ba-b646-75279a3b5d77', -- Leda Scouting - Tamoj del 1 2026-07-26
        'Markus Test Planeringsfunktionär',
        2007,
        'Huddinge Scoutkår',
        'Patrull Vargen',
        'Mona Ström',
        '+46700000001',
        4,
        TRUE
    ),
    (
        '95db4a8e-18e5-5f96-add0-3fee77e7ee2b',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        'c97167ff-5519-5965-a8dc-3113c9f52289', -- Kvällsbön 2026-07-26
        'Markus Test Planeringsfunktionär',
        1310,
        'Tullinge Scoutkår',
        'Patrull Ugglan',
        'Ali Rezai',
        '+46700000001',
        9,
        TRUE
    ),
    (
        '519434b6-0fc3-5e07-8243-5678510f2ab8',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '55a02dd6-aa42-57ba-b881-40f6f6187613', -- Speed friendning 2026-07-26
        'Markus Test Planeringsfunktionär',
        1124,
        'Scoutkåren Vikingarna',
        'Patrull Lodjuret',
        'Lars Ek',
        '+46700000001',
        7,
        TRUE
    ),
    (
        'e39e8db0-f391-54e7-b64b-fb3d46f069b5',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        'a8ada774-7cc9-5c31-8ce4-f5b97367d89b', -- Lekaktiviteter 2026-07-26
        'Markus Test Planeringsfunktionär',
        1102,
        'Adolf Fredriks Scoutkår',
        'Patrull Vargen',
        'Karin Berg',
        '+46700000001',
        8,
        TRUE
    ),
    (
        '25b669c3-2041-54f0-81cb-3f188c3615d3',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        'f0640f56-7792-5307-ba6d-6cec88b13c70', -- Cybersäkerhet med Unga forskare 2026-07-26
        'Markus Test Planeringsfunktionär',
        2007,
        'Huddinge Scoutkår',
        'Patrull Ugglan',
        'Mona Ström',
        '+46700000001',
        3,
        TRUE
    ),
    (
        '672c2075-5d6b-5c34-9e38-91d6da6e2b54',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '7a7c0e31-d225-57a6-b418-d3c0a7c045c7', -- Halmpool 2026-07-26
        'Markus Test Planeringsfunktionär',
        1310,
        'Tullinge Scoutkår',
        'Patrull Lodjuret',
        'Ali Rezai',
        '+46700000001',
        11,
        TRUE
    ),
    (
        '7fb2199e-1918-5e53-87b9-dc7966b0cff7',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        'e7e035d4-ad8b-55da-a308-532d5a9bbafb', -- Psykologisk beredskap 2026-07-26
        'Markus Test Planeringsfunktionär',
        1124,
        'Scoutkåren Vikingarna',
        'Patrull Vargen',
        'Lars Ek',
        '+46700000001',
        12,
        TRUE
    ),
    (
        '7861a6b1-cbba-5524-a4d3-464d10de5caa',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        'cef3019f-0305-56a0-8b32-d930994ef82f', -- Lokal trubadur 2026-07-26
        'Markus Test Planeringsfunktionär',
        1102,
        'Adolf Fredriks Scoutkår',
        'Patrull Ugglan',
        'Karin Berg',
        '+46700000001',
        7,
        TRUE
    ),
    (
        '3a2eb0a1-28f9-52ec-8789-5207ee880d0b',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        'fb2e9a02-0605-52ff-bee5-cb82c8b61312', -- Säker verksamhet 2026-07-27
        'Markus Test Planeringsfunktionär',
        2007,
        'Huddinge Scoutkår',
        'Patrull Lodjuret',
        'Mona Ström',
        '+46700000001',
        5,
        TRUE
    ),
    (
        'd88e3b77-3a4d-5268-b59b-6c35a8edfdab',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        'ab44ffae-97b5-5311-9d76-5b96e79ba50e', -- Mind & Tim Bergling Foundation: Träffa våra ungdomsambassadörer! 2026-07-27
        'Markus Test Planeringsfunktionär',
        1310,
        'Tullinge Scoutkår',
        'Patrull Vargen',
        'Ali Rezai',
        '+46700000001',
        6,
        TRUE
    ),
    (
        '3bd39fb0-1889-50fd-8f99-e73f2b2b3092',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '734e4cf4-1485-5454-b7fe-ecbb03977bd2', -- Återträff Go Global 2026-07-27
        'Markus Test Planeringsfunktionär',
        1124,
        'Scoutkåren Vikingarna',
        'Patrull Ugglan',
        'Lars Ek',
        '+46700000001',
        11,
        TRUE
    ),
    (
        '3d88a46b-5f39-5a54-b8c5-6b59a791dd17',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '8905edbc-6fdb-52fd-96d1-c72ab1c30911', -- Återträff Upplev 2026-07-27
        'Markus Test Planeringsfunktionär',
        1102,
        'Adolf Fredriks Scoutkår',
        'Patrull Lodjuret',
        'Karin Berg',
        '+46700000001',
        9,
        TRUE
    ),
    (
        'c31a7d26-664e-5b15-9657-dcfed84deb50',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        'cf73f516-7167-513d-ab05-5ad6f958d69e', -- Spelkväll! 2026-07-27
        'Markus Test Planeringsfunktionär',
        2007,
        'Huddinge Scoutkår',
        'Patrull Vargen',
        'Mona Ström',
        '+46700000001',
        10,
        TRUE
    ),
    (
        'd2839c97-6a09-556d-969a-b69a5047602b',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '928bac10-8819-5e75-887e-c412e38e8a1b', -- Spårarsamtal 2026-07-27
        'Markus Test Planeringsfunktionär',
        1310,
        'Tullinge Scoutkår',
        'Patrull Ugglan',
        'Ali Rezai',
        '+46700000001',
        5,
        TRUE
    ),
    (
        '94365576-759e-5b59-94dd-b0f85859cf47',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        'd5380b5b-9d81-54b7-b3cf-054603ee33cd', -- Speedfriending 2026-07-27
        'Markus Test Planeringsfunktionär',
        1124,
        'Scoutkåren Vikingarna',
        'Patrull Lodjuret',
        'Lars Ek',
        '+46700000001',
        3,
        TRUE
    ),
    (
        '5ed2b771-bd98-50aa-9be8-c4093d5c783d',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        'a98b2543-6025-5462-b449-bf810ebce753', -- Projektledning för roverscouter 2026-07-27
        'Markus Test Planeringsfunktionär',
        1102,
        'Adolf Fredriks Scoutkår',
        'Patrull Vargen',
        'Karin Berg',
        '+46700000001',
        4,
        TRUE
    ),
    (
        '6d4c1378-0d95-5bd0-9335-113689292317',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '7272a920-5a32-5747-ad7f-3878aeece0ad', -- Sagostund 2026-07-27
        'Markus Test Planeringsfunktionär',
        2007,
        'Huddinge Scoutkår',
        'Patrull Ugglan',
        'Mona Ström',
        '+46700000001',
        9,
        TRUE
    ),
    (
        'ef11d410-aa55-5421-8dd3-cc7109c075d9',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '419a5558-d525-5f10-a9f3-467c8d860321', -- Hand the Ball 2026-07-27
        'Markus Test Planeringsfunktionär',
        1310,
        'Tullinge Scoutkår',
        'Patrull Lodjuret',
        'Ali Rezai',
        '+46700000001',
        7,
        TRUE
    ),
    (
        '57daad91-e063-5d2b-a3c0-b90324d16f0f',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        'bd47dc77-2923-5247-8d41-6f2988fc9d42', -- Disko! 2026-07-27
        'Markus Test Planeringsfunktionär',
        1124,
        'Scoutkåren Vikingarna',
        'Patrull Vargen',
        'Lars Ek',
        '+46700000001',
        8,
        TRUE
    ),
    (
        '7308b1b0-5996-55b4-88c2-3d8b04bbf61c',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '610885be-25c9-51f7-b3aa-4abb9f1a4b73', -- Känslokartan 2026-07-27
        'Markus Test Planeringsfunktionär',
        1102,
        'Adolf Fredriks Scoutkår',
        'Patrull Ugglan',
        'Karin Berg',
        '+46700000001',
        3,
        TRUE
    ),
    (
        'c74f0e97-7186-521b-b48f-366c2f12b9bf',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '9e60857a-fe9c-56b0-95da-eac7249b4d07', -- Knoprep 2026-07-27
        'Markus Test Planeringsfunktionär',
        2007,
        'Huddinge Scoutkår',
        'Patrull Lodjuret',
        'Mona Ström',
        '+46700000001',
        11,
        TRUE
    ),
    (
        'e2bda938-c888-5601-ac5c-33999df717ed',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        'bc6ab101-53ed-5514-a44e-bdf5ddd57962', -- Slankaruseller 2026-07-27
        'Markus Test Planeringsfunktionär',
        1310,
        'Tullinge Scoutkår',
        'Patrull Vargen',
        'Ali Rezai',
        '+46700000001',
        12,
        TRUE
    ),
    (
        '3a024d02-f68a-5a60-9faf-7a08611cb197',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '4e3821d7-8615-5f3e-8829-7000f05c9711', -- Våga utmana normerna 2026-07-27
        'Markus Test Planeringsfunktionär',
        1124,
        'Scoutkåren Vikingarna',
        'Patrull Ugglan',
        'Lars Ek',
        '+46700000001',
        7,
        TRUE
    ),
    (
        '54dc6850-c998-53a8-a3b5-283747e1acc6',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '9c14b462-2c71-5f6d-8b04-59300e848a77', -- Mekanisk tjur 2026-07-27
        'Markus Test Planeringsfunktionär',
        1102,
        'Adolf Fredriks Scoutkår',
        'Patrull Lodjuret',
        'Karin Berg',
        '+46700000001',
        5,
        TRUE
    ),
    (
        '2f49f758-6421-5df8-88a0-6193445630e2',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '5e5bd9f4-bd09-5802-9d8b-5cf077f5332a', -- Hand the Ball 2026-07-27
        'Markus Test Planeringsfunktionär',
        2007,
        'Huddinge Scoutkår',
        'Patrull Vargen',
        'Mona Ström',
        '+46700000001',
        6,
        TRUE
    ),
    (
        '7b455071-3292-5d74-9b32-0ddc221a445d',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        'f492b12d-c637-5616-85bb-2a5eed4ad3a3', -- Desinformation, demokrati och sköldpaddor 2026-07-28
        'Markus Test Planeringsfunktionär',
        1310,
        'Tullinge Scoutkår',
        'Patrull Ugglan',
        'Ali Rezai',
        '+46700000001',
        11,
        TRUE
    ),
    (
        '2e246dea-3a34-5a65-832b-de15c91f0434',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '43550c20-55bc-5f9a-a8fd-a260997e1759', -- Upptäckarsamtal 2026-07-28
        'Markus Test Planeringsfunktionär',
        1124,
        'Scoutkåren Vikingarna',
        'Patrull Lodjuret',
        'Lars Ek',
        '+46700000001',
        9,
        TRUE
    ),
    (
        '8775d0a8-a7c7-5b8a-a185-393bdbaa6a0a',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '35249f33-50d1-57b2-8f12-fd99ce64cf47', -- Bris 2026-07-28
        'Markus Test Planeringsfunktionär',
        1102,
        'Adolf Fredriks Scoutkår',
        'Patrull Vargen',
        'Karin Berg',
        '+46700000001',
        10,
        TRUE
    ),
    (
        '9c75928c-3759-521a-b36d-db00abf9e3bf',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        'efa3894a-48c1-5122-a5dd-1fb9d38caa76', -- Tillsammans bygger vi Sverige 2026-07-28
        'Markus Test Planeringsfunktionär',
        2007,
        'Huddinge Scoutkår',
        'Patrull Ugglan',
        'Mona Ström',
        '+46700000001',
        5,
        TRUE
    ),
    (
        'bbb80d98-880e-5d7c-99a6-b4759d8611a1',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        'fbae3f1c-2b9a-55c4-9a46-43f90201c1d1', -- Sagostund 2026-07-28
        'Markus Test Planeringsfunktionär',
        1310,
        'Tullinge Scoutkår',
        'Patrull Lodjuret',
        'Ali Rezai',
        '+46700000001',
        3,
        TRUE
    ),
    (
        '0831430a-95fc-5c4b-be62-8b75b13074c9',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        'f9dde14c-4518-5ba5-9b6b-79f5b75d5799', -- Brottning 2026-07-28
        'Markus Test Planeringsfunktionär',
        1102,
        'Adolf Fredriks Scoutkår',
        'Patrull Ugglan',
        'Karin Berg',
        '+46700000001',
        9,
        TRUE
    ),
    (
        '76a0f4b6-c537-58f9-a49e-f3049a232c7c',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '70b9d463-b701-51a2-8dfc-bc9cd4960320', -- Bubbelballs 2026-07-28
        'Markus Test Planeringsfunktionär',
        2007,
        'Huddinge Scoutkår',
        'Patrull Lodjuret',
        'Mona Ström',
        '+46700000001',
        7,
        TRUE
    ),
    (
        'c2d22d0e-ce2b-5ed2-8709-f92959f6ef34',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        'c03d4b03-d5bd-5390-bff7-67ee16b7504b', -- Brädspel 2026-07-28
        'Markus Test Planeringsfunktionär',
        1310,
        'Tullinge Scoutkår',
        'Patrull Vargen',
        'Ali Rezai',
        '+46700000001',
        8,
        TRUE
    ),
    (
        '4a31670d-af94-52a3-81f8-a063499e8d7f',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '909fa919-6960-51dd-89a8-40c634e2402d', -- Tillsammans målning 2026-07-28
        'Markus Test Planeringsfunktionär',
        1124,
        'Scoutkåren Vikingarna',
        'Patrull Ugglan',
        'Lars Ek',
        '+46700000001',
        3,
        TRUE
    ),
    (
        '88a29002-37b0-5590-903f-a7caace95cff',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        'bc01d960-a456-526f-8a09-2bb217741930', -- Bubbligt pyssel 2026-07-28
        'Markus Test Planeringsfunktionär',
        1102,
        'Adolf Fredriks Scoutkår',
        'Patrull Lodjuret',
        'Karin Berg',
        '+46700000001',
        11,
        TRUE
    ),
    (
        '4bfff6b4-cd72-5db7-88ba-0ca0ec0e4dc9',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        'c260a43e-e518-5808-9eea-6251e4dd2065', -- Hand the Ball 2026-07-28
        'Markus Test Planeringsfunktionär',
        2007,
        'Huddinge Scoutkår',
        'Patrull Vargen',
        'Mona Ström',
        '+46700000001',
        12,
        TRUE
    ),
    (
        'f8a1e143-3dbb-59f6-84a7-59a95aa7ed15',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '32569674-216f-531f-b365-64759879094f', -- Unga forskare 2026-07-28
        'Markus Test Planeringsfunktionär',
        1310,
        'Tullinge Scoutkår',
        'Patrull Ugglan',
        'Ali Rezai',
        '+46700000001',
        7,
        TRUE
    ),
    (
        '6e91d6a0-07dd-5ba9-9605-a0fa5815c015',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '1248befb-2ca1-5015-af90-cf1fc04ee2b7', -- Uppdrag Självkänsla 2026-07-28
        'Markus Test Planeringsfunktionär',
        1124,
        'Scoutkåren Vikingarna',
        'Patrull Lodjuret',
        'Lars Ek',
        '+46700000001',
        5,
        TRUE
    ),
    (
        '6bf65b22-0410-567f-bd4e-d93c96b3e8c2',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '3b7a85a7-cf33-518a-8032-638a56a534db', -- Disco 2026-07-29
        'Markus Test Planeringsfunktionär',
        1102,
        'Adolf Fredriks Scoutkår',
        'Patrull Vargen',
        'Karin Berg',
        '+46700000001',
        6,
        TRUE
    ),
    (
        'e0161fcf-0a49-514e-8615-53745bd0ed89',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        'a328db88-45f5-5d3d-ad31-da470eacac3c', -- Äventyrararsamtal 2026-07-29
        'Markus Test Planeringsfunktionär',
        2007,
        'Huddinge Scoutkår',
        'Patrull Ugglan',
        'Mona Ström',
        '+46700000001',
        11,
        TRUE
    ),
    (
        '74b12846-568e-57fd-835e-54e701b98bd1',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '8531aec5-e2af-570f-9862-f47ff334b16a', -- Nyfiken på Treklöver Gilwell 2026-07-29
        'Markus Test Planeringsfunktionär',
        1310,
        'Tullinge Scoutkår',
        'Patrull Lodjuret',
        'Ali Rezai',
        '+46700000001',
        9,
        TRUE
    ),
    (
        'b0231a7e-35d7-5d36-864b-0cac0508bef3',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '9f92c566-bb26-583a-a238-7664cbdb0be5', -- Upptäck dina värderingar: Testa på Värdebaserat ledarskap 2026-07-29
        'Markus Test Planeringsfunktionär',
        1124,
        'Scoutkåren Vikingarna',
        'Patrull Vargen',
        'Lars Ek',
        '+46700000001',
        10,
        TRUE
    ),
    (
        '0b25cd59-fae2-526d-aabd-ed113b11e4d8',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        'b3a5cfde-4ef9-5798-a797-7d4da88bfc60', -- The HERDS 2026-07-29
        'Markus Test Planeringsfunktionär',
        1102,
        'Adolf Fredriks Scoutkår',
        'Patrull Ugglan',
        'Karin Berg',
        '+46700000001',
        5,
        TRUE
    ),
    (
        'ff0bf788-53a2-5735-87f2-76afa17e54a1',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '5f3cc3b0-092f-5ef5-b8e8-2ed141bbd017', -- Slappna av som Linné 2026-07-29
        'Markus Test Planeringsfunktionär',
        2007,
        'Huddinge Scoutkår',
        'Patrull Lodjuret',
        'Mona Ström',
        '+46700000001',
        3,
        TRUE
    ),
    (
        'db58a2e2-3c34-5b81-9fcb-c10b8b19dfa5',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '79e1275a-b7f3-5681-91b4-76568de7d94b', -- Hantverksfokus: Banderoller/vimplar 2026-07-29
        'Markus Test Planeringsfunktionär',
        1310,
        'Tullinge Scoutkår',
        'Patrull Vargen',
        'Ali Rezai',
        '+46700000001',
        4,
        TRUE
    ),
    (
        'b9eeb997-2d08-5afd-9e1f-1106bc425cb2',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '81118bd1-7e58-5f07-8c45-6aa9d688b8de', -- Brottning 2026-07-29
        'Markus Test Planeringsfunktionär',
        1124,
        'Scoutkåren Vikingarna',
        'Patrull Ugglan',
        'Lars Ek',
        '+46700000001',
        9,
        TRUE
    ),
    (
        'e2301c4a-51b1-5447-9ea5-e7ad64dbb779',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '09a0eaa2-2077-5847-b154-01bb25840b93', -- Brottning 2026-07-29
        'Markus Test Planeringsfunktionär',
        1102,
        'Adolf Fredriks Scoutkår',
        'Patrull Lodjuret',
        'Karin Berg',
        '+46700000001',
        7,
        TRUE
    ),
    (
        '39997a36-2891-5d8a-a587-0f125570df8b',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '06e7491d-377b-5a3b-bfca-20755677c656', -- Godnattsaga 2026-07-29
        'Markus Test Planeringsfunktionär',
        2007,
        'Huddinge Scoutkår',
        'Patrull Vargen',
        'Mona Ström',
        '+46700000001',
        8,
        TRUE
    ),
    (
        'd482010c-ddd9-5659-8aca-c577a0020355',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        'e5fb15f7-1844-513d-943f-2450746da7f9', -- Poetry Slam 2026-07-29
        'Markus Test Planeringsfunktionär',
        1310,
        'Tullinge Scoutkår',
        'Patrull Ugglan',
        'Ali Rezai',
        '+46700000001',
        3,
        TRUE
    ),
    (
        'aac502c9-9446-58bb-9c37-5dfd6b299868',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        'e6895bcd-a245-5aa8-a3ca-218c70574d59', -- Lasse Berg 2026-07-29
        'Markus Test Planeringsfunktionär',
        1124,
        'Scoutkåren Vikingarna',
        'Patrull Lodjuret',
        'Lars Ek',
        '+46700000001',
        11,
        TRUE
    ),
    (
        'e4132d6e-a48d-586e-b8a0-7600b772df89',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '7cf2fff2-3b9d-5b29-89df-4877d83e7015', -- Linedance 2026-07-29
        'Markus Test Planeringsfunktionär',
        1102,
        'Adolf Fredriks Scoutkår',
        'Patrull Vargen',
        'Karin Berg',
        '+46700000001',
        12,
        TRUE
    ),
    (
        'df97cd80-1cf9-55dc-86d3-f06bd5f92453',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        'fa2cb116-9f29-59aa-a59b-597bec8a9dc5', -- Folkhögskolan workshop 2026-07-29
        'Markus Test Planeringsfunktionär',
        2007,
        'Huddinge Scoutkår',
        'Patrull Ugglan',
        'Mona Ström',
        '+46700000001',
        7,
        TRUE
    ),
    (
        '1f36b647-bdbc-5d5d-8210-9810a3dba5d1',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '2afce3cb-dd2d-57e5-bb4e-e171005f3914', -- Tillsammans i ledarteamet 2026-07-29
        'Markus Test Planeringsfunktionär',
        1310,
        'Tullinge Scoutkår',
        'Patrull Lodjuret',
        'Ali Rezai',
        '+46700000001',
        5,
        TRUE
    ),
    (
        'eec3ae83-646f-525e-87d3-f1e17f8093be',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '83ea5ea3-fca8-5dad-80f8-cdedb0efc686', -- Upp- och nedmärket 2026-07-29
        'Markus Test Planeringsfunktionär',
        1124,
        'Scoutkåren Vikingarna',
        'Patrull Vargen',
        'Lars Ek',
        '+46700000001',
        6,
        TRUE
    ),
    (
        '5c4cf863-1dab-5ed5-b042-1011c8ec55ca',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '9c64cbe6-27f8-5c79-af5e-7b903c19ed3e', -- Frisk & Fri: Hur förändrar vi snacket om kropp och utseende? 2026-07-29
        'Markus Test Planeringsfunktionär',
        1102,
        'Adolf Fredriks Scoutkår',
        'Patrull Ugglan',
        'Karin Berg',
        '+46700000001',
        11,
        TRUE
    ),
    (
        '93780694-1e79-57ec-9b91-1015357abc0f',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        'c7a54b16-96f0-5eef-a2b0-e3e9923e1175', -- Quiz 2026-07-29
        'Markus Test Planeringsfunktionär',
        2007,
        'Huddinge Scoutkår',
        'Patrull Lodjuret',
        'Mona Ström',
        '+46700000001',
        9,
        TRUE
    ),
    (
        '1d9998ef-0286-54af-921c-0fc5bf11d9c2',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        'cc767b60-2cea-594b-be67-4b1e5d0fa504', -- Quiz: Disney 2026-07-29
        'Markus Test Planeringsfunktionär',
        1310,
        'Tullinge Scoutkår',
        'Patrull Vargen',
        'Ali Rezai',
        '+46700000001',
        10,
        TRUE
    ),
    (
        '6c170773-791b-5e8d-8198-c279a0609780',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        'ba51e8fe-ce4e-5d9b-8439-08e85efbc63f', -- Lekaktiviteter 2026-07-29
        'Markus Test Planeringsfunktionär',
        1124,
        'Scoutkåren Vikingarna',
        'Patrull Ugglan',
        'Lars Ek',
        '+46700000001',
        5,
        TRUE
    ),
    (
        '2d7eec58-453e-5faf-83c8-cd9df1f3ebd7',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '6ee37d9e-29be-55d0-8ea0-4a7455bb23cc', -- Brädspel 2026-07-29
        'Markus Test Planeringsfunktionär',
        1102,
        'Adolf Fredriks Scoutkår',
        'Patrull Lodjuret',
        'Karin Berg',
        '+46700000001',
        3,
        TRUE
    ),
    (
        '414d440e-955c-5398-9ce5-668351302e4d',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '8dcfb880-4593-5c83-8dc3-39334cdadbed', -- Tillsammans målning 2026-07-29
        'Markus Test Planeringsfunktionär',
        2007,
        'Huddinge Scoutkår',
        'Patrull Vargen',
        'Mona Ström',
        '+46700000001',
        4,
        TRUE
    ),
    (
        '47d256b0-a936-5e23-815d-f88be665c8d5',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '87c58b36-0673-56b5-b1bd-3d6fdb36e9c6', -- Inspiration för kårer som vill åka utomlands 2026-07-30
        'Markus Test Planeringsfunktionär',
        1310,
        'Tullinge Scoutkår',
        'Patrull Ugglan',
        'Ali Rezai',
        '+46700000001',
        9,
        TRUE
    ),
    (
        '03197580-d09e-5de1-afb7-578c3c548a4d',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '50cd5135-1530-5fb4-b27f-92d48428fd68', -- Nedmontera skiten - hur skapar vi den sämsta möjliga skolan? 2026-07-30
        'Markus Test Planeringsfunktionär',
        1124,
        'Scoutkåren Vikingarna',
        'Patrull Lodjuret',
        'Lars Ek',
        '+46700000001',
        7,
        TRUE
    ),
    (
        '02e55ad8-aa16-526b-aa65-7cc05fbea807',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        'd9b9d7fb-1634-5580-a328-495883dd5428', -- Deep talk - Rösta i Gnistan på tema! 2026-07-30
        'Markus Test Planeringsfunktionär',
        1102,
        'Adolf Fredriks Scoutkår',
        'Patrull Vargen',
        'Karin Berg',
        '+46700000001',
        8,
        TRUE
    ),
    (
        'ff192b6b-7289-51d3-b0d8-489ed52fd566',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        'a10bf42e-79ec-554a-8571-1ab2a3daea1c', -- Quiz 2026-07-30
        'Markus Test Planeringsfunktionär',
        2007,
        'Huddinge Scoutkår',
        'Patrull Ugglan',
        'Mona Ström',
        '+46700000001',
        3,
        TRUE
    ),
    (
        '4e73b574-19e5-51eb-9b25-fdacbcbf3c29',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '065b36e9-4127-5495-9ae3-16cb4a177ef9', -- Familjescoutsamtal 2026-07-30
        'Markus Test Planeringsfunktionär',
        1310,
        'Tullinge Scoutkår',
        'Patrull Lodjuret',
        'Ali Rezai',
        '+46700000001',
        11,
        TRUE
    ),
    (
        'd44cd6d8-afd6-5533-bcb8-ef90cd4ff820',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '665b6442-3ee5-5064-b728-e07a4f1b8e26', -- Speedfriending 2026-07-30
        'Markus Test Planeringsfunktionär',
        1124,
        'Scoutkåren Vikingarna',
        'Patrull Vargen',
        'Lars Ek',
        '+46700000001',
        12,
        TRUE
    ),
    (
        'c68ae7da-33b7-5e57-bcd2-5a6636a6cd4d',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        'aff5625b-7de7-5246-938d-ae374c0a9416', -- Klubb Fiesta med DJ Måns 2026-07-30
        'Markus Test Planeringsfunktionär',
        1102,
        'Adolf Fredriks Scoutkår',
        'Patrull Ugglan',
        'Karin Berg',
        '+46700000001',
        7,
        TRUE
    ),
    (
        '9d59bf18-bc69-573d-a360-fa13831ceaa9',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '8cac8501-366f-5eee-aa6f-5fc63a9a7193', -- Karaoke 2026-07-30
        'Markus Test Planeringsfunktionär',
        2007,
        'Huddinge Scoutkår',
        'Patrull Lodjuret',
        'Mona Ström',
        '+46700000001',
        5,
        TRUE
    ),
    (
        '4c1b225f-a91c-5786-9660-48f53a03ffca',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        'f094215c-5ef9-5b56-9750-7b111e25a829', -- Tänk Till 2026-07-30
        'Markus Test Planeringsfunktionär',
        1310,
        'Tullinge Scoutkår',
        'Patrull Vargen',
        'Ali Rezai',
        '+46700000001',
        6,
        TRUE
    ),
    (
        'a39e10a2-0aa6-5376-9d94-66b8e1ea22a9',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        'd527706a-43de-5b01-8a48-7a2f819268f5', -- Meningen med mig 2026-07-30
        'Markus Test Planeringsfunktionär',
        1124,
        'Scoutkåren Vikingarna',
        'Patrull Ugglan',
        'Lars Ek',
        '+46700000001',
        11,
        TRUE
    ),
    (
        '8285910b-181b-5f43-a5a1-5732875a0b42',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '68f6ba67-24f0-5c94-8384-99996852c29c', -- The HERDS 2026-07-30
        'Markus Test Planeringsfunktionär',
        1102,
        'Adolf Fredriks Scoutkår',
        'Patrull Lodjuret',
        'Karin Berg',
        '+46700000001',
        45,
        TRUE
    ),
    (
        'a0a819ad-a06c-5ef9-8a6f-89c714469898',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        'adca7be8-03cb-5e68-8fac-288b5599278e', -- The HERDS 2026-07-30
        'Markus Test Planeringsfunktionär',
        2007,
        'Huddinge Scoutkår',
        'Patrull Vargen',
        'Mona Ström',
        '+46700000001',
        10,
        TRUE
    ),
    (
        'b1eae926-62bb-5b3b-80d0-51e827ee48ca',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '67672c4c-9045-5d48-9b85-2ffa9b1038b1', -- Pyjamasparty med talangshow 2026-07-30
        'Markus Test Planeringsfunktionär',
        1310,
        'Tullinge Scoutkår',
        'Patrull Ugglan',
        'Ali Rezai',
        '+46700000001',
        5,
        TRUE
    ),
    (
        'a070f970-8ed3-5af7-8301-86f8cbecda3b',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '12c6fd16-9b78-59f8-a2e1-f0ed8d0aeb56', -- Kåsan 2026-07-30
        'Markus Test Planeringsfunktionär',
        1124,
        'Scoutkåren Vikingarna',
        'Patrull Lodjuret',
        'Lars Ek',
        '+46700000001',
        3,
        TRUE
    ),
    (
        'cc813f91-e275-5c6a-817e-ae5c3f0fca19',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '99182452-c33e-5e68-b734-587562646d7e', -- Cybersäkerhet med Unga forskare 2026-07-30
        'Markus Test Planeringsfunktionär',
        1102,
        'Adolf Fredriks Scoutkår',
        'Patrull Vargen',
        'Karin Berg',
        '+46700000001',
        4,
        TRUE
    ),
    (
        'abfd8fa2-3127-5c43-b946-300ec98c9b98',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '27b97594-1254-59e9-b12c-64f108bef1ee', -- Tillsammans målning 2026-07-30
        'Markus Test Planeringsfunktionär',
        2007,
        'Huddinge Scoutkår',
        'Patrull Ugglan',
        'Mona Ström',
        '+46700000001',
        9,
        TRUE
    ),
    (
        'af573699-d0e3-526b-899d-2f778ed2dd96',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        'b64b42bd-0008-53c5-ac1b-6a1789fd0f4d', -- Fladdermussafari 2026-07-30
        'Markus Test Planeringsfunktionär',
        1310,
        'Tullinge Scoutkår',
        'Patrull Lodjuret',
        'Ali Rezai',
        '+46700000001',
        7,
        TRUE
    ),
    (
        'b021e9fb-66ca-58b0-a8d2-5f7a1f914d1b',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '17965407-ce84-5770-8ace-166f630e29b7', -- Upptäck dina värderingar 2026-07-30
        'Markus Test Planeringsfunktionär',
        1124,
        'Scoutkåren Vikingarna',
        'Patrull Vargen',
        'Lars Ek',
        '+46700000001',
        8,
        TRUE
    ),
    (
        '7fbcd95a-aa6b-5af4-8604-9074ca1839af',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        'eb07b45f-6915-5bfc-8215-4a095fe75559', -- Äventyrare berättar: Per Eriksson 2026-07-30
        'Markus Test Planeringsfunktionär',
        1102,
        'Adolf Fredriks Scoutkår',
        'Patrull Ugglan',
        'Karin Berg',
        '+46700000001',
        3,
        TRUE
    ),
    (
        '7474214f-c475-5a74-ba3a-fcde7e84a52e',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '0f4635a3-e4b9-50f8-831a-3c9e5c029489', -- Quiz 2026-07-30
        'Markus Test Planeringsfunktionär',
        2007,
        'Huddinge Scoutkår',
        'Patrull Lodjuret',
        'Mona Ström',
        '+46700000001',
        11,
        TRUE
    ),
    (
        '2ca927ef-bd9c-5d86-b331-a3fdde8b0018',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '1d675389-6002-5fb2-805d-e9d8b27c2a33', -- BRIS 2026-07-30
        'Markus Test Planeringsfunktionär',
        1310,
        'Tullinge Scoutkår',
        'Patrull Vargen',
        'Ali Rezai',
        '+46700000001',
        12,
        TRUE
    ),
    (
        'bc375359-4224-5ceb-80e7-bc959d926c40',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '103efe17-3808-53af-9baf-d7ef382f5066', -- Nyfiken på att bli utbildare 2026-07-31
        'Markus Test Planeringsfunktionär',
        1124,
        'Scoutkåren Vikingarna',
        'Patrull Ugglan',
        'Lars Ek',
        '+46700000001',
        7,
        TRUE
    ),
    (
        '4831d57c-8b0f-53a6-ae2b-063207b06782',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        'bebef6a8-9539-5202-ac37-687a1a8d9b8a', -- Bli arrangemangsledare! 2026-07-31
        'Markus Test Planeringsfunktionär',
        1102,
        'Adolf Fredriks Scoutkår',
        'Patrull Lodjuret',
        'Karin Berg',
        '+46700000001',
        5,
        TRUE
    ),
    (
        'bf608f77-d1b4-5ca1-86b3-939361b95a46',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '452e7dd7-692d-5fe1-b5f6-31b4a7872e3f', -- The HERDS 2026-07-31
        'Markus Test Planeringsfunktionär',
        2007,
        'Huddinge Scoutkår',
        'Patrull Vargen',
        'Mona Ström',
        '+46700000001',
        6,
        TRUE
    ),
    (
        'a9eab7cc-e773-5de5-bd06-c0c9648895c1',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        'da3847f2-36c9-579f-9761-b33cbd97519f', -- BRIS 2026-07-31
        'Markus Test Planeringsfunktionär',
        1310,
        'Tullinge Scoutkår',
        'Patrull Ugglan',
        'Ali Rezai',
        '+46700000001',
        11,
        TRUE
    ),
    (
        '72f4b519-a7c4-5e2c-841f-e012665ffdc7',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '559d040c-caf3-5c92-bb40-dcedb8ef7f19', -- Sagostund 2026-07-31
        'Markus Test Planeringsfunktionär',
        1124,
        'Scoutkåren Vikingarna',
        'Patrull Lodjuret',
        'Lars Ek',
        '+46700000001',
        9,
        TRUE
    ),
    (
        'a775c4e5-3e0b-5306-994e-867f58992c9e',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '5818ec53-6260-5cb7-867d-71585a74606b', -- Muslimsk tro - NAMN kommer 2026-07-31
        'Markus Test Planeringsfunktionär',
        1102,
        'Adolf Fredriks Scoutkår',
        'Patrull Vargen',
        'Karin Berg',
        '+46700000001',
        10,
        TRUE
    ),
    (
        'f7832956-128c-503f-8e0f-b2b2bf1538ca',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '0d3261ea-c2cd-5bbf-ae71-f02609f3c9d0', -- Lounge Solnedgång 2026-07-31
        'Markus Test Planeringsfunktionär',
        2007,
        'Huddinge Scoutkår',
        'Patrull Ugglan',
        'Mona Ström',
        '+46700000001',
        5,
        TRUE
    ),
    (
        '4db50b17-4638-532a-8ddc-aa7f098bdef3',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        '40587247-379a-572f-86eb-2460bd6043db', -- En Känsla av Fest 2026-07-31
        'Markus Test Planeringsfunktionär',
        1310,
        'Tullinge Scoutkår',
        'Patrull Lodjuret',
        'Ali Rezai',
        '+46700000001',
        3,
        TRUE
    ),
    (
        'ba6c9e05-b532-5dba-8024-5a03615103dc',
        '006e3fdd-dc54-43a0-9a2a-4232335c07bc',
        'c01b2c7a-7547-51e7-9d04-74624badbfef', -- Quiz: Film/tvserie 2026-07-31
        'Markus Test Planeringsfunktionär',
        1124,
        'Scoutkåren Vikingarna',
        'Patrull Vargen',
        'Lars Ek',
        '+46700000001',
        4,
        TRUE
    )
ON CONFLICT (id) DO NOTHING;

-- Organizer assignments for the imported programme.
INSERT INTO activity_user (activity_id, user_id)
VALUES
    ('a6b93ca9-1418-5ac3-b668-6429c1023514', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('e5d2c766-cc40-5a2f-8488-f05fc8820572', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('a5cd670d-4c43-5400-8f5f-bf4da7113ac8', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('ce006bf2-571c-5af3-acb1-9b09812bfe7d', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('b2bac4bb-2eac-5205-9326-f21c7701cae2', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('678980c6-bcec-54df-868d-dee8cb79c7f8', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('d28215c6-a981-5223-a703-3d7156437d79', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('f123cd57-0cd6-5e71-8993-fe631c0ae9e3', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('49f455f9-9b5c-5bc2-8db3-b80189e30a26', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('86f8c015-5b80-584c-b685-f5a9dfaa9a20', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('fd6b5c43-abd1-54da-8012-c4eba92dea0b', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('481c9c0a-07c9-5a8b-a45b-d5622bfe5c09', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('078a02ed-a35c-5d31-9381-6bd61542ec9b', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('82dcf744-eed3-5e77-acda-c48b509fd9e2', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('c97167ff-5519-5965-a8dc-3113c9f52289', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('58969b83-d19a-5feb-aa0a-ab79ed50dd95', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('55a02dd6-aa42-57ba-b881-40f6f6187613', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('a6c40518-a47f-5846-8fbe-9deca32f61a7', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('b518a741-3087-5e95-87ce-92a7576252eb', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('71e5768c-7fb5-5bbf-9fdb-c68c208a443c', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('f0640f56-7792-5307-ba6d-6cec88b13c70', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('9ddf4439-267d-5f4c-9b9e-1ef7c400800d', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('7a7c0e31-d225-57a6-b418-d3c0a7c045c7', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('ee79360a-a81d-5f70-a42e-64f1ed0310cf', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('a25e5238-61a2-5523-95b3-2aea9004e56c', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('94e0e7e2-dab6-5457-8ab5-5fe45151ecb0', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('cef3019f-0305-56a0-8b32-d930994ef82f', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('fe69870d-9e76-5b79-bdf9-3dee3b81a968', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('fb2e9a02-0605-52ff-bee5-cb82c8b61312', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('17786f13-ca1b-5efe-acf4-e633f2dfac3b', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('17af255f-d728-5c22-b076-8daae5474bde', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('5699fdf0-232b-5511-a0c9-aaaf232dd936', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('734e4cf4-1485-5454-b7fe-ecbb03977bd2', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('4aa4dd5c-2187-530b-a0c9-e006024efeb6', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('8905edbc-6fdb-52fd-96d1-c72ab1c30911', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('b7235adc-a125-5e79-ad36-3d28925747fa', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('c743dad2-75e2-5870-8367-389485d79ea5', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('81fd232c-9acd-5f53-9f59-d4c4d22918b4', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('928bac10-8819-5e75-887e-c412e38e8a1b', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('a9f73bb3-1833-59c7-b061-cc71f236a1a4', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('d5380b5b-9d81-54b7-b3cf-054603ee33cd', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('27793f1c-f0cf-582f-a2cc-984ccd421417', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('b5eb6a48-0a1f-5e2b-8848-f6880c4a7d55', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('93cb71c7-13b9-5a05-8112-161e8c30c1e1', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('7272a920-5a32-5747-ad7f-3878aeece0ad', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('ffcc33c5-3e99-52ea-924b-56e7269e3a4b', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('419a5558-d525-5f10-a9f3-467c8d860321', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('340bf173-a87f-5fc4-8101-06d9ffcdf112', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('ab7e0f8c-d271-51c9-8f20-144f2b28fd6c', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('8cf6c9a5-0572-5fb7-97e8-f2a0b86f970f', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('610885be-25c9-51f7-b3aa-4abb9f1a4b73', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('e392b8e1-350c-5a6b-87c9-bd98f96558f3', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('9e60857a-fe9c-56b0-95da-eac7249b4d07', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('e8084f74-02e6-52b8-83c3-3919e0701795', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('9cf4dfd8-d2d6-58aa-be42-2bffdc4488ac', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('894b794e-82be-510f-ace5-f7ada9983f04', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('4e3821d7-8615-5f3e-8829-7000f05c9711', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('9e29c220-5584-5735-b757-27f5f9b5d57e', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('9c14b462-2c71-5f6d-8b04-59300e848a77', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('a32d19c5-987d-5fca-a48a-39d55d8bdc16', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('fbc1da73-3032-5b07-81c3-834b369cdbb4', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('9677d2d0-534a-5834-bb70-8357fe094083', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('f492b12d-c637-5616-85bb-2a5eed4ad3a3', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('ea9ade84-ef31-5f6e-830c-93008709c11a', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('43550c20-55bc-5f9a-a8fd-a260997e1759', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('24d1ae2b-6f15-5b63-92fe-3c01cf5151e5', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('82cc345e-54ce-569a-9c23-73dab334769a', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('f40c0dff-d0e6-5b3a-aa19-a445c03d54e1', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('efa3894a-48c1-5122-a5dd-1fb9d38caa76', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('145c51dd-fb96-5a8a-8f2b-0a83aa4ee067', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('fbae3f1c-2b9a-55c4-9a46-43f90201c1d1', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('4c41a1ac-f0cf-5f7a-b87c-41dd760c976b', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('e188aa7c-da5f-505a-96b4-f169416df98d', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('619ef56a-a375-5507-83e0-b3d7433492e5', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('f9dde14c-4518-5ba5-9b6b-79f5b75d5799', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('c3b747f0-650f-5322-a010-e7b4853d91a6', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('70b9d463-b701-51a2-8dfc-bc9cd4960320', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('d62cbeb2-5c7b-5973-9d04-582e7c9ddfaa', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('c647db8f-e85b-5c1d-baf6-1d32df54ca96', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('7cd36315-ac11-5140-8246-001bbf59a88e', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('909fa919-6960-51dd-89a8-40c634e2402d', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('33bc3fdc-c019-5662-94cb-ba847f705003', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('bc01d960-a456-526f-8a09-2bb217741930', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('a57d9076-80c7-57bf-9c21-7d47bf7b6990', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('e0585eff-e1cd-5169-93ee-6b224f613663', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('90a098a3-be20-50a4-b5e7-5bfa026b5e77', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('32569674-216f-531f-b365-64759879094f', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('a90af9f6-1ed7-5ca0-b78f-7881802014e7', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('1248befb-2ca1-5015-af90-cf1fc04ee2b7', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('9d875675-f251-509e-92d5-4ccc462477a3', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('d35950e9-41a4-5468-ae1b-dafc93d3bf2f', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('6b81f3fa-9d1a-50a4-9e81-1f38f2de5c89', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('a328db88-45f5-5d3d-ad31-da470eacac3c', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('2db5db3b-b409-5d32-bc8d-1f83bb0e32a4', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('8531aec5-e2af-570f-9862-f47ff334b16a', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('50d8a427-22aa-5b2e-ab5a-75dec3f92898', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('f0483b2a-3524-595e-9786-03b393d3ed2e', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('64e66343-8863-595d-940e-382b0d6d67c0', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('b3a5cfde-4ef9-5798-a797-7d4da88bfc60', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('e08132d4-7c5c-55de-8cba-9950dbc24b6f', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('5f3cc3b0-092f-5ef5-b8e8-2ed141bbd017', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('87f009ea-2475-5721-a86e-6c4558b5af89', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('dd628ebd-59b3-5ef9-89a4-9d33b9196bb8', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('3e76f15b-bcf7-5323-a2c4-754d743d0dc4', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('81118bd1-7e58-5f07-8c45-6aa9d688b8de', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('674e1c40-cfc0-5caa-962d-9036998468cf', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('09a0eaa2-2077-5847-b154-01bb25840b93', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('d0b88c03-dc38-5da4-b2cf-a2512546d498', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('23bb111a-592f-59cb-85a9-6fdf62534a63', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('af6d8ec5-8916-5714-aa67-0fa9b9925312', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('e5fb15f7-1844-513d-943f-2450746da7f9', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('cc04bc2c-ab64-5c1d-bb44-b975e0505e22', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('e6895bcd-a245-5aa8-a3ca-218c70574d59', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('b392ad26-4118-5fe3-999b-21e5a7733f7c', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('acbcca83-ac2d-5fed-b550-f75ceb39dee8', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('8af18041-d1ff-5d91-8f12-de04f9840d2a', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('fa2cb116-9f29-59aa-a59b-597bec8a9dc5', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('e9794be1-af8b-5270-80c2-1271b5490c99', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('2afce3cb-dd2d-57e5-bb4e-e171005f3914', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('b519a75c-6406-5102-a671-4098ad6463ef', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('721a6e2d-6e74-5fbe-84d4-3172d6129d1d', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('89f7a5d2-daae-52a4-8834-dc1167ab94db', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('9c64cbe6-27f8-5c79-af5e-7b903c19ed3e', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('ab29cf58-58fe-51cf-a826-eeefa2e8aead', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('c7a54b16-96f0-5eef-a2b0-e3e9923e1175', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('db77625e-6ea0-5bf9-a4ac-32a1d00f9b06', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('8c4dccb0-861b-5dfc-bb28-31050a9aecde', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('871e861c-aea4-58bd-abe2-c3a61ed921d2', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('ba51e8fe-ce4e-5d9b-8439-08e85efbc63f', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('a03d0ba9-b294-5822-b584-67a47f10cbb1', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('6ee37d9e-29be-55d0-8ea0-4a7455bb23cc', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('bacd0080-f649-5395-9a58-c19a9d7c00f4', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('42cd3402-33a3-53d7-9b8d-fcf95901bdf3', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('83b9605b-6d8f-56c2-8d06-aa8c4948f16d', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('87c58b36-0673-56b5-b1bd-3d6fdb36e9c6', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('c0ed0f3b-e9bd-5640-b053-ae5dab461678', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('50cd5135-1530-5fb4-b27f-92d48428fd68', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('bd46e4be-166b-53aa-98d6-8c64f006b706', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('0aba5b9b-9b61-52a7-a218-967cf33484f3', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('dd4bb037-abf9-5b64-a1e9-29cb8e45a1e0', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('a10bf42e-79ec-554a-8571-1ab2a3daea1c', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('5c34806a-8cb6-5ac8-939c-e50667086f37', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('065b36e9-4127-5495-9ae3-16cb4a177ef9', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('e8f319ab-0851-520a-966e-b3fe63beef09', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('7669c2c7-538f-5d2b-bc09-3e562a4768de', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('d600ef16-5a89-51fb-8169-5336aeddc7d4', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('aff5625b-7de7-5246-938d-ae374c0a9416', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('5cf47cfb-215d-5a70-87e1-4944ff4ccd4f', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('8cac8501-366f-5eee-aa6f-5fc63a9a7193', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('dc2e47e1-fea3-530a-84eb-5fc7d262767b', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('334d85ed-df16-5008-ab29-ca9dbb8d8ff6', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('c95183ae-acc1-5ccb-8e68-f934c65cd991', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('d527706a-43de-5b01-8a48-7a2f819268f5', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('612fb54e-a192-5dc0-97f7-81ab2bd663c3', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('68f6ba67-24f0-5c94-8384-99996852c29c', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('c7a25147-3684-56f2-bdad-81bca271f881', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('166dfba6-7cdf-5ae4-8a27-755d8617fee2', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('ab9f3402-0a49-5b62-aa5f-c4a7e999280a', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('67672c4c-9045-5d48-9b85-2ffa9b1038b1', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('ef7dd134-f00c-5de5-9e0a-af5d5a5046c4', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('12c6fd16-9b78-59f8-a2e1-f0ed8d0aeb56', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('5c917534-d54b-5837-ae81-b654d1f01b64', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('b93325a4-6e22-5fab-b75b-e8b89a9b75f6', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('ef47c6f3-c408-5dc8-9042-048ea1309885', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('27b97594-1254-59e9-b12c-64f108bef1ee', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('792f0166-12f7-5bd8-87f7-ea87887712c2', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('b64b42bd-0008-53c5-ac1b-6a1789fd0f4d', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('946e9644-2b60-5546-95f2-fbf87dd7abe5', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('c69e0ddf-996e-511b-ad7e-ec63fa23a452', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('2bb67276-c2c3-5801-9269-0e5f9bc02750', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('eb07b45f-6915-5bfc-8215-4a095fe75559', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('711ba1cb-05ba-55a3-8dfb-b7816e9dd83a', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('0f4635a3-e4b9-50f8-831a-3c9e5c029489', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('4b0500f1-ff30-55d8-a816-c70b07f5712d', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('302d98fa-3b21-556e-9e94-7071c56b6644', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('ee755d6d-b4d4-55dc-b588-594ba22a6ca0', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('103efe17-3808-53af-9baf-d7ef382f5066', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('bc5bfb95-4108-5cfe-abe2-fc0dc97ac7c1', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('bebef6a8-9539-5202-ac37-687a1a8d9b8a', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('a3c5bce6-1715-5ce5-a0fb-06ddb9b1b8b5', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('b6cc8ecb-95f6-5450-852e-d471f8854c7d', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('92fefeed-9bcb-5bd2-b16b-ea5796468fc6', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('da3847f2-36c9-579f-9761-b33cbd97519f', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('5cbff712-b8ae-530e-81e0-654ccb636f2e', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('559d040c-caf3-5c92-bb40-dcedb8ef7f19', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('851aa737-8b37-5cca-af39-869e5065563c', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('c1dfe740-cffc-5bc6-8746-fb7b7e49793d', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('fe469e61-e63f-5229-8abb-0fd8f123594c', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('0d3261ea-c2cd-5bbf-ae71-f02609f3c9d0', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('00f83fef-0443-5dd1-a80f-0b1a9538124d', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('40587247-379a-572f-86eb-2460bd6043db', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('2eddc752-7956-5628-aab7-cf4ee261c157', 'e5f6a7b8-c9d0-4e34-af01-345678901234'),
    ('84ebbc31-66aa-5814-948c-5999effba65f', 'c3d4e5f6-a7b8-4c12-8def-123456789012'),
    ('5f1952c0-2ac7-5856-893f-d55bc26d07c9', 'e5f6a7b8-c9d0-4e34-af01-345678901234')
ON CONFLICT (activity_id, user_id) DO NOTHING;

-- Favourites without a booking (hearted but not booked), plus a re-run of
-- the booking-implies-favourite backfill for the bookings added above.
INSERT INTO favourite (id, user_id, activity_id)
VALUES
    (gen_random_uuid(), 'd4e5f6a7-b8c9-4d23-9ef0-234567890123', 'b208a2a7-08dd-58c5-bd88-3084dbeb9436'),
    (gen_random_uuid(), 'e5f6a7b8-c9d0-4e34-af01-345678901234', 'b208a2a7-08dd-58c5-bd88-3084dbeb9436'),
    (gen_random_uuid(), '006e3fdd-dc54-43a0-9a2a-4232335c07bc', 'd6394f2b-7a4b-53ac-9287-aef7f65359aa'),
    (gen_random_uuid(), '2c378f10-bbf5-4a32-b8f4-050dd552a447', 'd6394f2b-7a4b-53ac-9287-aef7f65359aa'),
    (gen_random_uuid(), 'a1b2c3d4-e5f6-4a90-abcd-ef1234567890', 'f81290e7-83ef-5704-96e7-c312916f3658'),
    (gen_random_uuid(), 'b2c3d4e5-f6a7-4b01-bcde-f12345678901', 'f81290e7-83ef-5704-96e7-c312916f3658'),
    (gen_random_uuid(), 'd4e5f6a7-b8c9-4d23-9ef0-234567890123', '4f3dd97a-571d-515c-8e73-f7a0ca192da9'),
    (gen_random_uuid(), 'e5f6a7b8-c9d0-4e34-af01-345678901234', '4f3dd97a-571d-515c-8e73-f7a0ca192da9'),
    (gen_random_uuid(), '006e3fdd-dc54-43a0-9a2a-4232335c07bc', '0c73e5da-a930-528b-9b49-95a22f35655c'),
    (gen_random_uuid(), '2c378f10-bbf5-4a32-b8f4-050dd552a447', '0c73e5da-a930-528b-9b49-95a22f35655c'),
    (gen_random_uuid(), 'a1b2c3d4-e5f6-4a90-abcd-ef1234567890', '73ca9e93-b4e0-5bf2-80c8-5b6448b9bb3f'),
    (gen_random_uuid(), 'b2c3d4e5-f6a7-4b01-bcde-f12345678901', '73ca9e93-b4e0-5bf2-80c8-5b6448b9bb3f'),
    (gen_random_uuid(), 'd4e5f6a7-b8c9-4d23-9ef0-234567890123', '09f413be-effc-51c9-93b9-edefb32ab4c3'),
    (gen_random_uuid(), 'e5f6a7b8-c9d0-4e34-af01-345678901234', '09f413be-effc-51c9-93b9-edefb32ab4c3'),
    (gen_random_uuid(), '006e3fdd-dc54-43a0-9a2a-4232335c07bc', '7986095f-e2ca-515a-b331-42eecc9a6daf'),
    (gen_random_uuid(), '2c378f10-bbf5-4a32-b8f4-050dd552a447', '7986095f-e2ca-515a-b331-42eecc9a6daf'),
    (gen_random_uuid(), 'a1b2c3d4-e5f6-4a90-abcd-ef1234567890', '5f85b46c-f9b2-50e8-b8fb-04b42d02d27b'),
    (gen_random_uuid(), 'b2c3d4e5-f6a7-4b01-bcde-f12345678901', '5f85b46c-f9b2-50e8-b8fb-04b42d02d27b'),
    (gen_random_uuid(), 'd4e5f6a7-b8c9-4d23-9ef0-234567890123', 'a82c89e0-c1a7-5dd4-94ea-4822a33d8c1e'),
    (gen_random_uuid(), 'e5f6a7b8-c9d0-4e34-af01-345678901234', 'a82c89e0-c1a7-5dd4-94ea-4822a33d8c1e'),
    (gen_random_uuid(), '006e3fdd-dc54-43a0-9a2a-4232335c07bc', '37764be9-d7ba-58c8-b2f9-21497bd0a997'),
    (gen_random_uuid(), '2c378f10-bbf5-4a32-b8f4-050dd552a447', '37764be9-d7ba-58c8-b2f9-21497bd0a997'),
    (gen_random_uuid(), 'a1b2c3d4-e5f6-4a90-abcd-ef1234567890', 'f00f9619-668b-5af6-8b49-08b5247c50fe'),
    (gen_random_uuid(), 'b2c3d4e5-f6a7-4b01-bcde-f12345678901', 'f00f9619-668b-5af6-8b49-08b5247c50fe'),
    (gen_random_uuid(), 'd4e5f6a7-b8c9-4d23-9ef0-234567890123', '4bc7bc39-ae07-537a-909d-916a292f7da9'),
    (gen_random_uuid(), 'e5f6a7b8-c9d0-4e34-af01-345678901234', '4bc7bc39-ae07-537a-909d-916a292f7da9'),
    (gen_random_uuid(), '006e3fdd-dc54-43a0-9a2a-4232335c07bc', '76bbce09-a748-51b2-9bdc-abd08d3865f5'),
    (gen_random_uuid(), '2c378f10-bbf5-4a32-b8f4-050dd552a447', '76bbce09-a748-51b2-9bdc-abd08d3865f5'),
    (gen_random_uuid(), 'a1b2c3d4-e5f6-4a90-abcd-ef1234567890', '90db323c-56d0-5fa9-9826-9b1cc6e2eab5'),
    (gen_random_uuid(), 'b2c3d4e5-f6a7-4b01-bcde-f12345678901', '90db323c-56d0-5fa9-9826-9b1cc6e2eab5'),
    (gen_random_uuid(), 'd4e5f6a7-b8c9-4d23-9ef0-234567890123', '272ef6c8-ac23-5c2c-ba08-6b401086f499'),
    (gen_random_uuid(), 'e5f6a7b8-c9d0-4e34-af01-345678901234', '272ef6c8-ac23-5c2c-ba08-6b401086f499'),
    (gen_random_uuid(), '006e3fdd-dc54-43a0-9a2a-4232335c07bc', '647fd0b0-c417-51e0-a2ee-5e712e2d22a9'),
    (gen_random_uuid(), '2c378f10-bbf5-4a32-b8f4-050dd552a447', '647fd0b0-c417-51e0-a2ee-5e712e2d22a9'),
    (gen_random_uuid(), 'a1b2c3d4-e5f6-4a90-abcd-ef1234567890', 'bf3c8d00-859a-5c2e-a139-0485003a95c9'),
    (gen_random_uuid(), 'b2c3d4e5-f6a7-4b01-bcde-f12345678901', 'bf3c8d00-859a-5c2e-a139-0485003a95c9'),
    (gen_random_uuid(), 'd4e5f6a7-b8c9-4d23-9ef0-234567890123', 'ba62753e-ace6-5ea7-815c-5355dca33497'),
    (gen_random_uuid(), 'e5f6a7b8-c9d0-4e34-af01-345678901234', 'ba62753e-ace6-5ea7-815c-5355dca33497'),
    (gen_random_uuid(), '006e3fdd-dc54-43a0-9a2a-4232335c07bc', 'd61cc0ed-dde9-5a95-874f-6a394d470fb7'),
    (gen_random_uuid(), '2c378f10-bbf5-4a32-b8f4-050dd552a447', 'd61cc0ed-dde9-5a95-874f-6a394d470fb7'),
    (gen_random_uuid(), 'a1b2c3d4-e5f6-4a90-abcd-ef1234567890', '471e7101-bac5-54a5-93ab-1c57addf4105'),
    (gen_random_uuid(), 'b2c3d4e5-f6a7-4b01-bcde-f12345678901', '471e7101-bac5-54a5-93ab-1c57addf4105'),
    (gen_random_uuid(), 'd4e5f6a7-b8c9-4d23-9ef0-234567890123', 'b8961dd7-94d3-5faa-8539-28d23be901a1'),
    (gen_random_uuid(), 'e5f6a7b8-c9d0-4e34-af01-345678901234', 'b8961dd7-94d3-5faa-8539-28d23be901a1'),
    (gen_random_uuid(), '006e3fdd-dc54-43a0-9a2a-4232335c07bc', 'a371cfb1-38a6-5be9-a02d-0e5d373d5012'),
    (gen_random_uuid(), '2c378f10-bbf5-4a32-b8f4-050dd552a447', 'a371cfb1-38a6-5be9-a02d-0e5d373d5012'),
    (gen_random_uuid(), 'a1b2c3d4-e5f6-4a90-abcd-ef1234567890', 'b327ec08-141c-5c24-8e0c-6c57cbe914a9'),
    (gen_random_uuid(), 'b2c3d4e5-f6a7-4b01-bcde-f12345678901', 'b327ec08-141c-5c24-8e0c-6c57cbe914a9'),
    (gen_random_uuid(), 'd4e5f6a7-b8c9-4d23-9ef0-234567890123', '697113d8-32f1-5248-acd9-5d4f21d2b815'),
    (gen_random_uuid(), 'e5f6a7b8-c9d0-4e34-af01-345678901234', '697113d8-32f1-5248-acd9-5d4f21d2b815'),
    (gen_random_uuid(), '006e3fdd-dc54-43a0-9a2a-4232335c07bc', 'c7dce563-ead5-5d00-ade9-cc7796b5f2b3'),
    (gen_random_uuid(), '2c378f10-bbf5-4a32-b8f4-050dd552a447', 'c7dce563-ead5-5d00-ade9-cc7796b5f2b3'),
    (gen_random_uuid(), 'a1b2c3d4-e5f6-4a90-abcd-ef1234567890', '973ad700-673a-5f3a-b186-3bb43e890bb3'),
    (gen_random_uuid(), 'b2c3d4e5-f6a7-4b01-bcde-f12345678901', '973ad700-673a-5f3a-b186-3bb43e890bb3'),
    (gen_random_uuid(), 'd4e5f6a7-b8c9-4d23-9ef0-234567890123', '2250b265-08b5-5ada-ac0c-d982c9a4a0e4'),
    (gen_random_uuid(), 'e5f6a7b8-c9d0-4e34-af01-345678901234', '2250b265-08b5-5ada-ac0c-d982c9a4a0e4'),
    (gen_random_uuid(), '006e3fdd-dc54-43a0-9a2a-4232335c07bc', 'a6700f46-99c8-57f6-b195-df8de00b2a99'),
    (gen_random_uuid(), '2c378f10-bbf5-4a32-b8f4-050dd552a447', 'a6700f46-99c8-57f6-b195-df8de00b2a99'),
    (gen_random_uuid(), 'a1b2c3d4-e5f6-4a90-abcd-ef1234567890', 'f9be63fd-339d-559e-9591-0c9ef66e9e2a'),
    (gen_random_uuid(), 'b2c3d4e5-f6a7-4b01-bcde-f12345678901', 'f9be63fd-339d-559e-9591-0c9ef66e9e2a'),
    (gen_random_uuid(), 'd4e5f6a7-b8c9-4d23-9ef0-234567890123', '4c9b890c-63bb-55b1-89e4-6935d327a556'),
    (gen_random_uuid(), 'e5f6a7b8-c9d0-4e34-af01-345678901234', '4c9b890c-63bb-55b1-89e4-6935d327a556'),
    (gen_random_uuid(), '006e3fdd-dc54-43a0-9a2a-4232335c07bc', '7ca65d9b-1b5a-57c5-8b9f-af5689290f07'),
    (gen_random_uuid(), '2c378f10-bbf5-4a32-b8f4-050dd552a447', '7ca65d9b-1b5a-57c5-8b9f-af5689290f07'),
    (gen_random_uuid(), 'a1b2c3d4-e5f6-4a90-abcd-ef1234567890', '76fd5ec7-3097-52af-a625-fdbc403797d9'),
    (gen_random_uuid(), 'b2c3d4e5-f6a7-4b01-bcde-f12345678901', '76fd5ec7-3097-52af-a625-fdbc403797d9'),
    (gen_random_uuid(), 'd4e5f6a7-b8c9-4d23-9ef0-234567890123', '784116ea-ea92-5a89-b5b4-1c9060b8b157'),
    (gen_random_uuid(), 'e5f6a7b8-c9d0-4e34-af01-345678901234', '784116ea-ea92-5a89-b5b4-1c9060b8b157'),
    (gen_random_uuid(), '006e3fdd-dc54-43a0-9a2a-4232335c07bc', '1afdb52a-3c28-5aa6-88f3-87c059d4d6f4'),
    (gen_random_uuid(), '2c378f10-bbf5-4a32-b8f4-050dd552a447', '1afdb52a-3c28-5aa6-88f3-87c059d4d6f4'),
    (gen_random_uuid(), 'a1b2c3d4-e5f6-4a90-abcd-ef1234567890', '6b0a98a1-1c86-5fb8-a5c0-d2a1b40510a2'),
    (gen_random_uuid(), 'b2c3d4e5-f6a7-4b01-bcde-f12345678901', '6b0a98a1-1c86-5fb8-a5c0-d2a1b40510a2'),
    (gen_random_uuid(), 'd4e5f6a7-b8c9-4d23-9ef0-234567890123', '3e0bd307-6448-5c91-9ae5-f434a64a9247'),
    (gen_random_uuid(), 'e5f6a7b8-c9d0-4e34-af01-345678901234', '3e0bd307-6448-5c91-9ae5-f434a64a9247'),
    (gen_random_uuid(), '006e3fdd-dc54-43a0-9a2a-4232335c07bc', '8e8ba3a7-bedb-5473-97ac-a8e34f6a3b2a'),
    (gen_random_uuid(), '2c378f10-bbf5-4a32-b8f4-050dd552a447', '8e8ba3a7-bedb-5473-97ac-a8e34f6a3b2a'),
    (gen_random_uuid(), 'a1b2c3d4-e5f6-4a90-abcd-ef1234567890', '380d1a87-c218-54de-9786-798274eb5886'),
    (gen_random_uuid(), 'b2c3d4e5-f6a7-4b01-bcde-f12345678901', '380d1a87-c218-54de-9786-798274eb5886'),
    (gen_random_uuid(), 'd4e5f6a7-b8c9-4d23-9ef0-234567890123', 'bfef2b35-d06e-5cf5-8e9e-bf1d12faa9bb'),
    (gen_random_uuid(), 'e5f6a7b8-c9d0-4e34-af01-345678901234', 'bfef2b35-d06e-5cf5-8e9e-bf1d12faa9bb'),
    (gen_random_uuid(), '006e3fdd-dc54-43a0-9a2a-4232335c07bc', '073013fb-eefa-5d10-8b29-9c9a2d5db212'),
    (gen_random_uuid(), '2c378f10-bbf5-4a32-b8f4-050dd552a447', '073013fb-eefa-5d10-8b29-9c9a2d5db212'),
    (gen_random_uuid(), 'a1b2c3d4-e5f6-4a90-abcd-ef1234567890', 'e0dd114e-6e53-5a2e-b89a-9fc8501a83af'),
    (gen_random_uuid(), 'b2c3d4e5-f6a7-4b01-bcde-f12345678901', 'e0dd114e-6e53-5a2e-b89a-9fc8501a83af'),
    (gen_random_uuid(), 'd4e5f6a7-b8c9-4d23-9ef0-234567890123', '276b27f4-f554-5dcc-b9fa-d384dae614fe'),
    (gen_random_uuid(), 'e5f6a7b8-c9d0-4e34-af01-345678901234', '276b27f4-f554-5dcc-b9fa-d384dae614fe'),
    (gen_random_uuid(), '006e3fdd-dc54-43a0-9a2a-4232335c07bc', '53774fe1-7833-5af2-9252-6c605c05ed8e'),
    (gen_random_uuid(), '2c378f10-bbf5-4a32-b8f4-050dd552a447', '53774fe1-7833-5af2-9252-6c605c05ed8e'),
    (gen_random_uuid(), 'a1b2c3d4-e5f6-4a90-abcd-ef1234567890', '10cd9866-3857-57cf-8aca-07ca36dffa21'),
    (gen_random_uuid(), 'b2c3d4e5-f6a7-4b01-bcde-f12345678901', '10cd9866-3857-57cf-8aca-07ca36dffa21'),
    (gen_random_uuid(), 'd4e5f6a7-b8c9-4d23-9ef0-234567890123', '75ee78d9-01f9-5863-bae4-9be72bf86405'),
    (gen_random_uuid(), 'e5f6a7b8-c9d0-4e34-af01-345678901234', '75ee78d9-01f9-5863-bae4-9be72bf86405'),
    (gen_random_uuid(), '006e3fdd-dc54-43a0-9a2a-4232335c07bc', 'fb72df50-3d9e-54d6-b0ff-40a16c6c4816'),
    (gen_random_uuid(), '2c378f10-bbf5-4a32-b8f4-050dd552a447', 'fb72df50-3d9e-54d6-b0ff-40a16c6c4816'),
    (gen_random_uuid(), 'a1b2c3d4-e5f6-4a90-abcd-ef1234567890', 'b2fabd42-6e29-501e-9eed-8466de08d564'),
    (gen_random_uuid(), 'b2c3d4e5-f6a7-4b01-bcde-f12345678901', 'b2fabd42-6e29-501e-9eed-8466de08d564'),
    (gen_random_uuid(), 'd4e5f6a7-b8c9-4d23-9ef0-234567890123', 'ee4826a1-73cd-5516-a7a3-4f92df69f119'),
    (gen_random_uuid(), 'e5f6a7b8-c9d0-4e34-af01-345678901234', 'ee4826a1-73cd-5516-a7a3-4f92df69f119'),
    (gen_random_uuid(), '006e3fdd-dc54-43a0-9a2a-4232335c07bc', '81a0dbf5-a073-5253-9e66-6c6b2290e57d'),
    (gen_random_uuid(), '2c378f10-bbf5-4a32-b8f4-050dd552a447', '81a0dbf5-a073-5253-9e66-6c6b2290e57d'),
    (gen_random_uuid(), 'a1b2c3d4-e5f6-4a90-abcd-ef1234567890', '99d7c656-ce54-53b4-bb3f-d182f80be36d'),
    (gen_random_uuid(), 'b2c3d4e5-f6a7-4b01-bcde-f12345678901', '99d7c656-ce54-53b4-bb3f-d182f80be36d'),
    (gen_random_uuid(), 'd4e5f6a7-b8c9-4d23-9ef0-234567890123', '41e6f075-60f6-5052-9207-113fab7b7fb2'),
    (gen_random_uuid(), 'e5f6a7b8-c9d0-4e34-af01-345678901234', '41e6f075-60f6-5052-9207-113fab7b7fb2'),
    (gen_random_uuid(), '006e3fdd-dc54-43a0-9a2a-4232335c07bc', '6abcca52-a574-56cd-9608-0d415bd1de32'),
    (gen_random_uuid(), '2c378f10-bbf5-4a32-b8f4-050dd552a447', '6abcca52-a574-56cd-9608-0d415bd1de32'),
    (gen_random_uuid(), 'a1b2c3d4-e5f6-4a90-abcd-ef1234567890', '565af28c-9f99-54db-a882-011358f07ef6'),
    (gen_random_uuid(), 'b2c3d4e5-f6a7-4b01-bcde-f12345678901', '565af28c-9f99-54db-a882-011358f07ef6'),
    (gen_random_uuid(), 'd4e5f6a7-b8c9-4d23-9ef0-234567890123', '0b90f227-37ab-5e86-94da-e2863a470917'),
    (gen_random_uuid(), 'e5f6a7b8-c9d0-4e34-af01-345678901234', '0b90f227-37ab-5e86-94da-e2863a470917'),
    (gen_random_uuid(), '006e3fdd-dc54-43a0-9a2a-4232335c07bc', '149851bf-369e-525c-8824-7597c22174f0'),
    (gen_random_uuid(), '2c378f10-bbf5-4a32-b8f4-050dd552a447', '149851bf-369e-525c-8824-7597c22174f0'),
    (gen_random_uuid(), 'a1b2c3d4-e5f6-4a90-abcd-ef1234567890', '48fa8c42-11fb-5cf3-b2b9-2d02fe281ec7'),
    (gen_random_uuid(), 'b2c3d4e5-f6a7-4b01-bcde-f12345678901', '48fa8c42-11fb-5cf3-b2b9-2d02fe281ec7'),
    (gen_random_uuid(), 'd4e5f6a7-b8c9-4d23-9ef0-234567890123', '5e4dc1bc-b8f9-5159-b8c9-9c883e895dc7'),
    (gen_random_uuid(), 'e5f6a7b8-c9d0-4e34-af01-345678901234', '5e4dc1bc-b8f9-5159-b8c9-9c883e895dc7'),
    (gen_random_uuid(), '006e3fdd-dc54-43a0-9a2a-4232335c07bc', 'd98fdcad-156d-5086-898a-56c4e7d71dbf'),
    (gen_random_uuid(), '2c378f10-bbf5-4a32-b8f4-050dd552a447', 'd98fdcad-156d-5086-898a-56c4e7d71dbf'),
    (gen_random_uuid(), 'a1b2c3d4-e5f6-4a90-abcd-ef1234567890', '61a36783-7dc3-510a-a53f-a2a2f24b35a0'),
    (gen_random_uuid(), 'b2c3d4e5-f6a7-4b01-bcde-f12345678901', '61a36783-7dc3-510a-a53f-a2a2f24b35a0'),
    (gen_random_uuid(), 'd4e5f6a7-b8c9-4d23-9ef0-234567890123', 'b8365222-0727-59cf-9fca-f8f256c3aa12'),
    (gen_random_uuid(), 'e5f6a7b8-c9d0-4e34-af01-345678901234', 'b8365222-0727-59cf-9fca-f8f256c3aa12'),
    (gen_random_uuid(), '006e3fdd-dc54-43a0-9a2a-4232335c07bc', '20cb80f6-c27c-51d7-b750-61c62b629800'),
    (gen_random_uuid(), '2c378f10-bbf5-4a32-b8f4-050dd552a447', '20cb80f6-c27c-51d7-b750-61c62b629800'),
    (gen_random_uuid(), 'a1b2c3d4-e5f6-4a90-abcd-ef1234567890', '9a276b95-608c-5f7c-bea5-7be1881d6763'),
    (gen_random_uuid(), 'b2c3d4e5-f6a7-4b01-bcde-f12345678901', '9a276b95-608c-5f7c-bea5-7be1881d6763'),
    (gen_random_uuid(), 'd4e5f6a7-b8c9-4d23-9ef0-234567890123', 'dbf084f0-62ea-51d7-a1fe-07590a0b6094'),
    (gen_random_uuid(), 'e5f6a7b8-c9d0-4e34-af01-345678901234', 'dbf084f0-62ea-51d7-a1fe-07590a0b6094'),
    (gen_random_uuid(), '006e3fdd-dc54-43a0-9a2a-4232335c07bc', 'c905335b-63d6-562a-81e6-0d5dbba2ff7e'),
    (gen_random_uuid(), '2c378f10-bbf5-4a32-b8f4-050dd552a447', 'c905335b-63d6-562a-81e6-0d5dbba2ff7e'),
    (gen_random_uuid(), 'a1b2c3d4-e5f6-4a90-abcd-ef1234567890', '1cc1fda1-ef8c-5304-ba7e-22b5f717228a'),
    (gen_random_uuid(), 'b2c3d4e5-f6a7-4b01-bcde-f12345678901', '1cc1fda1-ef8c-5304-ba7e-22b5f717228a'),
    (gen_random_uuid(), 'd4e5f6a7-b8c9-4d23-9ef0-234567890123', 'e97b73f4-4d5a-5b18-a71f-680319e10eef'),
    (gen_random_uuid(), 'e5f6a7b8-c9d0-4e34-af01-345678901234', 'e97b73f4-4d5a-5b18-a71f-680319e10eef'),
    (gen_random_uuid(), '006e3fdd-dc54-43a0-9a2a-4232335c07bc', 'eead6a68-1f2b-53c5-bc82-f7b928d8beec'),
    (gen_random_uuid(), '2c378f10-bbf5-4a32-b8f4-050dd552a447', 'eead6a68-1f2b-53c5-bc82-f7b928d8beec'),
    (gen_random_uuid(), 'a1b2c3d4-e5f6-4a90-abcd-ef1234567890', '850fe1e2-1a9c-5f27-90ae-e1a188056e6d'),
    (gen_random_uuid(), 'b2c3d4e5-f6a7-4b01-bcde-f12345678901', '850fe1e2-1a9c-5f27-90ae-e1a188056e6d'),
    (gen_random_uuid(), 'd4e5f6a7-b8c9-4d23-9ef0-234567890123', '8ddfc7e3-652f-5d35-8b4e-c2fd9f7b9bd4'),
    (gen_random_uuid(), 'e5f6a7b8-c9d0-4e34-af01-345678901234', '8ddfc7e3-652f-5d35-8b4e-c2fd9f7b9bd4'),
    (gen_random_uuid(), '006e3fdd-dc54-43a0-9a2a-4232335c07bc', 'a0675bed-8d38-5222-acbf-d9719f19296c'),
    (gen_random_uuid(), '2c378f10-bbf5-4a32-b8f4-050dd552a447', 'a0675bed-8d38-5222-acbf-d9719f19296c'),
    (gen_random_uuid(), 'a1b2c3d4-e5f6-4a90-abcd-ef1234567890', '87018007-7156-5f30-ab55-74746d60ac5c'),
    (gen_random_uuid(), 'b2c3d4e5-f6a7-4b01-bcde-f12345678901', '87018007-7156-5f30-ab55-74746d60ac5c'),
    (gen_random_uuid(), 'd4e5f6a7-b8c9-4d23-9ef0-234567890123', 'cc405766-4f25-5b04-9020-90b1693609e3'),
    (gen_random_uuid(), 'e5f6a7b8-c9d0-4e34-af01-345678901234', 'cc405766-4f25-5b04-9020-90b1693609e3'),
    (gen_random_uuid(), '006e3fdd-dc54-43a0-9a2a-4232335c07bc', 'fd514c87-6151-50b6-9a28-893a562b7eff'),
    (gen_random_uuid(), '2c378f10-bbf5-4a32-b8f4-050dd552a447', 'fd514c87-6151-50b6-9a28-893a562b7eff'),
    (gen_random_uuid(), 'a1b2c3d4-e5f6-4a90-abcd-ef1234567890', '412c2b5e-f6dc-5d65-a818-d3a96117c17b'),
    (gen_random_uuid(), 'b2c3d4e5-f6a7-4b01-bcde-f12345678901', '412c2b5e-f6dc-5d65-a818-d3a96117c17b'),
    (gen_random_uuid(), 'd4e5f6a7-b8c9-4d23-9ef0-234567890123', '622589b9-9fcc-52ca-b040-cb4d7040bbf9'),
    (gen_random_uuid(), 'e5f6a7b8-c9d0-4e34-af01-345678901234', '622589b9-9fcc-52ca-b040-cb4d7040bbf9'),
    (gen_random_uuid(), '006e3fdd-dc54-43a0-9a2a-4232335c07bc', '2b21ad81-9fec-5838-ae82-7ea271f22d5a'),
    (gen_random_uuid(), '2c378f10-bbf5-4a32-b8f4-050dd552a447', '2b21ad81-9fec-5838-ae82-7ea271f22d5a'),
    (gen_random_uuid(), 'a1b2c3d4-e5f6-4a90-abcd-ef1234567890', '676d645a-e77b-5c21-b5ef-0081eedc0a6d'),
    (gen_random_uuid(), 'b2c3d4e5-f6a7-4b01-bcde-f12345678901', '676d645a-e77b-5c21-b5ef-0081eedc0a6d'),
    (gen_random_uuid(), 'd4e5f6a7-b8c9-4d23-9ef0-234567890123', '559b3071-76a4-58af-ab71-a6a26ac68f33'),
    (gen_random_uuid(), 'e5f6a7b8-c9d0-4e34-af01-345678901234', '559b3071-76a4-58af-ab71-a6a26ac68f33'),
    (gen_random_uuid(), '006e3fdd-dc54-43a0-9a2a-4232335c07bc', 'bc750540-bfb8-51e9-b775-cd44556f9b51'),
    (gen_random_uuid(), '2c378f10-bbf5-4a32-b8f4-050dd552a447', 'bc750540-bfb8-51e9-b775-cd44556f9b51'),
    (gen_random_uuid(), 'a1b2c3d4-e5f6-4a90-abcd-ef1234567890', 'd9c943cd-395c-505d-9f89-65d47a0333c5'),
    (gen_random_uuid(), 'b2c3d4e5-f6a7-4b01-bcde-f12345678901', 'd9c943cd-395c-505d-9f89-65d47a0333c5'),
    (gen_random_uuid(), 'd4e5f6a7-b8c9-4d23-9ef0-234567890123', '6e717191-08a7-5cba-9ae1-b0032d0e6b24'),
    (gen_random_uuid(), 'e5f6a7b8-c9d0-4e34-af01-345678901234', '6e717191-08a7-5cba-9ae1-b0032d0e6b24'),
    (gen_random_uuid(), '006e3fdd-dc54-43a0-9a2a-4232335c07bc', '48a0110c-7d2a-520f-9a21-324131dff26b'),
    (gen_random_uuid(), '2c378f10-bbf5-4a32-b8f4-050dd552a447', '48a0110c-7d2a-520f-9a21-324131dff26b'),
    (gen_random_uuid(), 'a1b2c3d4-e5f6-4a90-abcd-ef1234567890', '5c1f2d3f-4e11-5563-9a62-dfcb0e5812a7'),
    (gen_random_uuid(), 'b2c3d4e5-f6a7-4b01-bcde-f12345678901', '5c1f2d3f-4e11-5563-9a62-dfcb0e5812a7'),
    (gen_random_uuid(), 'd4e5f6a7-b8c9-4d23-9ef0-234567890123', '04bf5403-9b6f-5520-ab76-1db67a0910a7'),
    (gen_random_uuid(), 'e5f6a7b8-c9d0-4e34-af01-345678901234', '04bf5403-9b6f-5520-ab76-1db67a0910a7'),
    (gen_random_uuid(), '006e3fdd-dc54-43a0-9a2a-4232335c07bc', 'd58d93ed-0497-5eae-88c7-dc12c6d7d8b0'),
    (gen_random_uuid(), '2c378f10-bbf5-4a32-b8f4-050dd552a447', 'd58d93ed-0497-5eae-88c7-dc12c6d7d8b0'),
    (gen_random_uuid(), 'a1b2c3d4-e5f6-4a90-abcd-ef1234567890', 'd42b0964-c9cb-5274-b101-f1888cd74205'),
    (gen_random_uuid(), 'b2c3d4e5-f6a7-4b01-bcde-f12345678901', 'd42b0964-c9cb-5274-b101-f1888cd74205'),
    (gen_random_uuid(), 'd4e5f6a7-b8c9-4d23-9ef0-234567890123', '786cf71f-5cd2-546b-848f-c8129a41999e'),
    (gen_random_uuid(), 'e5f6a7b8-c9d0-4e34-af01-345678901234', '786cf71f-5cd2-546b-848f-c8129a41999e'),
    (gen_random_uuid(), '006e3fdd-dc54-43a0-9a2a-4232335c07bc', '5587614e-ce37-5a99-947e-151d62df8ad5'),
    (gen_random_uuid(), '2c378f10-bbf5-4a32-b8f4-050dd552a447', '5587614e-ce37-5a99-947e-151d62df8ad5'),
    (gen_random_uuid(), 'a1b2c3d4-e5f6-4a90-abcd-ef1234567890', 'e493f60f-1af6-5f49-adc4-6eede44b7888'),
    (gen_random_uuid(), 'b2c3d4e5-f6a7-4b01-bcde-f12345678901', 'e493f60f-1af6-5f49-adc4-6eede44b7888'),
    (gen_random_uuid(), 'd4e5f6a7-b8c9-4d23-9ef0-234567890123', '25defd23-b680-599a-b2a5-9e98deef7c63'),
    (gen_random_uuid(), 'e5f6a7b8-c9d0-4e34-af01-345678901234', '25defd23-b680-599a-b2a5-9e98deef7c63'),
    (gen_random_uuid(), '006e3fdd-dc54-43a0-9a2a-4232335c07bc', 'a8b2dad9-a597-5ff5-afb5-a4e6a06e24f7'),
    (gen_random_uuid(), '2c378f10-bbf5-4a32-b8f4-050dd552a447', 'a8b2dad9-a597-5ff5-afb5-a4e6a06e24f7'),
    (gen_random_uuid(), 'a1b2c3d4-e5f6-4a90-abcd-ef1234567890', '3bb4fefa-2da3-5f0f-821a-18756c2adf27'),
    (gen_random_uuid(), 'b2c3d4e5-f6a7-4b01-bcde-f12345678901', '3bb4fefa-2da3-5f0f-821a-18756c2adf27'),
    (gen_random_uuid(), 'd4e5f6a7-b8c9-4d23-9ef0-234567890123', '806abba6-b003-564b-99bf-ebc8ee10e52b'),
    (gen_random_uuid(), 'e5f6a7b8-c9d0-4e34-af01-345678901234', '806abba6-b003-564b-99bf-ebc8ee10e52b'),
    (gen_random_uuid(), '006e3fdd-dc54-43a0-9a2a-4232335c07bc', '0fbdeebb-4a80-552d-b133-611139617834'),
    (gen_random_uuid(), '2c378f10-bbf5-4a32-b8f4-050dd552a447', '0fbdeebb-4a80-552d-b133-611139617834'),
    (gen_random_uuid(), 'a1b2c3d4-e5f6-4a90-abcd-ef1234567890', '2cbbf2d3-ab65-5e5f-8bb3-847c4265d0fc'),
    (gen_random_uuid(), 'b2c3d4e5-f6a7-4b01-bcde-f12345678901', '2cbbf2d3-ab65-5e5f-8bb3-847c4265d0fc'),
    (gen_random_uuid(), 'd4e5f6a7-b8c9-4d23-9ef0-234567890123', '5543f089-bb63-5f5f-9d3a-ffd924526253'),
    (gen_random_uuid(), 'e5f6a7b8-c9d0-4e34-af01-345678901234', '5543f089-bb63-5f5f-9d3a-ffd924526253')
ON CONFLICT (user_id, activity_id) DO NOTHING;

INSERT INTO favourite (id, user_id, activity_id)
SELECT gen_random_uuid(),
    user_id,
    activity_id
FROM booking ON CONFLICT (user_id, activity_id) DO NOTHING;

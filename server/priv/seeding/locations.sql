INSERT INTO location (
        id,
        name,
        name_en,
        description,
        description_en,
        icon_name,
        icon_variant,
        color,
        latitude,
        longitude,
        opening_hours
    )
VALUES (
        '0190f3a1-1c2d-7e3f-9a4b-5c6d7e8f9a0b',
        'Infotält',
        'Info tent',
        'Information och hjälp för deltagare.',
        'Information and help for participants.',
        'tabler-badge-wc',
        'filled',
        '#2563eb',
        55.979798511431689,
        14.134385999313892,
        '{
            "2026-07-25": [
                {"from": "09:00", "to": "12:00"},
                {"from": "13:00", "to": "18:00"}
            ],
            "2026-07-26": [
                {"from": "09:00", "to": "18:00"}
            ]
        }'::jsonb
    ),
    (
        '0190f3a1-3e4f-7051-bc62-7d8e9f0a1b2c',
        'Sjukvårdstält',
        'First aid tent',
        'Sjukvård och första hjälpen dygnet runt.',
        'Medical care and first aid around the clock.',
        'tabler-first-aid-kit',
        'outline',
        '#dc2626',
        55.980512,
        14.135702,
        '{}'::jsonb
    ),
    -- A name-only location without coordinates (issue #26): no map marker or
    -- preview, only the name is shown.
    (
        '0190f3a1-5061-7273-de84-9f0a1b2c3d4e',
        'Samlingsplatsen',
        'The meeting point',
        'Samlingsplats – exakt plats meddelas på plats.',
        'Meeting point – exact spot announced on site.',
        'tabler-flag',
        'outline',
        '#16a34a',
        NULL,
        NULL,
        '{}'::jsonb
    );

INSERT INTO location_tag (id, name, name_en, icon_name, icon_variant)
VALUES (
        '0190f3a1-2d3e-7f40-ab51-6c7d8e9f0a1b',
        'Service',
        'Service',
        'tabler-info-circle',
        'outline'
    ),
    (
        '0190f3a1-4f50-7162-cd73-8e9f0a1b2c3d',
        'Sjukvård',
        'Medical',
        'tabler-heartbeat',
        'filled'
    );

INSERT INTO location_tag_location (location_tag_id, location_id)
VALUES (
        '0190f3a1-2d3e-7f40-ab51-6c7d8e9f0a1b',
        '0190f3a1-1c2d-7e3f-9a4b-5c6d7e8f9a0b'
    ),
    (
        '0190f3a1-2d3e-7f40-ab51-6c7d8e9f0a1b',
        '0190f3a1-3e4f-7051-bc62-7d8e9f0a1b2c'
    ),
    (
        '0190f3a1-4f50-7162-cd73-8e9f0a1b2c3d',
        '0190f3a1-3e4f-7051-bc62-7d8e9f0a1b2c'
    );

-- ============================================================================
-- Locations imported from 'Platser och aktiviteter(5).xlsx' (Platser
-- tab). No coordinates in the sheet, so all are name-only; opening hours are
-- parsed from the per-day columns.
-- ============================================================================
INSERT INTO location (
        id,
        name,
        name_en,
        description,
        description_en,
        icon_name,
        icon_variant,
        color,
        latitude,
        longitude,
        opening_hours
    )
VALUES
    (
        '222aa91f-d8dc-56b4-a631-e3903498c9a1',
        'Listening Ears',
        'Listening Ears',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-ear',
        'outline',
        '#2563eb',
        NULL,
        NULL,
        '{
            "2026-07-26": [{"from": "13:00", "to": "16:30"}, {"from": "18:30", "to": "21:00"}],
            "2026-07-27": [{"from": "13:00", "to": "16:30"}, {"from": "18:30", "to": "21:00"}],
            "2026-07-28": [{"from": "13:00", "to": "16:30"}, {"from": "18:30", "to": "21:00"}],
            "2026-07-29": [{"from": "13:00", "to": "16:30"}, {"from": "18:30", "to": "21:00"}],
            "2026-07-30": [{"from": "13:00", "to": "16:30"}, {"from": "18:30", "to": "21:00"}],
            "2026-07-31": [{"from": "13:00", "to": "16:30"}, {"from": "18:30", "to": "21:00"}],
            "2026-08-01": [{"from": "13:00", "to": "16:30"}, {"from": "18:30", "to": "21:00"}]
        }'::jsonb
    ),
    (
        '92e182f6-7542-5789-a2c2-51e1145974a4',
        'Biblioteket',
        'The Library',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-book',
        'outline',
        '#dc2626',
        NULL,
        NULL,
        '{
            "2026-07-27": [{"from": "09:00", "to": "12:00"}, {"from": "14:00", "to": "17:00"}],
            "2026-07-28": [{"from": "09:00", "to": "12:00"}, {"from": "14:00", "to": "17:00"}, {"from": "19:00", "to": "22:00"}],
            "2026-07-29": [{"from": "09:00", "to": "12:00"}, {"from": "14:00", "to": "17:00"}],
            "2026-07-30": [{"from": "09:00", "to": "12:00"}, {"from": "14:00", "to": "17:00"}, {"from": "19:00", "to": "22:00"}],
            "2026-07-31": [{"from": "09:00", "to": "12:00"}, {"from": "14:00", "to": "17:00"}, {"from": "19:00", "to": "22:00"}],
            "2026-08-01": [{"from": "09:00", "to": "12:00"}, {"from": "14:00", "to": "17:00"}]
        }'::jsonb
    ),
    (
        'db93cd52-18a4-58c9-ac68-d7c32fe390aa',
        'Själen',
        'The Soul',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-heart',
        'outline',
        '#16a34a',
        NULL,
        NULL,
        '{
            "2026-07-26": [{"from": "14:00", "to": "17:00"}],
            "2026-07-27": [{"from": "08:00", "to": "22:30"}],
            "2026-07-28": [{"from": "08:00", "to": "22:30"}],
            "2026-07-29": [{"from": "08:00", "to": "22:30"}],
            "2026-07-30": [{"from": "08:00", "to": "22:30"}],
            "2026-07-31": [{"from": "08:00", "to": "22:30"}],
            "2026-08-01": [{"from": "08:00", "to": "22:30"}]
        }'::jsonb
    ),
    (
        '61dd8139-dc09-560d-95c3-68848553690c',
        'Drömfångaren',
        'The Dreamcatcher',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-moon',
        'outline',
        '#ca8a04',
        NULL,
        NULL,
        '{
            "2026-07-27": [{"from": "09:00", "to": "21:00"}],
            "2026-07-28": [{"from": "09:00", "to": "21:00"}],
            "2026-07-29": [{"from": "09:00", "to": "21:00"}],
            "2026-07-30": [{"from": "09:00", "to": "21:00"}],
            "2026-07-31": [{"from": "09:00", "to": "21:00"}],
            "2026-08-01": [{"from": "09:00", "to": "21:00"}]
        }'::jsonb
    ),
    (
        '8bf3aefe-86d0-5828-b722-f1eec53fbb27',
        'Pulsen',
        'The Pulse',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-heartbeat',
        'outline',
        '#9333ea',
        NULL,
        NULL,
        '{
            "2026-07-26": [{"from": "14:00", "to": "17:00"}],
            "2026-07-27": [{"from": "06:30", "to": "12:00"}, {"from": "14:00", "to": "17:00"}, {"from": "20:00", "to": "23:00"}],
            "2026-07-28": [{"from": "06:00", "to": "12:00"}, {"from": "14:00", "to": "17:00"}, {"from": "19:00", "to": "22:00"}],
            "2026-07-29": [{"from": "06:00", "to": "12:00"}, {"from": "14:00", "to": "17:00"}, {"from": "19:00", "to": "22:00"}],
            "2026-07-30": [{"from": "06:00", "to": "12:00"}, {"from": "14:00", "to": "17:30"}, {"from": "19:00", "to": "22:00"}],
            "2026-07-31": [{"from": "06:30", "to": "12:00"}, {"from": "14:00", "to": "17:00"}, {"from": "19:00", "to": "22:00"}],
            "2026-08-01": [{"from": "06:00", "to": "12:00"}, {"from": "14:00", "to": "17:00"}, {"from": "22:00", "to": "23:00"}]
        }'::jsonb
    ),
    (
        'f7df2233-2fac-5b56-9f6e-6944d7b3fe0e',
        'Spelarkaden',
        'The Game Arcade',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-device-gamepad-2',
        'outline',
        '#c2410c',
        NULL,
        NULL,
        '{
            "2026-07-27": [{"from": "09:00", "to": "12:00"}, {"from": "14:00", "to": "17:00"}],
            "2026-07-28": [{"from": "09:00", "to": "12:00"}, {"from": "14:00", "to": "17:00"}, {"from": "19:00", "to": "22:00"}],
            "2026-07-29": [{"from": "09:00", "to": "12:00"}, {"from": "14:00", "to": "17:00"}],
            "2026-07-30": [{"from": "09:00", "to": "12:00"}, {"from": "14:00", "to": "17:00"}, {"from": "19:00", "to": "22:00"}],
            "2026-07-31": [{"from": "09:00", "to": "12:00"}, {"from": "14:00", "to": "17:00"}, {"from": "19:00", "to": "22:00"}],
            "2026-08-01": [{"from": "09:00", "to": "12:00"}, {"from": "14:00", "to": "17:00"}]
        }'::jsonb
    ),
    (
        'b053ffdf-e47f-58a1-8d81-10e9ea7a5209',
        'Jamboreeradio',
        'Jamboreeradio',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-radio',
        'outline',
        '#0d9488',
        NULL,
        NULL,
        '{
            "2026-07-26": [{"from": "06:00", "to": "23:00"}],
            "2026-07-27": [{"from": "06:00", "to": "23:00"}],
            "2026-07-28": [{"from": "06:00", "to": "23:00"}],
            "2026-07-29": [{"from": "06:00", "to": "23:00"}],
            "2026-07-30": [{"from": "06:00", "to": "23:00"}],
            "2026-07-31": [{"from": "06:00", "to": "23:00"}],
            "2026-08-01": [{"from": "06:00", "to": "23:00"}]
        }'::jsonb
    ),
    (
        'bf389deb-8c50-5537-a539-59d63f5b4198',
        'Klättertornet',
        'The Climbing Tower',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-ladder',
        'outline',
        '#db2777',
        NULL,
        NULL,
        '{
            "2026-07-27": [{"from": "09:00", "to": "12:00"}, {"from": "14:00", "to": "17:00"}],
            "2026-07-28": [{"from": "09:00", "to": "12:00"}, {"from": "14:00", "to": "17:00"}],
            "2026-07-29": [{"from": "09:00", "to": "12:00"}, {"from": "14:00", "to": "17:00"}],
            "2026-07-30": [{"from": "09:00", "to": "12:00"}, {"from": "14:00", "to": "17:00"}],
            "2026-07-31": [{"from": "09:00", "to": "12:00"}, {"from": "14:00", "to": "17:00"}],
            "2026-08-01": [{"from": "09:00", "to": "12:00"}, {"from": "14:00", "to": "17:00"}]
        }'::jsonb
    ),
    (
        '8a6e9259-c0ec-55e9-9876-b1d4074e942e',
        'Folkhögskolan',
        'The Folk High School',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-school',
        'outline',
        '#4f46e5',
        NULL,
        NULL,
        '{
            "2026-07-27": [{"from": "09:00", "to": "18:00"}],
            "2026-07-28": [{"from": "09:00", "to": "21:00"}],
            "2026-07-29": [{"from": "09:00", "to": "21:00"}],
            "2026-07-30": [{"from": "09:00", "to": "21:00"}],
            "2026-07-31": [{"from": "09:00", "to": "21:00"}],
            "2026-08-01": [{"from": "09:00", "to": "18:00"}]
        }'::jsonb
    ),
    (
        '5069f5da-5256-5c31-80ea-62211536f735',
        'Scoutmuseet',
        'The Scout Museum',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-building-museum',
        'outline',
        '#65a30d',
        NULL,
        NULL,
        '{
            "2026-07-27": [{"from": "08:30", "to": "17:00"}],
            "2026-07-28": [{"from": "08:30", "to": "21:00"}],
            "2026-07-29": [{"from": "08:30", "to": "17:00"}],
            "2026-07-30": [{"from": "08:30", "to": "21:00"}],
            "2026-07-31": [{"from": "08:30", "to": "21:00"}],
            "2026-08-01": [{"from": "08:30", "to": "17:00"}]
        }'::jsonb
    ),
    (
        '873567d0-7cb5-5369-9148-eabd14587102',
        'Hantverket med Do-Redo',
        'Hantverket med Do-Redo',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-tools',
        'outline',
        '#2563eb',
        NULL,
        NULL,
        '{
            "2026-07-27": [{"from": "09:00", "to": "12:00"}, {"from": "14:00", "to": "17:00"}],
            "2026-07-28": [{"from": "09:00", "to": "12:00"}, {"from": "14:00", "to": "17:00"}, {"from": "19:00", "to": "22:00"}],
            "2026-07-29": [{"from": "09:00", "to": "12:00"}, {"from": "14:00", "to": "17:00"}],
            "2026-07-30": [{"from": "09:00", "to": "12:00"}, {"from": "14:00", "to": "17:00"}, {"from": "19:00", "to": "22:00"}],
            "2026-07-31": [{"from": "09:00", "to": "12:00"}, {"from": "14:00", "to": "17:00"}, {"from": "19:00", "to": "22:00"}],
            "2026-08-01": [{"from": "09:00", "to": "12:00"}, {"from": "14:00", "to": "17:00"}]
        }'::jsonb
    ),
    (
        '3cc164ae-2a31-55a9-8a3e-73935189dcf0',
        'Swedish Food House',
        'Swedish Food House',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-tools-kitchen-2',
        'outline',
        '#dc2626',
        NULL,
        NULL,
        '{
            "2026-07-26": [{"from": "12:00", "to": "22:00"}],
            "2026-07-27": [{"from": "10:00", "to": "22:00"}],
            "2026-07-28": [{"from": "10:00", "to": "22:00"}],
            "2026-07-29": [{"from": "10:00", "to": "22:00"}],
            "2026-07-30": [{"from": "10:00", "to": "22:00"}],
            "2026-07-31": [{"from": "10:00", "to": "22:00"}],
            "2026-08-01": [{"from": "10:00", "to": "22:00"}]
        }'::jsonb
    ),
    (
        '6be7efcd-bd4b-52f3-8a00-d0d43aba7a60',
        'Sparbanken',
        'The Savings Bank',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-building-bank',
        'outline',
        '#16a34a',
        NULL,
        NULL,
        '{
            "2026-07-28": [{"from": "14:00", "to": "18:00"}],
            "2026-07-29": [{"from": "13:00", "to": "17:00"}],
            "2026-07-30": [{"from": "13:00", "to": "17:00"}]
        }'::jsonb
    ),
    (
        '218902f4-2ec5-58e6-9503-ee8b3da23cf1',
        'Fairtrade',
        'Fairtrade',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-leaf',
        'outline',
        '#ca8a04',
        NULL,
        NULL,
        '{
            "2026-07-26": [{"from": "14:00", "to": "16:00"}],
            "2026-07-27": [{"from": "09:00", "to": "16:00"}],
            "2026-07-28": [{"from": "09:00", "to": "16:00"}]
        }'::jsonb
    ),
    (
        '9898c99b-93ab-571c-a26b-af06d81644b9',
        'Jamboreeshopen',
        'The Jamboree Shop',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-shopping-cart',
        'outline',
        '#9333ea',
        NULL,
        NULL,
        '{
            "2026-07-26": [{"from": "10:00", "to": "20:00"}],
            "2026-07-27": [{"from": "10:00", "to": "19:00"}],
            "2026-07-28": [{"from": "10:00", "to": "20:00"}],
            "2026-07-29": [{"from": "10:00", "to": "18:00"}],
            "2026-07-30": [{"from": "10:00", "to": "20:00"}],
            "2026-07-31": [{"from": "10:00", "to": "20:00"}],
            "2026-08-01": [{"from": "10:00", "to": "19:00"}]
        }'::jsonb
    ),
    (
        'c1110889-acf8-5aa0-8392-086a1427cef9',
        'Badbusstationen',
        'The Beach Bus Station',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-bus',
        'outline',
        '#c2410c',
        NULL,
        NULL,
        '{}'::jsonb
    ),
    (
        '6d1cc310-cb09-56aa-9ccd-05b9dfbf3325',
        'Utanför lägerområdet',
        'Outside the camp area',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-map-pin',
        'outline',
        '#0d9488',
        NULL,
        NULL,
        '{}'::jsonb
    ),
    (
        'adf125a7-5bf4-5b81-9c9f-bedfce4c0a65',
        'Upptäckarhubben',
        'The Explorer Hub',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-tent',
        'outline',
        '#db2777',
        NULL,
        NULL,
        '{
            "2026-07-26": [{"from": "14:00", "to": "21:00"}],
            "2026-07-27": [{"from": "09:00", "to": "17:00"}],
            "2026-07-28": [{"from": "09:00", "to": "21:00"}],
            "2026-07-29": [{"from": "09:00", "to": "17:00"}],
            "2026-07-30": [{"from": "09:00", "to": "21:00"}],
            "2026-07-31": [{"from": "09:00", "to": "21:00"}],
            "2026-08-01": [{"from": "09:00", "to": "17:00"}]
        }'::jsonb
    ),
    (
        'e69ca8d6-a415-5586-81bc-07651faf1879',
        'Utmanarhubben, samtalstält (flera små)',
        'The Challenger Hub, talk tents',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-tent',
        'outline',
        '#4f46e5',
        NULL,
        NULL,
        '{
            "2026-07-26": [{"from": "14:00", "to": "00:00"}],
            "2026-07-27": [{"from": "09:00", "to": "17:00"}, {"from": "21:00", "to": "00:00"}],
            "2026-07-28": [{"from": "09:00", "to": "00:00"}],
            "2026-07-29": [{"from": "09:00", "to": "17:00"}],
            "2026-07-30": [{"from": "09:00", "to": "00:00"}],
            "2026-07-31": [{"from": "09:00", "to": "00:00"}],
            "2026-08-01": [{"from": "09:00", "to": "17:00"}, {"from": "21:00", "to": "02:00"}]
        }'::jsonb
    ),
    (
        '144a94f4-4382-5a06-a690-39c4f846e8fc',
        'Josbaren',
        'The Jos Bar',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-glass-cocktail',
        'outline',
        '#65a30d',
        NULL,
        NULL,
        '{
            "2026-07-26": [{"from": "09:00", "to": "22:00"}],
            "2026-07-27": [{"from": "09:00", "to": "18:00"}],
            "2026-07-28": [{"from": "09:00", "to": "22:00"}],
            "2026-07-29": [{"from": "09:00", "to": "22:00"}],
            "2026-07-30": [{"from": "09:00", "to": "22:00"}],
            "2026-07-31": [{"from": "09:00", "to": "22:00"}],
            "2026-08-01": [{"from": "09:00", "to": "18:00"}]
        }'::jsonb
    ),
    (
        '6a01d4f5-5989-530b-a37b-d53ae9440118',
        'Heartbeat café',
        'Heartbeat Café',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-coffee',
        'outline',
        '#2563eb',
        NULL,
        NULL,
        '{
            "2026-07-26": [{"from": "09:00", "to": "22:00"}],
            "2026-07-27": [{"from": "09:00", "to": "18:00"}],
            "2026-07-28": [{"from": "09:00", "to": "22:00"}],
            "2026-07-29": [{"from": "09:00", "to": "22:00"}],
            "2026-07-30": [{"from": "09:00", "to": "22:00"}],
            "2026-07-31": [{"from": "09:00", "to": "22:00"}],
            "2026-08-01": [{"from": "09:00", "to": "18:00"}]
        }'::jsonb
    ),
    (
        'e5af716c-8a6f-56dc-9cfc-287150d616f4',
        'Utmanarhubb - Brädspelstält',
        'Challenger Hub - Board Game Tent',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-device-gamepad-2',
        'outline',
        '#dc2626',
        NULL,
        NULL,
        '{
            "2026-07-26": [{"from": "14:00", "to": "00:00"}],
            "2026-07-27": [{"from": "09:00", "to": "17:00"}, {"from": "21:00", "to": "00:00"}],
            "2026-07-28": [{"from": "09:00", "to": "00:00"}],
            "2026-07-29": [{"from": "09:00", "to": "17:00"}],
            "2026-07-30": [{"from": "09:00", "to": "00:00"}],
            "2026-07-31": [{"from": "09:00", "to": "00:00"}],
            "2026-08-01": [{"from": "09:00", "to": "17:00"}, {"from": "21:00", "to": "02:00"}]
        }'::jsonb
    ),
    (
        'e09df35a-2d0f-58cb-93b7-81169fa42369',
        'Utmanarhubb - Cafetält',
        'Challenger Hub - Café Tent',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-coffee',
        'outline',
        '#16a34a',
        NULL,
        NULL,
        '{
            "2026-07-26": [{"from": "14:00", "to": "00:00"}],
            "2026-07-27": [{"from": "09:00", "to": "17:00"}, {"from": "21:00", "to": "00:00"}],
            "2026-07-28": [{"from": "09:00", "to": "00:00"}],
            "2026-07-29": [{"from": "09:00", "to": "17:00"}],
            "2026-07-30": [{"from": "09:00", "to": "00:00"}],
            "2026-07-31": [{"from": "09:00", "to": "00:00"}],
            "2026-08-01": [{"from": "09:00", "to": "17:00"}, {"from": "21:00", "to": "02:00"}]
        }'::jsonb
    ),
    (
        'c6171639-edd4-5e3a-bf3f-2a1ddf1a5211',
        'Utmanarhubb - Stora tältet',
        'Challenger Hub - Big Tent',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-tent',
        'outline',
        '#ca8a04',
        NULL,
        NULL,
        '{
            "2026-07-26": [{"from": "14:00", "to": "00:00"}],
            "2026-07-27": [{"from": "09:00", "to": "17:00"}, {"from": "21:00", "to": "00:00"}],
            "2026-07-28": [{"from": "09:00", "to": "00:00"}],
            "2026-07-29": [{"from": "09:00", "to": "17:00"}],
            "2026-07-30": [{"from": "09:00", "to": "00:00"}],
            "2026-07-31": [{"from": "09:00", "to": "00:00"}],
            "2026-08-01": [{"from": "09:00", "to": "17:00"}, {"from": "21:00", "to": "02:00"}]
        }'::jsonb
    ),
    (
        'e10efb9b-f353-54dd-811c-e3b516ce79e8',
        'Roverhubben',
        'The Rover Hub',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-tent',
        'outline',
        '#9333ea',
        NULL,
        NULL,
        '{
            "2026-07-26": [{"from": "14:00", "to": "20:00"}, {"from": "21:00", "to": "00:00"}],
            "2026-07-27": [{"from": "09:00", "to": "20:00"}, {"from": "22:00", "to": "00:00"}],
            "2026-07-28": [{"from": "09:00", "to": "00:00"}],
            "2026-07-29": [{"from": "09:00", "to": "00:00"}],
            "2026-07-30": [{"from": "09:00", "to": "21:00"}, {"from": "22:00", "to": "00:00"}],
            "2026-07-31": [{"from": "09:00", "to": "00:00"}],
            "2026-08-01": [{"from": "09:00", "to": "20:00"}, {"from": "22:00", "to": "02:00"}]
        }'::jsonb
    ),
    (
        '5bd74612-23b5-52d3-9e21-8086ef3bcefd',
        'Roverhubben - Loungen',
        'Rover Hub - The Lounge',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-armchair',
        'outline',
        '#c2410c',
        NULL,
        NULL,
        '{
            "2026-07-26": [{"from": "14:00", "to": "20:00"}, {"from": "21:00", "to": "00:00"}],
            "2026-07-27": [{"from": "09:00", "to": "20:00"}, {"from": "22:00", "to": "00:00"}],
            "2026-07-28": [{"from": "09:00", "to": "00:00"}],
            "2026-07-29": [{"from": "09:00", "to": "00:00"}],
            "2026-07-30": [{"from": "09:00", "to": "21:00"}, {"from": "22:00", "to": "00:00"}],
            "2026-07-31": [{"from": "09:00", "to": "00:00"}],
            "2026-08-01": [{"from": "09:00", "to": "20:00"}, {"from": "22:00", "to": "02:00"}]
        }'::jsonb
    ),
    (
        'b9c63f1a-813b-52d0-9904-e4c74a6b8fcc',
        'Roverhubben - Bistron',
        'Rover Hub - The Bistro',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-tools-kitchen-2',
        'outline',
        '#0d9488',
        NULL,
        NULL,
        '{
            "2026-07-26": [{"from": "14:00", "to": "20:00"}, {"from": "21:00", "to": "00:00"}],
            "2026-07-27": [{"from": "09:00", "to": "20:00"}, {"from": "22:00", "to": "00:00"}],
            "2026-07-28": [{"from": "09:00", "to": "00:00"}],
            "2026-07-29": [{"from": "09:00", "to": "00:00"}],
            "2026-07-30": [{"from": "09:00", "to": "21:00"}, {"from": "22:00", "to": "00:00"}],
            "2026-07-31": [{"from": "09:00", "to": "00:00"}],
            "2026-08-01": [{"from": "09:00", "to": "20:00"}, {"from": "22:00", "to": "02:00"}]
        }'::jsonb
    ),
    (
        '3a137c17-32b0-5583-9509-7711947e13cd',
        'Roverhubben - Pubben',
        'Rover Hub - The Pub',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-beer',
        'outline',
        '#db2777',
        NULL,
        NULL,
        '{
            "2026-07-26": [{"from": "14:00", "to": "20:00"}, {"from": "21:00", "to": "00:00"}],
            "2026-07-27": [{"from": "09:00", "to": "20:00"}, {"from": "22:00", "to": "00:00"}],
            "2026-07-28": [{"from": "09:00", "to": "00:00"}],
            "2026-07-29": [{"from": "09:00", "to": "00:00"}],
            "2026-07-30": [{"from": "09:00", "to": "21:00"}, {"from": "22:00", "to": "00:00"}],
            "2026-07-31": [{"from": "09:00", "to": "00:00"}],
            "2026-08-01": [{"from": "09:00", "to": "20:00"}, {"from": "22:00", "to": "02:00"}]
        }'::jsonb
    ),
    (
        'eadcb315-41e0-546c-b3a5-6b28bfb6c18c',
        'Roverhubben - Klubben',
        'Roverhubben - Klubben',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-tent',
        'outline',
        '#4f46e5',
        NULL,
        NULL,
        '{
            "2026-07-26": [{"from": "14:00", "to": "20:00"}, {"from": "21:00", "to": "00:00"}],
            "2026-07-27": [{"from": "09:00", "to": "20:00"}, {"from": "22:00", "to": "00:00"}],
            "2026-07-28": [{"from": "09:00", "to": "00:00"}],
            "2026-07-29": [{"from": "09:00", "to": "00:00"}],
            "2026-07-30": [{"from": "09:00", "to": "21:00"}, {"from": "22:00", "to": "00:00"}],
            "2026-07-31": [{"from": "09:00", "to": "00:00"}],
            "2026-08-01": [{"from": "09:00", "to": "20:00"}, {"from": "22:00", "to": "02:00"}]
        }'::jsonb
    ),
    (
        'ebb7da6c-244f-59f4-8165-898dd0f1b636',
        'Roverprogram',
        'Roverprogram',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-calendar-event',
        'outline',
        '#65a30d',
        NULL,
        NULL,
        '{
            "2026-07-28": [{"from": "08:30", "to": "12:30"}, {"from": "14:00", "to": "18:00"}],
            "2026-07-29": [{"from": "08:30", "to": "12:30"}, {"from": "14:00", "to": "18:00"}],
            "2026-07-30": [{"from": "08:30", "to": "12:30"}, {"from": "14:00", "to": "18:00"}],
            "2026-07-31": [{"from": "08:30", "to": "12:30"}, {"from": "14:00", "to": "18:00"}],
            "2026-08-01": [{"from": "08:30", "to": "12:30"}, {"from": "14:00", "to": "18:00"}]
        }'::jsonb
    ),
    (
        '304850ba-46f1-5dde-974e-b50f973c1260',
        'Upptäckarhubben - Bikupan',
        'Upptäckarhubben - Bikupan',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-tent',
        'outline',
        '#2563eb',
        NULL,
        NULL,
        '{
            "2026-07-26": [{"from": "14:00", "to": "21:00"}],
            "2026-07-27": [{"from": "09:00", "to": "17:00"}],
            "2026-07-28": [{"from": "09:00", "to": "21:00"}],
            "2026-07-29": [{"from": "09:00", "to": "17:00"}],
            "2026-07-30": [{"from": "09:00", "to": "21:00"}],
            "2026-07-31": [{"from": "09:00", "to": "21:00"}],
            "2026-08-01": [{"from": "09:00", "to": "17:00"}]
        }'::jsonb
    ),
    (
        '814b68b7-cae2-52f0-8a6d-9d13797bdabf',
        'Upptäckarhubben - Pysslingen',
        'Upptäckarhubben - Pysslingen',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-tent',
        'outline',
        '#dc2626',
        NULL,
        NULL,
        '{
            "2026-07-26": [{"from": "14:00", "to": "21:00"}],
            "2026-07-27": [{"from": "09:00", "to": "17:00"}],
            "2026-07-28": [{"from": "09:00", "to": "21:00"}],
            "2026-07-29": [{"from": "09:00", "to": "17:00"}],
            "2026-07-30": [{"from": "09:00", "to": "21:00"}],
            "2026-07-31": [{"from": "09:00", "to": "21:00"}],
            "2026-08-01": [{"from": "09:00", "to": "17:00"}]
        }'::jsonb
    ),
    (
        '1a4f6eda-8d95-5fc9-8f3d-b663ecf6b4d3',
        'Upptäckarhubben - Korpboet',
        'Upptäckarhubben - Korpboet',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-tent',
        'outline',
        '#16a34a',
        NULL,
        NULL,
        '{
            "2026-07-26": [{"from": "14:00", "to": "21:00"}],
            "2026-07-27": [{"from": "09:00", "to": "17:00"}],
            "2026-07-28": [{"from": "09:00", "to": "21:00"}],
            "2026-07-29": [{"from": "09:00", "to": "17:00"}],
            "2026-07-30": [{"from": "09:00", "to": "21:00"}],
            "2026-07-31": [{"from": "09:00", "to": "21:00"}],
            "2026-08-01": [{"from": "09:00", "to": "17:00"}]
        }'::jsonb
    ),
    (
        '4bd82aa6-0f20-5cf8-80d6-e475a15c288a',
        'Upptäckarhubben - Zvampen',
        'Upptäckarhubben - Zvampen',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-tent',
        'outline',
        '#ca8a04',
        NULL,
        NULL,
        '{
            "2026-07-26": [{"from": "14:00", "to": "21:00"}],
            "2026-07-27": [{"from": "09:00", "to": "17:00"}],
            "2026-07-28": [{"from": "09:00", "to": "21:00"}],
            "2026-07-29": [{"from": "09:00", "to": "17:00"}],
            "2026-07-30": [{"from": "09:00", "to": "21:00"}],
            "2026-07-31": [{"from": "09:00", "to": "21:00"}],
            "2026-08-01": [{"from": "09:00", "to": "17:00"}]
        }'::jsonb
    ),
    (
        'b70eb2f8-96dc-5ecb-b551-c28f1fb1ffb0',
        'Upptäckarhubben - Draknästet',
        'Upptäckarhubben - Draknästet',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-tent',
        'outline',
        '#9333ea',
        NULL,
        NULL,
        '{
            "2026-07-26": [{"from": "14:00", "to": "21:00"}],
            "2026-07-27": [{"from": "09:00", "to": "17:00"}],
            "2026-07-28": [{"from": "09:00", "to": "21:00"}],
            "2026-07-29": [{"from": "09:00", "to": "17:00"}],
            "2026-07-30": [{"from": "09:00", "to": "21:00"}],
            "2026-07-31": [{"from": "09:00", "to": "21:00"}],
            "2026-08-01": [{"from": "09:00", "to": "17:00"}]
        }'::jsonb
    ),
    (
        '81cfeea5-ab1b-5264-a6d1-279a20fadaf4',
        'Upptäckarhubben - Murmeldjuret',
        'Upptäckarhubben - Murmeldjuret',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-tent',
        'outline',
        '#c2410c',
        NULL,
        NULL,
        '{
            "2026-07-26": [{"from": "14:00", "to": "21:00"}],
            "2026-07-27": [{"from": "09:00", "to": "17:00"}],
            "2026-07-28": [{"from": "09:00", "to": "21:00"}],
            "2026-07-29": [{"from": "09:00", "to": "17:00"}],
            "2026-07-30": [{"from": "09:00", "to": "21:00"}],
            "2026-07-31": [{"from": "09:00", "to": "21:00"}],
            "2026-08-01": [{"from": "09:00", "to": "17:00"}]
        }'::jsonb
    ),
    (
        '7357971d-510a-567f-bff7-c37329d01c7f',
        'Upptäckarhubben - Scen',
        'Upptäckarhubben - Scen',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-music',
        'outline',
        '#0d9488',
        NULL,
        NULL,
        '{
            "2026-07-26": [{"from": "14:00", "to": "21:00"}],
            "2026-07-27": [{"from": "09:00", "to": "17:00"}],
            "2026-07-28": [{"from": "09:00", "to": "21:00"}],
            "2026-07-29": [{"from": "09:00", "to": "17:00"}],
            "2026-07-30": [{"from": "09:00", "to": "21:00"}],
            "2026-07-31": [{"from": "09:00", "to": "21:00"}],
            "2026-08-01": [{"from": "09:00", "to": "17:00"}]
        }'::jsonb
    ),
    (
        '59e1df30-6abb-58a0-b951-0da741883428',
        'Äventyrarhubben',
        'The Adventurer Hub',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-tent',
        'outline',
        '#db2777',
        NULL,
        NULL,
        '{
            "2026-07-26": [{"from": "14:00", "to": "21:00"}],
            "2026-07-27": [{"from": "09:00", "to": "17:00"}],
            "2026-07-28": [{"from": "09:00", "to": "21:00"}],
            "2026-07-29": [{"from": "09:00", "to": "17:00"}],
            "2026-07-30": [{"from": "09:00", "to": "21:00"}],
            "2026-07-31": [{"from": "09:00", "to": "21:00"}],
            "2026-08-01": [{"from": "09:00", "to": "17:00"}]
        }'::jsonb
    ),
    (
        '3ad84bf8-0a68-5c32-8895-8f9183480709',
        'Äventyrarhubben - Livliga Luckan',
        'Äventyrarhubben - Livliga Luckan',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-tent',
        'outline',
        '#4f46e5',
        NULL,
        NULL,
        '{
            "2026-07-26": [{"from": "14:00", "to": "21:00"}],
            "2026-07-27": [{"from": "09:00", "to": "17:00"}],
            "2026-07-28": [{"from": "09:00", "to": "21:00"}],
            "2026-07-29": [{"from": "09:00", "to": "17:00"}],
            "2026-07-30": [{"from": "09:00", "to": "21:00"}],
            "2026-07-31": [{"from": "09:00", "to": "21:00"}],
            "2026-08-01": [{"from": "09:00", "to": "17:00"}]
        }'::jsonb
    ),
    (
        '1b05f536-c57d-5b4f-bd5a-0011a7c4dbeb',
        'Äventyrarhubben - Bubblan',
        'Äventyrarhubben - Bubblan',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-tent',
        'outline',
        '#65a30d',
        NULL,
        NULL,
        '{
            "2026-07-26": [{"from": "14:00", "to": "21:00"}],
            "2026-07-27": [{"from": "09:00", "to": "17:00"}],
            "2026-07-28": [{"from": "09:00", "to": "21:00"}],
            "2026-07-29": [{"from": "09:00", "to": "17:00"}],
            "2026-07-30": [{"from": "09:00", "to": "21:00"}],
            "2026-07-31": [{"from": "09:00", "to": "21:00"}],
            "2026-08-01": [{"from": "09:00", "to": "17:00"}]
        }'::jsonb
    ),
    (
        '752c0d21-3c68-50d2-bf8a-53ee8fa96895',
        'Äventyrarhubben - Forskardalen',
        'Äventyrarhubben - Forskardalen',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-tent',
        'outline',
        '#2563eb',
        NULL,
        NULL,
        '{
            "2026-07-26": [{"from": "14:00", "to": "21:00"}],
            "2026-07-27": [{"from": "09:00", "to": "17:00"}],
            "2026-07-28": [{"from": "09:00", "to": "21:00"}],
            "2026-07-29": [{"from": "09:00", "to": "17:00"}],
            "2026-07-30": [{"from": "09:00", "to": "21:00"}],
            "2026-07-31": [{"from": "09:00", "to": "21:00"}],
            "2026-08-01": [{"from": "09:00", "to": "17:00"}]
        }'::jsonb
    ),
    (
        'c5970e8b-8397-5bda-b92b-9734d3db4223',
        'Äventyrarhubben - Skogsgläntan',
        'Äventyrarhubben - Skogsgläntan',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-tent',
        'outline',
        '#dc2626',
        NULL,
        NULL,
        '{
            "2026-07-26": [{"from": "14:00", "to": "21:00"}],
            "2026-07-27": [{"from": "09:00", "to": "17:00"}],
            "2026-07-28": [{"from": "09:00", "to": "21:00"}],
            "2026-07-29": [{"from": "09:00", "to": "17:00"}],
            "2026-07-30": [{"from": "09:00", "to": "21:00"}],
            "2026-07-31": [{"from": "09:00", "to": "21:00"}],
            "2026-08-01": [{"from": "09:00", "to": "17:00"}]
        }'::jsonb
    ),
    (
        'e65a2868-19ef-54ef-8606-2a6d7d7fe9eb',
        'Äventyrarhubben - Ranchen',
        'Äventyrarhubben - Ranchen',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-tent',
        'outline',
        '#16a34a',
        NULL,
        NULL,
        '{
            "2026-07-26": [{"from": "14:00", "to": "21:00"}],
            "2026-07-27": [{"from": "09:00", "to": "17:00"}],
            "2026-07-28": [{"from": "09:00", "to": "21:00"}],
            "2026-07-29": [{"from": "09:00", "to": "17:00"}],
            "2026-07-30": [{"from": "09:00", "to": "21:00"}],
            "2026-07-31": [{"from": "09:00", "to": "21:00"}],
            "2026-08-01": [{"from": "09:00", "to": "17:00"}]
        }'::jsonb
    ),
    (
        '410166cf-c3f9-547e-8d04-88011947a675',
        'Äventyrarhubben - Saloonen',
        'Äventyrarhubben - Saloonen',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-tent',
        'outline',
        '#ca8a04',
        NULL,
        NULL,
        '{
            "2026-07-26": [{"from": "14:00", "to": "21:00"}],
            "2026-07-27": [{"from": "09:00", "to": "17:00"}],
            "2026-07-28": [{"from": "09:00", "to": "21:00"}],
            "2026-07-29": [{"from": "09:00", "to": "17:00"}],
            "2026-07-30": [{"from": "09:00", "to": "21:00"}],
            "2026-07-31": [{"from": "09:00", "to": "21:00"}],
            "2026-08-01": [{"from": "09:00", "to": "17:00"}]
        }'::jsonb
    ),
    (
        '132ac210-81cf-517d-af93-170589646f53',
        'Äventyrarhubben - Tågstationen',
        'Äventyrarhubben - Tågstationen',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-tent',
        'outline',
        '#9333ea',
        NULL,
        NULL,
        '{
            "2026-07-26": [{"from": "14:00", "to": "21:00"}],
            "2026-07-27": [{"from": "09:00", "to": "17:00"}],
            "2026-07-28": [{"from": "09:00", "to": "21:00"}],
            "2026-07-29": [{"from": "09:00", "to": "17:00"}],
            "2026-07-30": [{"from": "09:00", "to": "21:00"}],
            "2026-07-31": [{"from": "09:00", "to": "21:00"}],
            "2026-08-01": [{"from": "09:00", "to": "17:00"}]
        }'::jsonb
    ),
    (
        '6e2c7bf6-22af-58a7-ab08-58e462caae3e',
        'Äventyrarhubben - Soliga sällskapshörnan',
        'Äventyrarhubben - Soliga sällskapshörnan',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-tent',
        'outline',
        '#c2410c',
        NULL,
        NULL,
        '{
            "2026-07-26": [{"from": "14:00", "to": "21:00"}],
            "2026-07-27": [{"from": "09:00", "to": "17:00"}],
            "2026-07-28": [{"from": "09:00", "to": "21:00"}],
            "2026-07-29": [{"from": "09:00", "to": "17:00"}],
            "2026-07-30": [{"from": "09:00", "to": "21:00"}],
            "2026-07-31": [{"from": "09:00", "to": "21:00"}],
            "2026-08-01": [{"from": "09:00", "to": "17:00"}]
        }'::jsonb
    ),
    (
        '6b32fa25-8341-537f-b8d7-ca4ad5a843a6',
        'Programtältet',
        'The Programme Tent',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-calendar-event',
        'outline',
        '#0d9488',
        NULL,
        NULL,
        '{
            "2026-07-26": [{"from": "14:00", "to": "17:30"}, {"from": "19:00", "to": "21:00"}],
            "2026-07-27": [{"from": "10:00", "to": "11:30"}, {"from": "13:00", "to": "18:00"}],
            "2026-07-28": [{"from": "10:00", "to": "11:30"}, {"from": "13:00", "to": "17:30"}, {"from": "19:00", "to": "21:00"}],
            "2026-07-29": [{"from": "10:00", "to": "11:30"}, {"from": "13:00", "to": "17:30"}],
            "2026-07-30": [{"from": "10:00", "to": "11:30"}, {"from": "13:00", "to": "17:30"}, {"from": "19:00", "to": "21:00"}],
            "2026-07-31": [{"from": "10:00", "to": "11:30"}, {"from": "13:00", "to": "17:30"}, {"from": "19:00", "to": "21:00"}],
            "2026-08-01": [{"from": "10:00", "to": "11:30"}, {"from": "13:00", "to": "18:00"}]
        }'::jsonb
    ),
    (
        '8fe15224-f662-5ce0-a1bc-4706c821c590',
        'Gnistan',
        'The Spark',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-flame',
        'outline',
        '#db2777',
        NULL,
        NULL,
        '{
            "2026-07-26": [{"from": "00:00", "to": "23:00"}],
            "2026-07-27": [{"from": "09:30", "to": "18:00"}],
            "2026-07-28": [{"from": "09:30", "to": "23:00"}],
            "2026-07-29": [{"from": "09:30", "to": "17:00"}],
            "2026-07-30": [{"from": "09:30", "to": "23:00"}],
            "2026-07-31": [{"from": "09:30", "to": "23:00"}],
            "2026-08-01": [{"from": "09:30", "to": "12:00"}]
        }'::jsonb
    ),
    (
        'b7c1953b-fbc0-5e24-9124-199bb83eec3a',
        'Signalen',
        'The Signal',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-antenna',
        'outline',
        '#4f46e5',
        NULL,
        NULL,
        '{}'::jsonb
    ),
    (
        'b19300df-eec0-5b74-a2eb-772d1950ee26',
        'the HERDS',
        'the HERDS',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-tent',
        'outline',
        '#65a30d',
        NULL,
        NULL,
        '{}'::jsonb
    ),
    (
        'f0d9890d-67f2-56c9-b046-3c495e393dae',
        'Aktivitetsbanken',
        'Aktivitetsbanken',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-building-bank',
        'outline',
        '#2563eb',
        NULL,
        NULL,
        '{
            "2026-07-27": [{"from": "09:00", "to": "12:00"}, {"from": "14:00", "to": "17:00"}],
            "2026-07-28": [{"from": "09:00", "to": "12:00"}, {"from": "14:00", "to": "17:00"}, {"from": "19:00", "to": "22:00"}],
            "2026-07-29": [{"from": "09:00", "to": "12:00"}, {"from": "14:00", "to": "17:00"}],
            "2026-07-30": [{"from": "09:00", "to": "12:00"}, {"from": "14:00", "to": "17:00"}, {"from": "19:00", "to": "22:00"}],
            "2026-07-31": [{"from": "09:00", "to": "12:00"}, {"from": "14:00", "to": "17:00"}, {"from": "19:00", "to": "22:00"}],
            "2026-08-01": [{"from": "09:00", "to": "12:00"}, {"from": "14:00", "to": "17:00"}]
        }'::jsonb
    ),
    (
        'c440eaf2-34c8-53ff-8e45-0f196f8d3f10',
        'Lägerbålsscenen',
        'Lägerbålsscenen',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-music',
        'outline',
        '#dc2626',
        NULL,
        NULL,
        '{
            "2026-07-26": [{"from": "20:00", "to": "21:00"}]
        }'::jsonb
    ),
    (
        'e5918264-9f97-5ec9-8eec-bb488943071e',
        'Oasen',
        'Oasen',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-tent',
        'outline',
        '#16a34a',
        NULL,
        NULL,
        '{
            "2026-07-26": [{"from": "14:00", "to": "17:00"}],
            "2026-07-27": [{"from": "09:00", "to": "17:00"}],
            "2026-07-28": [{"from": "09:00", "to": "17:00"}],
            "2026-07-29": [{"from": "09:00", "to": "17:00"}],
            "2026-07-30": [{"from": "09:00", "to": "17:00"}],
            "2026-07-31": [{"from": "09:00", "to": "17:00"}],
            "2026-08-01": [{"from": "09:00", "to": "17:00"}]
        }'::jsonb
    ),
    (
        '1909ad93-ffb0-5f13-a3ca-724de312bba8',
        'Hjärtat',
        'Hjärtat',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-tent',
        'outline',
        '#ca8a04',
        NULL,
        NULL,
        '{}'::jsonb
    ),
    (
        'bf707c29-099d-509f-b584-207ddd14884f',
        'Andrummet',
        'Andrummet',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-tent',
        'outline',
        '#9333ea',
        NULL,
        NULL,
        '{}'::jsonb
    ),
    (
        '74551559-94b3-54af-a177-41db64d3b0f9',
        'Kontignentstält - Canada',
        'Kontignentstält - Canada',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-tent',
        'outline',
        '#c2410c',
        NULL,
        NULL,
        '{}'::jsonb
    ),
    (
        'cebf5bbf-c478-5109-8d53-566a366ffb45',
        'NSF',
        'NSF',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-tent',
        'outline',
        '#0d9488',
        NULL,
        NULL,
        '{}'::jsonb
    ),
    (
        'b810b555-28a0-57e1-bc54-ed08f477fcbd',
        'Light My Fire',
        'Light My Fire',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-tent',
        'outline',
        '#db2777',
        NULL,
        NULL,
        '{}'::jsonb
    ),
    (
        '13184ac0-3f19-59a8-97e7-f6639e67d847',
        'Morakniv',
        'Morakniv',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-tent',
        'outline',
        '#4f46e5',
        NULL,
        NULL,
        '{}'::jsonb
    ),
    (
        'fc815b6e-716d-5c70-a3a1-e04b6bb34ae9',
        'Accenture',
        'Accenture',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-tent',
        'outline',
        '#65a30d',
        NULL,
        NULL,
        '{
            "2026-07-29": [{"from": "14:00", "to": "17:00"}],
            "2026-07-30": [{"from": "14:00", "to": "17:00"}]
        }'::jsonb
    ),
    (
        '3abaf0b9-aaf7-51b3-b6bf-02e2e00868df',
        'Hundrastgård',
        'Hundrastgård',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-tent',
        'outline',
        '#2563eb',
        NULL,
        NULL,
        '{}'::jsonb
    ),
    (
        '468c6568-2b5b-59db-9eaf-a1fcac55141e',
        'Ledarhänget',
        'Ledarhänget',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-tent',
        'outline',
        '#dc2626',
        NULL,
        NULL,
        '{}'::jsonb
    ),
    (
        '3ef6ac67-e626-5420-a7a0-23e589b76940',
        'Utmanarhubben - Lilla scenen',
        'Utmanarhubben - Lilla scenen',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-music',
        'outline',
        '#16a34a',
        NULL,
        NULL,
        '{
            "2026-07-26": [{"from": "14:00", "to": "00:00"}],
            "2026-07-27": [{"from": "09:00", "to": "17:00"}, {"from": "21:00", "to": "00:00"}],
            "2026-07-28": [{"from": "09:00", "to": "00:00"}],
            "2026-07-29": [{"from": "09:00", "to": "17:00"}],
            "2026-07-30": [{"from": "09:00", "to": "00:00"}],
            "2026-07-31": [{"from": "09:00", "to": "00:00"}],
            "2026-08-01": [{"from": "09:00", "to": "17:00"}, {"from": "21:00", "to": "02:00"}]
        }'::jsonb
    ),
    (
        '28096a60-107b-5452-9898-b3609640ffb9',
        'Utmanarhubben',
        'Utmanarhubben',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-tent',
        'outline',
        '#ca8a04',
        NULL,
        NULL,
        '{
            "2026-07-26": [{"from": "14:00", "to": "00:00"}],
            "2026-07-27": [{"from": "09:00", "to": "17:00"}, {"from": "21:00", "to": "00:00"}],
            "2026-07-28": [{"from": "09:00", "to": "00:00"}],
            "2026-07-29": [{"from": "09:00", "to": "17:00"}],
            "2026-07-30": [{"from": "09:00", "to": "00:00"}],
            "2026-07-31": [{"from": "09:00", "to": "00:00"}],
            "2026-08-01": [{"from": "09:00", "to": "17:00"}, {"from": "21:00", "to": "02:00"}]
        }'::jsonb
    ),
    (
        '8708a2dd-285b-5492-b8a3-36ed62818db2',
        'Upptäckarhubben - Gräset bakom pysslingen',
        'Upptäckarhubben - Gräset bakom pysslingen',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-tent',
        'outline',
        '#9333ea',
        NULL,
        NULL,
        '{
            "2026-07-26": [{"from": "14:00", "to": "21:00"}],
            "2026-07-27": [{"from": "09:00", "to": "17:00"}],
            "2026-07-28": [{"from": "09:00", "to": "21:00"}],
            "2026-07-29": [{"from": "09:00", "to": "17:00"}],
            "2026-07-30": [{"from": "09:00", "to": "21:00"}],
            "2026-07-31": [{"from": "09:00", "to": "21:00"}],
            "2026-08-01": [{"from": "09:00", "to": "17:00"}]
        }'::jsonb
    ),
    (
        '0f29d7b2-b1e9-5371-8dd6-8e967c002208',
        'Upptäckarhubben - infodisken',
        'Upptäckarhubben - infodisken',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-tent',
        'outline',
        '#c2410c',
        NULL,
        NULL,
        '{
            "2026-07-26": [{"from": "14:00", "to": "21:00"}],
            "2026-07-27": [{"from": "09:00", "to": "17:00"}],
            "2026-07-28": [{"from": "09:00", "to": "21:00"}],
            "2026-07-29": [{"from": "09:00", "to": "17:00"}],
            "2026-07-30": [{"from": "09:00", "to": "21:00"}],
            "2026-07-31": [{"from": "09:00", "to": "21:00"}],
            "2026-08-01": [{"from": "09:00", "to": "17:00"}]
        }'::jsonb
    ),
    (
        'c5a754b1-5317-5ee3-a031-49caf710672e',
        'Upptäckarhubben - Skogen',
        'Upptäckarhubben - Skogen',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-tent',
        'outline',
        '#0d9488',
        NULL,
        NULL,
        '{
            "2026-07-26": [{"from": "14:00", "to": "21:00"}],
            "2026-07-27": [{"from": "09:00", "to": "17:00"}],
            "2026-07-28": [{"from": "09:00", "to": "21:00"}],
            "2026-07-29": [{"from": "09:00", "to": "17:00"}],
            "2026-07-30": [{"from": "09:00", "to": "21:00"}],
            "2026-07-31": [{"from": "09:00", "to": "21:00"}],
            "2026-08-01": [{"from": "09:00", "to": "17:00"}]
        }'::jsonb
    ),
    (
        '5b8eccbb-cf63-5818-a6d8-d7c4296d7279',
        'Hinderbanan',
        'Hinderbanan',
        'Plats på lägerområdet.',
        'Venue at the camp site.',
        'tabler-tent',
        'outline',
        '#db2777',
        NULL,
        NULL,
        '{
            "2026-07-26": [{"from": "14:00", "to": "20:00"}],
            "2026-07-27": [{"from": "09:00", "to": "17:00"}],
            "2026-07-28": [{"from": "09:00", "to": "20:00"}],
            "2026-07-29": [{"from": "09:00", "to": "17:00"}],
            "2026-07-30": [{"from": "09:00", "to": "20:00"}],
            "2026-07-31": [{"from": "09:00", "to": "20:00"}],
            "2026-08-01": [{"from": "09:00", "to": "17:00"}]
        }'::jsonb
    )
ON CONFLICT (id) DO NOTHING;

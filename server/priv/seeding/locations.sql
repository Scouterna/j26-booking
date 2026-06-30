INSERT INTO location (
        id,
        name,
        name_en,
        description,
        description_en,
        icon_name,
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
        '#dc2626',
        55.980512,
        14.135702,
        '{}'::jsonb
    );

INSERT INTO location_tag (id, name, name_en, icon_name)
VALUES (
        '0190f3a1-2d3e-7f40-ab51-6c7d8e9f0a1b',
        'Service',
        'Service',
        'tabler-info-circle'
    ),
    (
        '0190f3a1-4f50-7162-cd73-8e9f0a1b2c3d',
        'Sjukvård',
        'Medical',
        'tabler-heartbeat'
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

INSERT INTO activity (
        id,
        title,
        description,
        max_attendees,
        start_time,
        end_time
    )
VALUES (
        '6f5e1d46-5f58-4e23-9a9d-8c2bfc2d22a0',
        'Sång kring lägerelden',
        'En kväll med klassiska scoutsånger kring lägerelden, med marshmallows över glöden.',
        50,
        '2025-07-12 20:00:00',
        '2025-07-12 22:00:00'
    ),
    (
        'b4219a53-4746-4a09-8b4e-3e2ac0c3df11',
        'Orienteringsutmaning',
        'Scouter tar sig genom skogen med endast karta och kompass.',
        30,
        '2025-07-13 10:00:00',
        '2025-07-13 13:00:00'
    ),
    (
        'fa3825ab-8bc1-4f59-9100-2cc6aeb3d219',
        'Sjukvårdsworkshop',
        'Praktisk träning i att hantera vanliga utomhusskador och nödsituationer.',
        25,
        '2025-07-14 09:00:00',
        '2025-07-14 11:30:00'
    ),
    (
        'c10f7b72-cc9d-44a5-9e3f-f0f89b621e3e',
        'Knoptävling',
        'Testa din knopknytning på snabbhet och precision i en rolig tävling.',
        40,
        '2025-07-14 15:00:00',
        '2025-07-14 17:00:00'
    ),
    (
        'd923f1ae-8f8e-45f2-8e7d-89e7d7b4cb75',
        'Naturvandring och djurskådning',
        'En guidad vandring med fokus på att identifiera lokala växter och djur.',
        35,
        '2025-07-15 08:00:00',
        '2025-07-15 12:00:00'
    ),
    -- Punktevenemang (start_time == end_time)
    (
        '0197faa4-e500-7b23-9292-38f7bd41c955',
        'Invigningsceremoni',
        'Välkomsttal och flagghissning som inleder jamboreen.',
        NULL,
        '2025-07-11 18:00:00',
        '2025-07-11 18:00:00'
    ),
    (
        '0197fda5-f000-7c16-ad8e-ba5fe8838e8e',
        'Morgonsamling vid flaggan',
        'Daglig flaggceremoni för att starta dagen tillsammans.',
        NULL,
        '2025-07-12 08:00:00',
        '2025-07-12 08:00:00'
    ),
    (
        '01980596-6880-77c5-bfb3-797743dec7ff',
        'Kvällsreflektion',
        'Kort samling för att reflektera över dagen innan släckning.',
        NULL,
        '2025-07-13 21:00:00',
        '2025-07-13 21:00:00'
    ),
    (
        '01980a85-d600-7e22-8dc6-e1d3a638b02a',
        'Berättarstund',
        'Scoutledare delar legendariska berättelser kring lyktan.',
        NULL,
        '2025-07-14 20:00:00',
        '2025-07-14 20:00:00'
    ),
    (
        '01981352-0880-7df6-9f52-b6ee5d932757',
        'Avslutningsceremoni',
        'Nedhalning av jamboreflaggan som markerar lägrets slut.',
        NULL,
        '2025-07-16 13:00:00',
        '2025-07-16 13:00:00'
    ),
    -- Aktiviteter på befintliga dagar, utan max_attendees
    (
        '0197feef-8700-7663-9871-27951b84a3b7',
        'Hantverksverkstad',
        'Kom förbi och tillverka vänskapsarmband, märken och halsdukringar.',
        NULL,
        '2025-07-12 14:00:00',
        '2025-07-12 16:00:00'
    ),
    (
        '0197ff78-db40-77af-9474-fd036c4b1d64',
        'Patrullekar',
        'Utomhuslekar i samarbete, ledda av patrulledare. Öppet för alla.',
        NULL,
        '2025-07-12 16:30:00',
        '2025-07-12 18:30:00'
    ),
    (
        '01980242-f7c0-712d-9e19-b5dba6525b7c',
        'Fågelskådning i gryningen',
        'Tidig morgonpromenad med kikare för att spana efter lokala fågelarter.',
        NULL,
        '2025-07-13 05:30:00',
        '2025-07-13 07:30:00'
    ),
    (
        '019804ba-ae80-7f7f-ab97-4d876a1425f5',
        'Matlagning över öppen eld',
        'Matlagning över öppen eld — ta med patrullen och en hungrig mage.',
        NULL,
        '2025-07-13 17:00:00',
        '2025-07-13 19:00:00'
    ),
    (
        '01980905-5080-7999-a87f-7877e616357f',
        'Skogsfotografering',
        'Tips och tricks för att fånga naturen med mobil och kamera.',
        NULL,
        '2025-07-14 13:00:00',
        '2025-07-14 15:00:00'
    ),
    (
        '01980e47-23c0-707f-a1e0-0d8e27d8fb79',
        'Täljarverkstad',
        'Lär dig tälja trä säkert med scoutkniv. Knivar finns på plats.',
        NULL,
        '2025-07-15 13:30:00',
        '2025-07-15 15:30:00'
    ),
    (
        '01980f75-4380-73b7-81ad-f8d9391778cb',
        'Talangshow',
        'Patruller anmäler sig på plats för att framföra sketcher, musik och mer.',
        NULL,
        '2025-07-15 19:00:00',
        '2025-07-15 21:00:00'
    ),
    (
        '01980ffe-97c0-707f-97d2-7a30f5ff93aa',
        'Avslutande lägersånger',
        'En sista kväll med sång och avsked runt huvudbålet.',
        NULL,
        '2025-07-15 21:30:00',
        '2025-07-15 23:00:00'
    ),
    -- Aktiviteter på nya dagar
    (
        '0197f8b6-8280-73cc-b398-f6951ce6cfea',
        'Lägerbyggdag',
        'Tältresning och förberedelse av patrullplatser. Hjälp till där du kan.',
        NULL,
        '2025-07-11 09:00:00',
        '2025-07-11 17:00:00'
    ),
    (
        '019812ad-3d00-7178-a029-05bd3b30d54b',
        'Avskedsbrunch',
        'En avslappnad brunch på sista morgonen innan alla åker hem.',
        NULL,
        '2025-07-16 10:00:00',
        '2025-07-16 12:00:00'
    ),
    -- Aktivitet över flera dagar (start- och sluttid på olika dagar)
    (
        '01980483-c000-728f-9bbb-9fb05bb5fc59',
        'Övernattningsvandring',
        'Vandra ut, sov under tarp och återvänd i gryningen. För erfarna scouter.',
        NULL,
        '2025-07-13 16:00:00',
        '2025-07-14 08:00:00'
    ),
    -- Ytterligare ett par med max_attendees, så att de flesta aktiviteter är obegränsade
    (
        '01980860-8500-7d9a-a4c0-359d166e4010',
        'Surrning och pionjärarbete',
        'Bygg en liten port av rep och stänger. Begränsat antal platser på grund av materialet.',
        20,
        '2025-07-14 10:00:00',
        '2025-07-14 12:00:00'
    ),
    (
        '01980d86-e100-7af8-8016-bbc7909dd5ae',
        'Säkert bad i sjön',
        'Övervakat bad i sjön. Livräddare på plats.',
        25,
        '2025-07-15 10:00:00',
        '2025-07-15 12:00:00'
    );

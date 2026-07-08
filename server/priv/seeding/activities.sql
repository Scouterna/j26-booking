INSERT INTO activity (
        id,
        title,
        title_en,
        description,
        description_en,
        max_attendees,
        start_time,
        end_time
    )
VALUES (
        '6f5e1d46-5f58-4e23-9a9d-8c2bfc2d22a0',
        'Sång kring lägerelden',
        'Campfire Songs',
        'En kväll med klassiska scoutsånger kring lägerelden, med marshmallows över glöden.',
        'An evening of classic scout songs around the campfire, with marshmallows over the embers.',
        50,
        '2025-07-12 20:00:00',
        '2025-07-12 22:00:00'
    ),
    (
        'b4219a53-4746-4a09-8b4e-3e2ac0c3df11',
        'Orienteringsutmaning',
        'Orienteering Challenge',
        'Scouter tar sig genom skogen med endast karta och kompass.',
        'Scouts make their way through the forest with only a map and compass.',
        30,
        '2025-07-13 10:00:00',
        '2025-07-13 13:00:00'
    ),
    (
        'fa3825ab-8bc1-4f59-9100-2cc6aeb3d219',
        'Sjukvårdsworkshop',
        'First Aid Workshop',
        'Praktisk träning i att hantera vanliga utomhusskador och nödsituationer.',
        'Hands-on training in handling common outdoor injuries and emergencies.',
        25,
        '2025-07-14 09:00:00',
        '2025-07-14 11:30:00'
    ),
    (
        'c10f7b72-cc9d-44a5-9e3f-f0f89b621e3e',
        'Knoptävling',
        'Knot-Tying Contest',
        'Testa din knopknytning på snabbhet och precision i en rolig tävling.',
        'Test your knot-tying for speed and precision in a fun contest.',
        40,
        '2025-07-14 15:00:00',
        '2025-07-14 17:00:00'
    ),
    (
        'd923f1ae-8f8e-45f2-8e7d-89e7d7b4cb75',
        'Naturvandring och djurskådning',
        'Nature Walk and Wildlife Watching',
        'En guidad vandring med fokus på att identifiera lokala växter och djur.',
        'A guided walk focused on identifying local plants and animals.',
        35,
        '2025-07-15 08:00:00',
        '2025-07-15 12:00:00'
    ),
    -- Punktevenemang (start_time == end_time)
    (
        '0197faa4-e500-7b23-9292-38f7bd41c955',
        'Invigningsceremoni',
        'Opening Ceremony',
        'Välkomsttal och flagghissning som inleder jamboreen.',
        'Welcome speeches and flag raising that open the jamboree.',
        NULL,
        '2025-07-11 18:00:00',
        '2025-07-11 18:00:00'
    ),
    (
        '0197fda5-f000-7c16-ad8e-ba5fe8838e8e',
        'Morgonsamling vid flaggan',
        'Morning Flag Gathering',
        'Daglig flaggceremoni för att starta dagen tillsammans.',
        'Daily flag ceremony to start the day together.',
        NULL,
        '2025-07-12 08:00:00',
        '2025-07-12 08:00:00'
    ),
    (
        '01980596-6880-77c5-bfb3-797743dec7ff',
        'Kvällsreflektion',
        'Evening Reflection',
        'Kort samling för att reflektera över dagen innan släckning.',
        'A short gathering to reflect on the day before lights-out.',
        NULL,
        '2025-07-13 21:00:00',
        '2025-07-13 21:00:00'
    ),
    (
        '01980a85-d600-7e22-8dc6-e1d3a638b02a',
        'Berättarstund',
        'Storytelling Time',
        'Scoutledare delar legendariska berättelser kring lyktan.',
        'Scout leaders share legendary stories around the lantern.',
        NULL,
        '2025-07-14 20:00:00',
        '2025-07-14 20:00:00'
    ),
    (
        '01981352-0880-7df6-9f52-b6ee5d932757',
        'Avslutningsceremoni',
        'Closing Ceremony',
        'Nedhalning av jamboreflaggan som markerar lägrets slut.',
        'Lowering of the jamboree flag marking the end of the camp.',
        NULL,
        '2025-07-16 13:00:00',
        '2025-07-16 13:00:00'
    ),
    -- Aktiviteter på befintliga dagar, utan max_attendees
    (
        '0197feef-8700-7663-9871-27951b84a3b7',
        'Hantverksverkstad',
        'Craft Workshop',
        'Kom förbi och tillverka vänskapsarmband, märken och halsdukringar.',
        'Drop by and make friendship bracelets, badges, and neckerchief slides.',
        NULL,
        '2025-07-12 14:00:00',
        '2025-07-12 16:00:00'
    ),
    (
        '0197ff78-db40-77af-9474-fd036c4b1d64',
        'Patrullekar',
        'Patrol Games',
        'Utomhuslekar i samarbete, ledda av patrulledare. Öppet för alla.',
        'Cooperative outdoor games led by patrol leaders. Open to everyone.',
        NULL,
        '2025-07-12 16:30:00',
        '2025-07-12 18:30:00'
    ),
    (
        '01980242-f7c0-712d-9e19-b5dba6525b7c',
        'Fågelskådning i gryningen',
        'Dawn Birdwatching',
        'Tidig morgonpromenad med kikare för att spana efter lokala fågelarter.',
        'An early morning walk with binoculars to spot local bird species.',
        NULL,
        '2025-07-13 05:30:00',
        '2025-07-13 07:30:00'
    ),
    (
        '019804ba-ae80-7f7f-ab97-4d876a1425f5',
        'Matlagning över öppen eld',
        'Open-Fire Cooking',
        'Matlagning över öppen eld — ta med patrullen och en hungrig mage.',
        'Cooking over an open fire — bring your patrol and a hungry stomach.',
        NULL,
        '2025-07-13 17:00:00',
        '2025-07-13 19:00:00'
    ),
    (
        '01980905-5080-7999-a87f-7877e616357f',
        'Skogsfotografering',
        'Forest Photography',
        'Tips och tricks för att fånga naturen med mobil och kamera.',
        'Tips and tricks for capturing nature with your phone and camera.',
        NULL,
        '2025-07-14 13:00:00',
        '2025-07-14 15:00:00'
    ),
    (
        '01980e47-23c0-707f-a1e0-0d8e27d8fb79',
        'Täljarverkstad',
        'Whittling Workshop',
        'Lär dig tälja trä säkert med scoutkniv. Knivar finns på plats.',
        'Learn to whittle wood safely with a scout knife. Knives provided on site.',
        NULL,
        '2025-07-15 13:30:00',
        '2025-07-15 15:30:00'
    ),
    (
        '01980f75-4380-73b7-81ad-f8d9391778cb',
        'Talangshow',
        'Talent Show',
        'Patruller anmäler sig på plats för att framföra sketcher, musik och mer.',
        'Patrols sign up on site to perform sketches, music, and more.',
        NULL,
        '2025-07-15 19:00:00',
        '2025-07-15 21:00:00'
    ),
    (
        '01980ffe-97c0-707f-97d2-7a30f5ff93aa',
        'Avslutande lägersånger',
        'Closing Campfire Songs',
        'En sista kväll med sång och avsked runt huvudbålet.',
        'A final evening of song and farewells around the main campfire.',
        NULL,
        '2025-07-15 21:30:00',
        '2025-07-15 23:00:00'
    ),
    -- Aktiviteter på nya dagar
    (
        '0197f8b6-8280-73cc-b398-f6951ce6cfea',
        'Lägerbyggdag',
        'Camp Build Day',
        'Tältresning och förberedelse av patrullplatser. Hjälp till där du kan.',
        'Pitching tents and preparing patrol sites. Help out where you can.',
        NULL,
        '2025-07-11 09:00:00',
        '2025-07-11 17:00:00'
    ),
    (
        '019812ad-3d00-7178-a029-05bd3b30d54b',
        'Avskedsbrunch',
        'Farewell Brunch',
        'En avslappnad brunch på sista morgonen innan alla åker hem.',
        'A relaxed brunch on the final morning before everyone heads home.',
        NULL,
        '2025-07-16 10:00:00',
        '2025-07-16 12:00:00'
    ),
    -- Aktivitet över flera dagar (start- och sluttid på olika dagar)
    (
        '01980483-c000-728f-9bbb-9fb05bb5fc59',
        'Övernattningsvandring',
        'Overnight Hike',
        'Vandra ut, sov under tarp och återvänd i gryningen. För erfarna scouter.',
        'Hike out, sleep under a tarp, and return at dawn. For experienced scouts.',
        NULL,
        '2025-07-13 16:00:00',
        '2025-07-14 08:00:00'
    ),
    -- Ytterligare ett par med max_attendees, så att de flesta aktiviteter är obegränsade
    (
        '01980860-8500-7d9a-a4c0-359d166e4010',
        'Surrning och pionjärarbete',
        'Lashing and Pioneering',
        'Bygg en liten port av rep och stänger. Begränsat antal platser på grund av materialet.',
        'Build a small gateway from ropes and poles. Limited spots due to materials.',
        20,
        '2025-07-14 10:00:00',
        '2025-07-14 12:00:00'
    ),
    (
        '01980d86-e100-7af8-8016-bbc7909dd5ae',
        'Säkert bad i sjön',
        'Safe Lake Swimming',
        'Övervakat bad i sjön. Livräddare på plats.',
        'Supervised swimming in the lake. Lifeguards on site.',
        25,
        '2025-07-15 10:00:00',
        '2025-07-15 12:00:00'
    );

-- Återkommande specialaktiviteter: badbuss & klättervägg.
-- Många bokningsbara tider som delar titel/beskrivning men varierar i
-- tid och antal platser. Identifieras av recurring_activity_kind (slug).
INSERT INTO activity (
        id,
        title,
        title_en,
        description,
        description_en,
        max_attendees,
        start_time,
        end_time,
        recurring_activity_kind
    )
VALUES (
        '0198a000-0000-7000-8000-000000000001',
        'Badbuss',
        'Swim Bus',
        'Buss till badplatsen och tillbaka. Begränsat antal platser per avgång.',
        'Bus to the swimming spot and back. Limited spots per departure.',
        30,
        '2025-07-12 09:00:00',
        '2025-07-12 12:00:00',
        'swim-bus'
    ),
    (
        '0198a000-0000-7000-8000-000000000002',
        'Badbuss',
        'Swim Bus',
        'Buss till badplatsen och tillbaka. Begränsat antal platser per avgång.',
        'Bus to the swimming spot and back. Limited spots per departure.',
        30,
        '2025-07-12 13:00:00',
        '2025-07-12 16:00:00',
        'swim-bus'
    ),
    (
        '0198a000-0000-7000-8000-000000000003',
        'Badbuss',
        'Swim Bus',
        'Buss till badplatsen och tillbaka. Begränsat antal platser per avgång.',
        'Bus to the swimming spot and back. Limited spots per departure.',
        40,
        '2025-07-13 09:00:00',
        '2025-07-13 12:00:00',
        'swim-bus'
    ),
    (
        '0198a000-0000-7000-8000-000000000004',
        'Badbuss',
        'Swim Bus',
        'Buss till badplatsen och tillbaka. Begränsat antal platser per avgång.',
        'Bus to the swimming spot and back. Limited spots per departure.',
        40,
        '2025-07-13 13:00:00',
        '2025-07-13 16:00:00',
        'swim-bus'
    ),
    (
        '0198b000-0000-7000-8000-000000000001',
        'Klättervägg',
        'Climbing Wall',
        'Prova på klättring med instruktör och säkerhetsutrustning.',
        'Try climbing with an instructor and safety equipment.',
        12,
        '2025-07-12 10:00:00',
        '2025-07-12 11:00:00',
        'climbing-wall'
    ),
    (
        '0198b000-0000-7000-8000-000000000002',
        'Klättervägg',
        'Climbing Wall',
        'Prova på klättring med instruktör och säkerhetsutrustning.',
        'Try climbing with an instructor and safety equipment.',
        12,
        '2025-07-12 11:00:00',
        '2025-07-12 12:00:00',
        'climbing-wall'
    ),
    (
        '0198b000-0000-7000-8000-000000000003',
        'Klättervägg',
        'Climbing Wall',
        'Prova på klättring med instruktör och säkerhetsutrustning.',
        'Try climbing with an instructor and safety equipment.',
        12,
        '2025-07-13 10:00:00',
        '2025-07-13 11:00:00',
        'climbing-wall'
    ),
    (
        '0198b000-0000-7000-8000-000000000004',
        'Klättervägg',
        'Climbing Wall',
        'Prova på klättring med instruktör och säkerhetsutrustning.',
        'Try climbing with an instructor and safety equipment.',
        8,
        '2025-07-13 11:00:00',
        '2025-07-13 12:00:00',
        'climbing-wall'
    );

-- Assign a few activities to real locations (seeded in locations.sql). The
-- remaining activities keep location_id NULL to exercise the no-location path.
UPDATE activity
SET location_id = '0190f3a1-1c2d-7e3f-9a4b-5c6d7e8f9a0b' -- Infotält
WHERE id IN (
    '6f5e1d46-5f58-4e23-9a9d-8c2bfc2d22a0',
    'fa3825ab-8bc1-4f59-9100-2cc6aeb3d219',
    '0197faa4-e500-7b23-9292-38f7bd41c955'
);

UPDATE activity
SET location_id = '0190f3a1-3e4f-7051-bc62-7d8e9f0a1b2c' -- Sjukvårdstält
WHERE id IN (
    'b4219a53-4746-4a09-8b4e-3e2ac0c3df11',
    'c10f7b72-cc9d-44a5-9e3f-f0f89b621e3e'
);

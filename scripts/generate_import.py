"""Generate the real-import SQL from the "Platser och aktiviteter" workbook
and the recurring-activity schedules (badbuss, klattervagg) from one workbook
each.

Emits INSERT statements into server/priv/import/ (same style as
server/priv/seeding/*.sql):

- "Platser"            -> location rows (+ opening_hours JSONB per date). Its
                          description columns (Swedish, and English once the
                          sheet has one) are found by header text, since the
                          sheet keeps gaining columns.
- "Kategorier"         -> activity_tag rows
- one sheet per day    -> activity rows (+ tag links and target groups)
- "Appen" (badbuss)    -> one beach-bus activity row per slot and day
- "Blad1" (klattervagg) -> one climbing-wall activity row per slot and day

locations.sql starts by TRUNCATE-ing every app table (bookings, favourites,
call-offs and users included -- users are upserted again on login), so running
the import wipes all existing data. Run locations.sql first, then
activities.sql, then the recurring files.

Both recurring workbooks hold a dateless daily template of slots, and both run
26-31 July, but they disagree on the tab name and the column order, and only
the badbuss has the per-day deviation columns (see RECURRING_IMPORTS).
Slots have no end time -- end_time is set equal to start_time, which the client
renders as a single clock time. Where deviations exist: on 28/7
(Tillsammansfesten) slots with text in that column use its funktionar-only
description and are tagged with target_group 'funktionar'; on 31/7 (Avslutning)
slots marked "Ej bokningsbar" are skipped and the rest take the column's
description. The sheets have no English text, so description_en falls back to
Swedish.

Imported per activity: title, title_en, description, description_en,
max_attendees (only when "Kraver bokning" is true), start_time, end_time,
location_id (Plats), its Kategori as an activity_tag link, and
activity_target_group rows for the Upptackare/Aventyrare/Utmanare/Rover/
Ledare/Funktionarer columns. Activities marked "Dold i appen" are skipped
entirely. "Agare" and the "Sektion" column of the Platser sheet have nowhere
to go and are dropped.

Times in the sheet are camp-local (Europe/Stockholm, UTC+2 during the camp)
and are converted to UTC before insert, since the activity table stores naive
UTC timestamps.

An activity is bookable in the app if and only if max_attendees is set, so
"Kraver bokning" rows whose Maxantal is empty or not a number ("10 lag",
"8 bollar") are imported as NOT bookable, with a warning -- fix the sheet and
re-run to make them bookable.

The workbook is read with python-calamine rather than openpyxl: the exports
we get contain font definitions openpyxl refuses to parse.

Requires: pip install python-calamine

Usage: python3 generate_import.py [program.xlsx [badbuss.xlsx [klattervagg.xlsx]]]
Output: server/priv/import/{locations,activities,badbuss,klattervagg}.sql
        (each recurring file only when its workbook is given)
"""

from __future__ import annotations

import re
import sys
import uuid
from collections import Counter
from datetime import date, datetime, time, timedelta, timezone
from pathlib import Path
from typing import NamedTuple
from zoneinfo import ZoneInfo

from python_calamine import CalamineWorkbook

SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_WORKBOOK_PATH = SCRIPT_DIR / "platser_och_aktiviteter.xlsx"
OUTPUT_DIR = SCRIPT_DIR.parent / "server" / "priv" / "import"
LOCATIONS_OUTPUT_PATH = OUTPUT_DIR / "locations.sql"
ACTIVITIES_OUTPUT_PATH = OUTPUT_DIR / "activities.sql"
BADBUSS_OUTPUT_PATH = OUTPUT_DIR / "badbuss.sql"
KLATTERVAGG_OUTPUT_PATH = OUTPUT_DIR / "klattervagg.sql"
# Every file concatenated inside one transaction, for importing through a
# GUI SQL client where running the files separately and in the right order is
# easy to get wrong -- and where getting it wrong shows up as a confusing
# activity_target_group foreign key violation rather than "you skipped
# locations.sql".
COMBINED_OUTPUT_PATH = OUTPUT_DIR / "import_all.sql"

YEAR = 2026
# The sheet's times are wall-clock times at the camp; the activity table's
# TIMESTAMP columns are read by the server as UTC.
CAMP_TZ = ZoneInfo("Europe/Stockholm")
MONTH_NAMES = {"juli": 7, "augusti": 8}
DAY_SHEET_NAMES = [
    "25 juli",
    "26 juli",
    "27 juli",
    "28 juli",
    "29 juli",
    "30 juli",
    "31 juli",
    "1 augusti",
]

# Day-sheet columns (0-indexed) whose True/False marks a target group, and the
# target_group enum value each maps to.
TARGET_GROUP_COLUMNS = [
    (5, "upptackare"),
    (6, "aventyrare"),
    (7, "utmanare"),
    (8, "rover"),
    (9, "ledare"),
    (10, "funktionar"),
]

# Plats spellings in the day sheets that don't match the Platser sheet but
# clearly mean an existing location. Keys and values are normalize_name'd.
LOCATION_ALIASES = {
    "utmanarhubb-brädspelstält": "utmanarhubben-brädspelstält",
    "utmanarhubb-cafetält": "utmanarhubben-cafetält",
    "utmanarhubb-storatältet": "utmanarhubben-storatältet",
}

# The recurring-activity schedules (badbuss, klattervagg): each workbook's
# Appen tab is a daily template without dates; these are the days they run.
RECURRING_DAYS = [date(YEAR, 7, day) for day in range(26, 32)]
TILLSAMMANS_DAY = date(YEAR, 7, 28)  # column "Avvikelser Tillsammman..."
AVSLUTNING_DAY = date(YEAR, 7, 31)  # column "Avvikelse Avslutning..."
NOT_BOOKABLE_MARKER = "ej bokningsbar"


class RecurringImport(NamedTuple):
    """One recurring-activity workbook. Both hold the same shape of sheet -- a
    dateless daily template of slots -- but they disagree on what the tab is
    called and where the columns sit, and only the badbuss has the per-day
    deviation columns."""

    kind: str  # activity.recurring_activity_kind
    # stable_id namespace. Never change an existing one -- it would renumber
    # every already-imported row of that kind.
    id_kind: str
    title: str
    title_en: str
    label: str  # how warnings and generated comments name the thing
    source: str  # the workbook, for the generated file's header comment
    output_path: Path
    days: list[date]
    sheet_name: str  # the tab holding the daily template
    # 0-indexed columns of that sheet. The deviation columns are None for
    # sheets that don't have them, which makes every day of that kind
    # identical.
    start_time_column: int
    max_attendees_column: int
    description_column: int
    tillsammans_column: int | None
    avslutning_column: int | None


RECURRING_IMPORTS = [
    RecurringImport(
        kind="beach-bus",
        id_kind="badbuss",
        title="Badbuss",
        title_en="Beach Bus",
        label="badbuss",
        source="Ide korschema FL",
        output_path=BADBUSS_OUTPUT_PATH,
        days=RECURRING_DAYS,
        sheet_name="Appen",
        # Kl, Slot, Turer, Antal bussar, Platser per slot, Bokningsbara
        # platser, (blank), Beskrivning till app, Avvikelser
        # Tillsammmansfesten 28/7, Avvikelse Avslutning 31/7. Columns 1-4 are
        # bus logistics and unused.
        start_time_column=0,
        max_attendees_column=5,
        description_column=7,
        tillsammans_column=8,
        avslutning_column=9,
    ),
    RecurringImport(
        kind="climbing-wall",
        id_kind="climbing-wall",
        title="Klättervägg",
        title_en="Climbing Wall",
        label="klattervagg",
        source="klättervägg",
        output_path=KLATTERVAGG_OUTPUT_PATH,
        days=RECURRING_DAYS,
        sheet_name="Blad1",
        # Kl, Platser per slot (unused), Bokningsbara platser, Beskrivning
        # till app. No deviation columns: every day is the same.
        start_time_column=0,
        max_attendees_column=2,
        description_column=3,
        tillsammans_column=None,
        avslutning_column=None,
    ),
]

# Placeholders for location fields the spreadsheet doesn't provide.
DEFAULT_ICON_NAME = "tabler-map-pin"
DEFAULT_ICON_VARIANT = "outline"
DEFAULT_COLOR = "#6b7280"

# Every app table, in FK-safe order; _migrations is deliberately absent.
APP_TABLES = [
    "booking",
    "call_off",
    "favourite",
    "activity_user",
    "activity_target_group",
    "activity_tag_activity",
    "activity_tag",
    "activity",
    "location_tag_location",
    "location_tag",
    "location",
    '"user"',
]

TIME_RANGE_RE = re.compile(r"(\d{1,2})[:.](\d{2})\s*-\s*(\d{1,2})[:.](\d{2})")
TIME_RE = re.compile(r"(\d{1,2})[:.](\d{2})(?::(\d{2}))?")


# Namespace for the UUIDv5 row ids. Ids are derived from the sheet content
# rather than random so that regenerating produces the same ids: activity rows
# reference location ids, so with random ids a fresh activities.sql only works
# against a location table loaded from the very same run, and mixing
# generations fails with a location_id foreign key violation (which then shows
# up as activity_id violations on the link tables). Never change this value --
# it would renumber every row in an already-imported database.
IMPORT_NAMESPACE = uuid.UUID("5f5a1cb0-1f3d-5c7e-9c3a-2a1e0d5b7f10")

_ID_OCCURRENCES: Counter[str] = Counter()


def stable_id(kind: str, *parts: str) -> str:
    """A deterministic id for one row, derived from what identifies it in the
    sheet. The sheet does contain genuine duplicate rows (same title, same
    times, imported twice on purpose), so identical keys get a per-occurrence
    suffix; that stays stable as long as the duplicates keep their sheet
    order."""
    key = "|".join((kind,) + parts)
    _ID_OCCURRENCES[key] += 1
    occurrence = _ID_OCCURRENCES[key]
    if occurrence > 1:
        key = f"{key}#{occurrence}"
    return str(uuid.uuid5(IMPORT_NAMESPACE, key))


def cell_str(value: object) -> str | None:
    """A cell's text content, or None for empty/whitespace-only cells."""
    if value is None:
        return None
    text = str(value).strip()
    return text or None


def normalize_name(name: str) -> str:
    """Key used to match activity Plats/Kategori against the Platser/
    Kategorier sheets: the sheets disagree on casing ("lek" vs "Lek") and on
    spacing around dashes ("Utmanarhubben- Lilla scenen")."""
    return re.sub(r"\s+", "", name).casefold()


def parse_swedish_date(label: str) -> date:
    day_str, month_name = label.strip().split(" ", 1)
    return date(YEAR, MONTH_NAMES[month_name.strip()], int(day_str))


def parse_time_cell(value: object) -> time | None:
    """A Starttid/Sluttid cell: usually a real time cell, but a handful are
    text like "09.00" or "19.30"."""
    if isinstance(value, time):
        return value
    if isinstance(value, datetime):
        return value.time()
    text = cell_str(value)
    if text is None:
        return None
    match = TIME_RE.fullmatch(text)
    if match is None:
        return None
    return time(int(match[1]), int(match[2]), int(match[3] or 0))


def parse_coordinate_cell(value: object) -> float | None:
    if isinstance(value, bool):
        return None
    if isinstance(value, (int, float)):
        return float(value)
    text = cell_str(value)
    return float(text) if text is not None else None


def parse_bool_cell(value: object) -> bool:
    if isinstance(value, bool):
        return value
    return (cell_str(value) or "").casefold() == "true"


def parse_max_attendees(value: object) -> tuple[int | None, str | None]:
    """Returns (max_attendees, unusable_text). Numbers come through as
    floats; some cells are text like "10 lag" or "8 bollar" that we cannot
    map to a per-person count."""
    if isinstance(value, bool):
        return None, str(value)
    if isinstance(value, (int, float)):
        return int(value), None
    text = cell_str(value)
    if text is None:
        return None, "(empty)"
    if re.fullmatch(r"\d+", text):
        return int(text), None
    return None, repr(text)


def parse_opening_hours_cell(text: str | None) -> list[tuple[str, str]]:
    """Extract (from, to) HH:MM pairs from a free-text opening-hours cell.

    Cells mix separators (space, comma, newline) and typos (`.` instead of
    `:`, unpadded hours), so this scans for "H(:|.)MM - H(:|.)MM" patterns
    rather than splitting on a fixed delimiter.
    """
    if not text:
        return []
    ranges = []
    for from_h, from_m, to_h, to_m in TIME_RANGE_RE.findall(text):
        ranges.append((f"{int(from_h):02d}:{from_m}", f"{int(to_h):02d}:{to_m}"))
    return ranges


def to_utc(d: date, t: time) -> datetime:
    return datetime.combine(d, t, tzinfo=CAMP_TZ).astimezone(timezone.utc)


def sql_str(value: str | None) -> str:
    """Render a text value as an SQL literal that survives naive SQL clients.

    Postgres itself is happy with any quote-doubled literal, but the GUI
    clients people run these files in (DBeaver, DataGrip) split the file into
    statements with their own parsers, and the sheet text is full of sequences
    those parsers act on even though they sit inside a string: paragraph
    breaks (a blank line ends a statement), "--" and "/*" (comment starts
    that eat the closing quote and desync every literal after it), ";"
    (statement terminator), ":word" and "?" (JDBC parameter placeholders).
    Each of those turns the one big INSERT into fragments that fail, which
    then shows up as a foreign key violation on the link tables further down.

    So anything hazardous is written as an escape-string escape instead of the
    character itself. The value Postgres stores is unchanged; only the
    on-disk spelling differs. Every escape used here is fixed-width (\\xhh
    consumes at most two hex digits), so a following hex digit in the text
    cannot extend it.
    """
    if value is None:
        return "NULL"
    escaped = value.replace("'", "''")
    hazards = (
        ("\\", "\\\\"),  # first: later replacements introduce backslashes
        ("\r\n", "\\n"),
        ("\r", "\\n"),
        ("\n", "\\n"),
        (";", "\\x3B"),
        ("?", "\\x3F"),
        ("--", "-\\x2D"),
        ("/*", "/\\x2A"),
        ("*/", "*\\x2F"),
    )
    needs_escaping = any(needle in escaped for needle, _ in hazards)
    # ":word" is a named JDBC parameter; a bare ":" is harmless.
    needs_escaping = needs_escaping or re.search(r":\w", escaped) is not None
    if not needs_escaping:
        return "'" + escaped + "'"
    for needle, replacement in hazards:
        escaped = escaped.replace(needle, replacement)
    escaped = re.sub(r":(?=\w)", "\\\\x3A", escaped)
    return "E'" + escaped + "'"


BATCH_SIZE = 100


def insert_statements(header: str, values: list[str]) -> str:
    """Render `values` as one INSERT statement per BATCH_SIZE rows.

    All of these tables would fit in a single statement, but that makes the
    activity insert a few hundred kilobytes of SQL in one go, which some
    clients refuse to run, and it means one bad row takes the whole import
    with it. Batching keeps every statement small and points a failure at the
    rows it came from. `header` is everything up to (not including) VALUES.
    """
    return "\n".join(
        header + "VALUES\n" + ",\n".join(values[start : start + BATCH_SIZE]) + ";"
        for start in range(0, len(values), BATCH_SIZE)
    )


def sql_int(value: int | None) -> str:
    return "NULL" if value is None else str(value)


def sql_float(value: float | None) -> str:
    return "NULL" if value is None else repr(float(value))


def sql_timestamp(dt: datetime) -> str:
    return f"'{dt:%Y-%m-%d %H:%M:%S}'"


def sql_jsonb_opening_hours(opening_hours: dict[str, list[tuple[str, str]]]) -> str:
    if not opening_hours:
        return "'{}'::jsonb"
    date_entries = []
    for iso_date in sorted(opening_hours):
        ranges = ",\n".join(
            f'                {{"from": "{f}", "to": "{t}"}}'
            for f, t in opening_hours[iso_date]
        )
        date_entries.append(f'            "{iso_date}": [\n{ranges}\n            ]')
    body = ",\n".join(date_entries)
    return f"'{{\n{body}\n        }}'::jsonb"


def sheet_rows(wb: CalamineWorkbook, name: str) -> list[list[object]]:
    """Rows padded to a uniform width (calamine trims trailing empties)."""
    rows = wb.get_sheet_by_name(name).to_python()
    width = max((len(row) for row in rows), default=0)
    return [list(row) + [None] * (width - len(row)) for row in rows]


def platser_columns(header_row: list[object]) -> dict[str, int | None]:
    """Locate the Platser sheet's columns after the eight day columns.

    These are matched by header text rather than by position: the sheet gains
    columns over time (the English description was added beside the Swedish
    one), which shifts everything to its right. A fixed index would then read
    the description as a latitude and fail somewhere far away.

    Returns None for the English description when the column isn't there yet,
    in which case the Swedish text is used for both.
    """
    headers = {}
    for index, cell in enumerate(header_row[10:], start=10):
        text = (cell_str(cell) or "").casefold()
        if not text:
            continue
        if "beskrivning" in text:
            headers["description_en" if "engelsk" in text else "description"] = index
        elif text.startswith("latitud"):
            headers["latitude"] = index
        elif text.startswith("longitud"):
            headers["longitude"] = index
    missing = [
        name
        for name in ("description", "latitude", "longitude")
        if name not in headers
    ]
    if missing:
        raise ValueError(
            "Platser sheet is missing the "
            f"{', '.join(missing)} column(s); headers from column 11 on are "
            f"{[cell_str(c) for c in header_row[10:]]}"
        )
    headers.setdefault("description_en", None)
    return headers


def read_locations(wb: CalamineWorkbook) -> tuple[list[dict], list[str]]:
    # Row 0 is a merged note, row 1 the headers. Columns: 0 = Namn,
    # 1 = Sektion (unused), 2-9 = one per camp day; the description,
    # description-in-English, Latitud and Longitud columns are found by header
    # text because the sheet keeps gaining columns.
    rows = sheet_rows(wb, "Platser")
    day_headers = rows[1][2:10]
    columns = platser_columns(rows[1])
    warnings = []
    if columns["description_en"] is None:
        warnings.append(
            "Platser sheet has no English description column; the Swedish "
            "description is used for description_en"
        )
    locations = []
    for row in rows[2:]:
        name = cell_str(row[0])
        if not name:
            continue
        opening_hours = {}
        for header, cell in zip(day_headers, row[2:10]):
            ranges = parse_opening_hours_cell(cell_str(cell))
            if ranges:
                opening_hours[parse_swedish_date(str(header)).isoformat()] = ranges
        description = cell_str(row[columns["description"]]) or ""
        description_en = (
            None
            if columns["description_en"] is None
            else cell_str(row[columns["description_en"]])
        )
        locations.append(
            {
                "id": stable_id("location", name),
                "name": name,
                "description": description,
                # description_en is NOT NULL; fall back to the Swedish text
                # like the activity import does, and treat "-" as a
                # deliberately empty English cell.
                "description_en": description
                if description_en in (None, "-")
                else description_en,
                "latitude": parse_coordinate_cell(row[columns["latitude"]]),
                "longitude": parse_coordinate_cell(row[columns["longitude"]]),
                "opening_hours": opening_hours,
            }
        )
    return locations, warnings


def read_tags(wb: CalamineWorkbook) -> list[dict]:
    rows = sheet_rows(wb, "Kategorier")
    names = []
    for row in rows[1:]:
        name = cell_str(row[0])
        if name:
            names.append(name)
    return [
        {"id": stable_id("activity_tag", name), "name": name} for name in names
    ]


def read_activities(wb: CalamineWorkbook) -> tuple[list[dict], list[str], list[str]]:
    activities = []
    skipped = []
    warnings = []
    for sheet_name in DAY_SHEET_NAMES:
        activity_date = parse_swedish_date(sheet_name)
        for row in sheet_rows(wb, sheet_name)[1:]:
            name = cell_str(row[0])
            if not name or name.startswith("Exempel"):
                continue
            if parse_bool_cell(row[16]):
                skipped.append(f'{sheet_name}: {name} (marked "Dold i appen")')
                continue
            start_time = parse_time_cell(row[12])
            end_time = parse_time_cell(row[13])
            if start_time is None or end_time is None:
                skipped.append(f"{sheet_name}: {name} (missing start/end time)")
                continue
            start = to_utc(activity_date, start_time)
            end = to_utc(activity_date, end_time)
            if end <= start:
                end += timedelta(days=1)
                warnings.append(
                    f"{sheet_name}: {name} ends at/before its start; assumed "
                    "it runs past midnight"
                )
            bookable = parse_bool_cell(row[15])
            max_attendees = None
            if bookable:
                max_attendees, unusable_max = parse_max_attendees(row[14])
                if max_attendees is None:
                    warnings.append(
                        f"{sheet_name}: {name} requires booking but Maxantal "
                        f"is {unusable_max}; imported as NOT bookable -- fix "
                        "the sheet and re-run"
                    )
            title_en = cell_str(row[1])
            description_en = cell_str(row[3])
            description = cell_str(row[2]) or ""
            activities.append(
                {
                    "id": stable_id(
                        "activity", sheet_name, name, start.isoformat(), end.isoformat()
                    ),
                    "title": name,
                    # title_en/description_en are NOT NULL; fall back to the
                    # Swedish text like the bilingual migration did. "-" marks
                    # a deliberately empty English cell in the sheet.
                    "title_en": name if title_en in (None, "-") else title_en,
                    "description": description,
                    "description_en": description
                    if description_en in (None, "-")
                    else description_en,
                    "max_attendees": max_attendees,
                    "start": start,
                    "end": end,
                    "category": cell_str(row[4]),
                    "location_name": cell_str(row[11]),
                    "location_id": None,
                    "tag_id": None,
                    "target_groups": [
                        group
                        for column, group in TARGET_GROUP_COLUMNS
                        if parse_bool_cell(row[column])
                    ],
                }
            )
    return activities, skipped, warnings


def read_recurring_slots(
    wb: CalamineWorkbook, config: RecurringImport
) -> list[dict]:
    """The daily-template tab: row 0 headers, then one row per daily slot until
    the TOTALT summary row (which has no time and so is skipped along with any
    other timeless row). Which tab, and which column holds what, is per
    workbook -- see RECURRING_IMPORTS."""

    def deviation(row: list[object], column: int | None) -> str | None:
        return None if column is None else cell_str(row[column])

    if config.sheet_name not in wb.sheet_names:
        raise ValueError(
            f"{config.label} workbook has no {config.sheet_name!r} tab; its "
            f"tabs are {wb.sheet_names}"
        )
    slots = []
    for row in sheet_rows(wb, config.sheet_name)[1:]:
        start_time = parse_time_cell(row[config.start_time_column])
        if start_time is None:
            continue
        max_attendees, unusable_max = parse_max_attendees(
            row[config.max_attendees_column]
        )
        if max_attendees is None:
            raise ValueError(
                f"{config.label} {config.sheet_name} {start_time}: "
                f"Bokningsbara platser is {unusable_max}"
            )
        slots.append(
            {
                "start_time": start_time,
                "max_attendees": max_attendees,
                "description": cell_str(row[config.description_column]) or "",
                "tillsammans_deviation": deviation(
                    row, config.tillsammans_column
                ),
                "avslutning_deviation": deviation(row, config.avslutning_column),
            }
        )
    return slots


def expand_recurring_slots(
    slots: list[dict], config: RecurringImport
) -> tuple[list[dict], list[str]]:
    """One activity per slot and day, applying the per-day deviation
    columns."""
    activities = []
    warnings = []
    for day in config.days:
        for slot in slots:
            description = slot["description"]
            target_groups = []
            if day == TILLSAMMANS_DAY and slot["tillsammans_deviation"]:
                description = slot["tillsammans_deviation"]
                target_groups = ["funktionar"]
            if day == AVSLUTNING_DAY and slot["avslutning_deviation"]:
                if (
                    slot["avslutning_deviation"].casefold()
                    == NOT_BOOKABLE_MARKER
                ):
                    warnings.append(
                        f"{config.label} {day.isoformat()} "
                        f"{slot['start_time']}: \"Ej bokningsbar\" on "
                        "Avslutning; slot skipped"
                    )
                    continue
                description = slot["avslutning_deviation"]
            start = to_utc(day, slot["start_time"])
            activities.append(
                {
                    "id": stable_id(
                        config.id_kind, day.isoformat(), start.isoformat()
                    ),
                    "title": config.title,
                    "title_en": config.title_en,
                    "description": description,
                    # No English text in these workbooks; fall back to Swedish
                    # like the program import does.
                    "description_en": description,
                    "max_attendees": slot["max_attendees"],
                    "start": start,
                    # The sheet has no end times; start == end renders as a
                    # single clock time in the client (SameDaySameTime).
                    "end": start,
                    "target_groups": target_groups,
                }
            )
    return activities, warnings


def find_duplicates(activities: list[dict]) -> list[str]:
    seen = {}
    for activity in activities:
        key = (activity["title"], activity["start"], activity["end"])
        seen[key] = seen.get(key, 0) + 1
    return [
        f"{start:%d %b}: {title} {start:%H:%M}-{end:%H:%M} UTC x{count}"
        for (title, start, end), count in sorted(seen.items(), key=lambda kv: kv[0][1])
        if count > 1
    ]


def resolve_references(
    locations: list[dict],
    tags: list[dict],
    activities: list[dict],
) -> list[str]:
    """Point each activity at its location and tag rows. Plats/Kategori
    values with no match get a warning and stay NULL/unlinked rather than
    silently inventing a placeholder row."""
    locations_by_key = {normalize_name(loc["name"]): loc for loc in locations}
    tags_by_key = {normalize_name(tag["name"]): tag for tag in tags}
    missing_locations = {}
    missing_tags = {}
    for activity in activities:
        if activity["location_name"]:
            key = normalize_name(activity["location_name"])
            key = LOCATION_ALIASES.get(key, key)
            location = locations_by_key.get(key)
            if location is None:
                missing_locations[activity["location_name"]] = (
                    missing_locations.get(activity["location_name"], 0) + 1
                )
            else:
                activity["location_id"] = location["id"]
        if activity["category"]:
            tag = tags_by_key.get(normalize_name(activity["category"]))
            if tag is None:
                missing_tags[activity["category"]] = (
                    missing_tags.get(activity["category"], 0) + 1
                )
            else:
                activity["tag_id"] = tag["id"]
    warnings = [
        f'Plats "{name}" ({count} activities) is not in the Platser sheet; '
        "imported without a location"
        for name, count in sorted(missing_locations.items())
    ]
    warnings.extend(
        f'Kategori "{name}" ({count} activities) is not in the Kategorier '
        "sheet; imported without a tag"
        for name, count in sorted(missing_tags.items())
    )
    return warnings


def render_locations_sql(locations: list[dict], missing_coords: list[str]) -> str:
    lines = [
        "-- Generated by scripts/generate_import.py from the Platser och",
        "-- aktiviteter workbook. Do not edit by hand; re-run the generator instead.",
        "--",
        "-- Run this file first, then activities.sql. The TRUNCATE below wipes",
        "-- ALL existing app data, including bookings, favourites, call-offs and",
        "-- users (users are upserted again on login).",
    ]
    if missing_coords:
        lines.append(
            f"-- {len(missing_coords)} locations have no Latitud/Longitud in "
            "the sheet; their coordinates are NULL below."
        )
    lines.append(
        "-- name_en/icon_name/color/icon_variant have no source column in the "
        "sheet; placeholders are used below and need manual review."
    )
    lines.append("")
    lines.append("TRUNCATE\n    " + ",\n    ".join(APP_TABLES) + "\n    CASCADE;")
    lines.append("")

    location_values = []
    for loc in locations:
        location_values.append(
            "    (\n"
            f"        {sql_str(loc['id'])},\n"
            f"        {sql_str(loc['name'])},\n"
            f"        {sql_str(loc['name'])},\n"
            f"        {sql_str(loc['description'])},\n"
            f"        {sql_str(loc['description_en'])},\n"
            f"        {sql_str(DEFAULT_ICON_NAME)},\n"
            f"        {sql_str(DEFAULT_ICON_VARIANT)},\n"
            f"        {sql_str(DEFAULT_COLOR)},\n"
            f"        {sql_float(loc['latitude'])},\n"
            f"        {sql_float(loc['longitude'])},\n"
            f"        {sql_jsonb_opening_hours(loc['opening_hours'])}\n"
            "    )"
        )
    lines.append(
        insert_statements(
            "INSERT INTO location (\n"
        "        id,\n"
        "        name,\n"
        "        name_en,\n"
        "        description,\n"
        "        description_en,\n"
        "        icon_name,\n"
        "        icon_variant,\n"
        "        color,\n"
        "        latitude,\n"
        "        longitude,\n"
            "        opening_hours\n"
            "    )\n",
            location_values,
        )
    )
    lines.append("")

    return "\n".join(lines)


def render_activities_sql(
    activities: list[dict],
    tags: list[dict],
    skipped: list[str],
) -> str:
    lines = [
        "-- Generated by scripts/generate_import.py from the Platser och",
        "-- aktiviteter workbook. Do not edit by hand; re-run the generator instead.",
        "--",
        "-- Run locations.sql first: it wipes all existing data and inserts the",
        "-- location rows referenced here.",
        "--",
        "-- Times in the sheet are camp-local (Europe/Stockholm); start_time and",
        "-- end_time below are UTC. max_attendees is only set where the sheet",
        "-- marks the activity as \"Kraver bokning\" AND has a numeric Maxantal;",
        "-- an activity is bookable in the app if and only if max_attendees is",
        "-- set. Activities marked Dold i appen are skipped; Agare is dropped",
        "-- entirely.",
    ]
    if skipped:
        lines.append("--")
        lines.append("-- Skipped (reason in parentheses):")
        for entry in skipped:
            lines.append(f"--   {entry}")
    lines.append("")

    tag_values = [
        "    (\n"
        f"        {sql_str(tag['id'])},\n"
        f"        {sql_str(tag['name'])},\n"
        f"        {sql_str(tag['name'])}\n"
        "    )"
        for tag in tags
    ]
    lines.append(
        "-- The Kategorier sheet. name_en has no source column; the Swedish\n"
        "-- name is used as a placeholder and needs manual review.\n"
        + insert_statements(
            "INSERT INTO activity_tag (id, name, name_en)\n", tag_values
        )
    )
    lines.append("")

    values = []
    for activity in activities:
        values.append(
            "    (\n"
            f"        {sql_str(activity['id'])},\n"
            f"        {sql_str(activity['title'])},\n"
            f"        {sql_str(activity['title_en'])},\n"
            f"        {sql_str(activity['description'])},\n"
            f"        {sql_str(activity['description_en'])},\n"
            f"        {sql_int(activity['max_attendees'])},\n"
            f"        {sql_timestamp(activity['start'])},\n"
            f"        {sql_timestamp(activity['end'])},\n"
            f"        {sql_str(activity['location_id'])}\n"
            "    )"
        )
    lines.append(
        insert_statements(
            "INSERT INTO activity (\n"
            "        id,\n"
            "        title,\n"
            "        title_en,\n"
            "        description,\n"
            "        description_en,\n"
            "        max_attendees,\n"
            "        start_time,\n"
            "        end_time,\n"
            "        location_id\n"
            "    )\n",
            values,
        )
    )
    lines.append("")

    link_values = [
        "    (\n"
        f"        {sql_str(activity['tag_id'])},\n"
        f"        {sql_str(activity['id'])}\n"
        "    )"
        for activity in activities
        if activity["tag_id"] is not None
    ]
    if link_values:
        lines.append(
            "-- Each activity's Kategori column.\n"
            + insert_statements(
                "INSERT INTO activity_tag_activity"
                " (activity_tag_id, activity_id)\n",
                link_values,
            )
        )
        lines.append("")

    group_values = [
        f"    ({sql_str(activity['id'])}, {sql_str(group)})"
        for activity in activities
        for group in activity["target_groups"]
    ]
    if group_values:
        lines.append(
            insert_statements(
                "INSERT INTO activity_target_group"
                " (activity_id, target_group)\n",
                group_values,
            )
        )
        lines.append("")

    return "\n".join(lines)


def render_recurring_sql(
    activities: list[dict], skipped: list[str], config: RecurringImport
) -> str:
    days = f"{config.days[0]:%-d}-{config.days[-1]:%-d} {config.days[-1]:%B}"
    lines = [
        f"-- Generated by scripts/generate_import.py from the {config.source}",
        f"-- workbook's {config.sheet_name} tab. Do not edit by hand; re-run",
        "-- the generator instead.",
        "--",
        "-- Run after locations.sql (which wipes all data) and activities.sql.",
        "--",
        f"-- One {config.kind} activity per slot and day ({days}). The",
        "-- sheet has no end times, so end_time = start_time (rendered as a",
        "-- single clock time), and no English text, so description_en falls",
        "-- back to Swedish. max_attendees is the sheet's Bokningsbara platser.",
    ]
    if config.tillsammans_column is not None or config.avslutning_column is not None:
        lines.append(
            "-- On 28/7 the deviating slots are funktionar-only; on 31/7 the "
            "slots\n-- marked \"Ej bokningsbar\" are omitted:"
        )
        for entry in skipped:
            lines.append(f"--   {entry}")
    else:
        lines.append("-- The sheet has no per-day deviations: every day is the same.")
    lines.append("")

    values = []
    for activity in activities:
        values.append(
            "    (\n"
            f"        {sql_str(activity['id'])},\n"
            f"        {sql_str(activity['title'])},\n"
            f"        {sql_str(activity['title_en'])},\n"
            f"        {sql_str(activity['description'])},\n"
            f"        {sql_str(activity['description_en'])},\n"
            f"        {sql_int(activity['max_attendees'])},\n"
            f"        {sql_timestamp(activity['start'])},\n"
            f"        {sql_timestamp(activity['end'])},\n"
            f"        {sql_str(config.kind)}\n"
            "    )"
        )
    lines.append(
        insert_statements(
            "INSERT INTO activity (\n"
            "        id,\n"
            "        title,\n"
            "        title_en,\n"
            "        description,\n"
            "        description_en,\n"
            "        max_attendees,\n"
            "        start_time,\n"
            "        end_time,\n"
            "        recurring_activity_kind\n"
            "    )\n",
            values,
        )
    )
    lines.append("")

    group_values = [
        f"    ({sql_str(activity['id'])}, {sql_str(group)})"
        for activity in activities
        for group in activity["target_groups"]
    ]
    if group_values:
        lines.append(
            "-- The funktionar-only slots on Tillsammansfesten 28/7.\n"
            + insert_statements(
                "INSERT INTO activity_target_group"
                " (activity_id, target_group)\n",
                group_values,
            )
        )
        lines.append("")

    return "\n".join(lines)


def render_combined_sql(parts: list[str]) -> str:
    """Every generated file wrapped in one transaction.

    Order matters (activities reference locations), and a partial import leaves
    the app with activities missing their locations, so the whole thing either
    lands or rolls back.
    """
    header = (
        "-- Generated by scripts/generate_import.py: locations.sql,\n"
        "-- activities.sql and the recurring-activity files in the order they\n"
        "-- have to run, wrapped in a single transaction. Do not edit by hand;\n"
        "-- re-run the generator instead.\n"
        "--\n"
        "-- Importing this one file is equivalent to running them all\n"
        "-- separately, and cannot be run in the wrong order or half-applied.\n"
        "-- It TRUNCATEs every app table first, so it wipes all existing data.\n"
        "--\n"
        "-- In DBeaver: open this file and run it as a script (Alt+X), not as a\n"
        "-- single query (Ctrl+Enter). If a statement fails, choose Stop rather\n"
        "-- than Ignore -- the first error is the real one, and continuing past\n"
        "-- it only produces foreign key violations on the link tables.\n"
        "BEGIN;\n"
    )
    return header + "\n".join(parts) + "\nCOMMIT;\n"


def main() -> None:
    workbook_path = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_WORKBOOK_PATH
    # One optional workbook per recurring import, in RECURRING_IMPORTS order.
    recurring_paths = [Path(arg) for arg in sys.argv[2:]]
    if len(recurring_paths) > len(RECURRING_IMPORTS):
        raise SystemExit(
            f"at most {len(RECURRING_IMPORTS)} recurring workbooks "
            f"({', '.join(c.label for c in RECURRING_IMPORTS)}), got "
            f"{len(recurring_paths)}"
        )
    wb = CalamineWorkbook.from_path(workbook_path)

    locations, location_warnings = read_locations(wb)
    tags = read_tags(wb)
    activities, skipped, warnings = read_activities(wb)
    warnings.extend(location_warnings)
    warnings.extend(
        f"duplicate rows in the sheet, all imported: {entry}"
        for entry in find_duplicates(activities)
    )
    warnings.extend(resolve_references(locations, tags, activities))

    missing_coords = sorted(loc["name"] for loc in locations if loc["latitude"] is None)
    tag_link_count = sum(1 for a in activities if a["tag_id"] is not None)
    group_count = sum(len(a["target_groups"]) for a in activities)

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    LOCATIONS_OUTPUT_PATH.write_text(render_locations_sql(locations, missing_coords))
    ACTIVITIES_OUTPUT_PATH.write_text(
        render_activities_sql(activities, tags, skipped)
    )

    print(f"Wrote {len(locations)} locations -> {LOCATIONS_OUTPUT_PATH}")
    print(
        f"Wrote {len(tags)} activity tags, {len(activities)} activities "
        f"({tag_link_count} tag links, {group_count} target-group rows) "
        f"-> {ACTIVITIES_OUTPUT_PATH}"
    )
    for config, path in zip(RECURRING_IMPORTS, recurring_paths):
        recurring_wb = CalamineWorkbook.from_path(path)
        slots = read_recurring_slots(recurring_wb, config)
        expanded, expanded_skipped = expand_recurring_slots(slots, config)
        config.output_path.write_text(
            render_recurring_sql(expanded, expanded_skipped, config)
        )
        funk_count = sum(len(a["target_groups"]) for a in expanded)
        deviations = (
            f" ({funk_count} funktionar-only, {len(expanded_skipped)} skipped "
            "on Avslutning)"
            if config.tillsammans_column is not None
            or config.avslutning_column is not None
            else ""
        )
        print(
            f"Wrote {len(expanded)} {config.label} slots from {len(slots)} "
            f"daily slots over {len(config.days)} days{deviations} "
            f"-> {config.output_path}"
        )
    parts = [
        LOCATIONS_OUTPUT_PATH.read_text(),
        ACTIVITIES_OUTPUT_PATH.read_text(),
    ]
    parts.extend(
        config.output_path.read_text()
        for config in RECURRING_IMPORTS
        if config.output_path.exists()
    )
    COMBINED_OUTPUT_PATH.write_text(render_combined_sql(parts))
    print(f"Wrote all of the above in one transaction -> {COMBINED_OUTPUT_PATH}")

    print(f"{len(missing_coords)} locations have no coordinates (left NULL)")
    if skipped:
        print(f"Skipped {len(skipped)} activities:")
        for entry in skipped:
            print(f"  - {entry}")
    if warnings:
        print(f"{len(warnings)} warnings:")
        for entry in warnings:
            print(f"  - {entry}")


if __name__ == "__main__":
    main()

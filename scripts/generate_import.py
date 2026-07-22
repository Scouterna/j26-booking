"""Generate the real-import SQL from the "Platser och aktiviteter" workbook.

Reads the workbook's three kinds of sheets and emits INSERT statements into
server/priv/import/ (same style as server/priv/seeding/*.sql):

- "Platser"            -> location rows (+ opening_hours JSONB per date)
- "Kategorier"         -> activity_tag rows
- one sheet per day    -> activity rows (+ tag links and target groups)

locations.sql starts by TRUNCATE-ing every app table (bookings, favourites,
call-offs and users included -- users are upserted again on login), so running
the import wipes all existing data. Run locations.sql first, then
activities.sql.

Imported per activity: title, title_en, description, description_en,
max_attendees (only when "Kraver bokning" is true), start_time, end_time,
location_id (Plats), its Kategori as an activity_tag link, and
activity_target_group rows for the Upptackare/Aventyrare/Utmanare/Rover
columns. Ledare/Funktionarer have no target_group enum value yet; add them to
TARGET_GROUP_COLUMNS once the enum supports them. "Dold i appen", "Agare" and
the "Sektion" column of the Platser sheet have nowhere to go and are dropped.

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

Usage: python3 generate_import.py [workbook.xlsx]
Output: server/priv/import/locations.sql, server/priv/import/activities.sql
"""

from __future__ import annotations

import re
import sys
import uuid
from datetime import date, datetime, time, timedelta, timezone
from pathlib import Path
from zoneinfo import ZoneInfo

from python_calamine import CalamineWorkbook

SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_WORKBOOK_PATH = SCRIPT_DIR / "platser_och_aktiviteter.xlsx"
OUTPUT_DIR = SCRIPT_DIR.parent / "server" / "priv" / "import"
LOCATIONS_OUTPUT_PATH = OUTPUT_DIR / "locations.sql"
ACTIVITIES_OUTPUT_PATH = OUTPUT_DIR / "activities.sql"

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
# target_group enum value each maps to. Columns 9 (Ledare) and 10
# (Funktionarer) have no enum value yet -- add them here once they do.
TARGET_GROUP_COLUMNS = [
    (5, "upptackare"),
    (6, "aventyrare"),
    (7, "utmanare"),
    (8, "rover"),
]

# Plats spellings in the day sheets that don't match the Platser sheet but
# clearly mean an existing location. Keys and values are normalize_name'd.
LOCATION_ALIASES = {
    "utmanarhubb-brädspelstält": "utmanarhubben-brädspelstält",
    "utmanarhubb-cafetält": "utmanarhubben-cafetält",
    "utmanarhubb-storatältet": "utmanarhubben-storatältet",
}

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


def new_id() -> str:
    return str(uuid.uuid4())


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
    if value is None:
        return "NULL"
    return "'" + value.replace("'", "''") + "'"


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


def read_locations(wb: CalamineWorkbook) -> list[dict]:
    # Row 0 is a merged note, row 1 the headers. Columns: 0 = Namn,
    # 1 = Sektion (unused), 2-9 = one per camp day, 10 = Beskrivning,
    # 11 = Latitud, 12 = Longitud.
    rows = sheet_rows(wb, "Platser")
    day_headers = rows[1][2:10]
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
        locations.append(
            {
                "id": new_id(),
                "name": name,
                "description": cell_str(row[10]) or "",
                "latitude": parse_coordinate_cell(row[11]),
                "longitude": parse_coordinate_cell(row[12]),
                "opening_hours": opening_hours,
            }
        )
    return locations


def read_tags(wb: CalamineWorkbook) -> list[dict]:
    rows = sheet_rows(wb, "Kategorier")
    names = []
    for row in rows[1:]:
        name = cell_str(row[0])
        if name:
            names.append(name)
    return [{"id": new_id(), "name": name} for name in names]


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
            if parse_bool_cell(row[16]):
                warnings.append(
                    f'{sheet_name}: {name} is marked "Dold i appen" but is '
                    "imported anyway (activities have no hidden flag)"
                )
            title_en = cell_str(row[1])
            description_en = cell_str(row[3])
            description = cell_str(row[2]) or ""
            activities.append(
                {
                    "id": new_id(),
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
        "-- name_en/description_en/icon_name/color/icon_variant have no "
        "source column in the sheet; placeholders are used below and need "
        "manual review."
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
            f"        {sql_str(loc['description'])},\n"
            f"        {sql_str(DEFAULT_ICON_NAME)},\n"
            f"        {sql_str(DEFAULT_ICON_VARIANT)},\n"
            f"        {sql_str(DEFAULT_COLOR)},\n"
            f"        {sql_float(loc['latitude'])},\n"
            f"        {sql_float(loc['longitude'])},\n"
            f"        {sql_jsonb_opening_hours(loc['opening_hours'])}\n"
            "    )"
        )
    lines.append(
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
        "    )\n"
        "VALUES\n" + ",\n".join(location_values) + ";"
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
        "-- set. The sheet's Ledare/Funktionarer columns have no target_group",
        "-- enum value yet and are dropped; Dold i appen and Agare are dropped",
        "-- entirely.",
    ]
    if skipped:
        lines.append("--")
        lines.append("-- Skipped (missing start/end time in the sheet):")
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
        "INSERT INTO activity_tag (id, name, name_en)\n"
        "VALUES\n" + ",\n".join(tag_values) + ";"
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
        "    )\n"
        "VALUES\n" + ",\n".join(values) + ";"
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
            "INSERT INTO activity_tag_activity (activity_tag_id, activity_id)\n"
            "VALUES\n" + ",\n".join(link_values) + ";"
        )
        lines.append("")

    group_values = [
        f"    ({sql_str(activity['id'])}, {sql_str(group)})"
        for activity in activities
        for group in activity["target_groups"]
    ]
    if group_values:
        lines.append(
            "INSERT INTO activity_target_group (activity_id, target_group)\n"
            "VALUES\n" + ",\n".join(group_values) + ";"
        )
        lines.append("")

    return "\n".join(lines)


def main() -> None:
    workbook_path = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_WORKBOOK_PATH
    wb = CalamineWorkbook.from_path(workbook_path)

    locations = read_locations(wb)
    tags = read_tags(wb)
    activities, skipped, warnings = read_activities(wb)
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
    print(f"{len(missing_coords)} locations have no coordinates (left NULL)")
    if skipped:
        print(f"Skipped {len(skipped)} activities missing start/end time:")
        for entry in skipped:
            print(f"  - {entry}")
    if warnings:
        print(f"{len(warnings)} warnings:")
        for entry in warnings:
            print(f"  - {entry}")


if __name__ == "__main__":
    main()

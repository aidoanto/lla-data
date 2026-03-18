from __future__ import annotations

import csv
import re
import zipfile
from dataclasses import dataclass
from datetime import date
from pathlib import Path
from xml.etree import ElementTree as ET


ROOT = Path(__file__).resolve().parents[1]
NS = {"main": "http://schemas.openxmlformats.org/spreadsheetml/2006/main"}
DATE_RANGE_RE = re.compile(r"# (\d{8})-(\d{8})")


@dataclass(frozen=True)
class ArchiveConfig:
    column_name: str
    workbook_path: Path


ARCHIVES = [
    ArchiveConfig(
        column_name="lifeline_org_au_new_users",
        workbook_path=ROOT
        / "ua-data/lifeline-australia/https-www-lifeline-org-au/"
        / "https-www-lifeline-org-au-lifeline-all-external-traffic-month-visitors-overview.xlsx",
    ),
    ArchiveConfig(
        column_name="beyond_blue_au_only_new_users",
        workbook_path=ROOT
        / "ua-data/beyond-blue/201506-202307-web-bb-web-bb-au-only-month-visitors-overview.xlsx",
    ),
]

OUTPUT_PATH = ROOT / "ua-data/monthly_ua_new_users_lifeline_and_beyond_blue.csv"


def load_shared_strings(archive: zipfile.ZipFile) -> list[str]:
    root = ET.fromstring(archive.read("xl/sharedStrings.xml"))
    strings: list[str] = []
    for item in root.findall("main:si", NS):
        text = "".join(node.text or "" for node in item.iterfind(".//main:t", NS))
        strings.append(text)
    return strings


def cell_text(cell: ET.Element, shared_strings: list[str]) -> str:
    value = cell.findtext("main:v", default="", namespaces=NS)
    if cell.attrib.get("t") == "s":
        return shared_strings[int(float(value))]
    return value


def add_months(start: date, month_offset: int) -> date:
    month_index = (start.year * 12 + start.month - 1) + month_offset
    year = month_index // 12
    month = month_index % 12 + 1
    return date(year, month, 1)


def parse_monthly_new_users(workbook_path: Path) -> dict[str, int]:
    with zipfile.ZipFile(workbook_path) as archive:
        shared_strings = load_shared_strings(archive)
        worksheet = ET.fromstring(archive.read("xl/worksheets/sheet1.xml"))

    date_range_text = next(
        (value for value in shared_strings if DATE_RANGE_RE.fullmatch(value)),
        None,
    )
    if date_range_text is None:
        raise ValueError(f"Could not find date range in {workbook_path}")

    match = DATE_RANGE_RE.fullmatch(date_range_text)
    assert match is not None
    range_start = date.fromisoformat(
        f"{match.group(1)[0:4]}-{match.group(1)[4:6]}-{match.group(1)[6:8]}"
    )

    monthly_rows: dict[str, int] = {}
    for row in worksheet.findall(".//main:sheetData/main:row", NS):
        cells = {cell.attrib["r"][0]: cell for cell in row.findall("main:c", NS)}
        if "A" not in cells or "B" not in cells:
            continue

        month_index_raw = cell_text(cells["A"], shared_strings).strip()
        new_users_raw = cell_text(cells["B"], shared_strings).strip()
        if not month_index_raw or not new_users_raw:
            continue

        try:
            month_index = int(float(month_index_raw))
        except ValueError:
            continue
        if month_index <= 0:
            continue

        month = add_months(range_start, month_index - 1).isoformat()
        monthly_rows[month] = int(round(float(new_users_raw)))

    return monthly_rows


def main() -> None:
    by_archive = {
        archive.column_name: parse_monthly_new_users(archive.workbook_path)
        for archive in ARCHIVES
    }
    all_months = sorted({month for values in by_archive.values() for month in values})

    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    with OUTPUT_PATH.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=["month", *[archive.column_name for archive in ARCHIVES]],
        )
        writer.writeheader()
        for month in all_months:
            row = {"month": month}
            for archive in ARCHIVES:
                row[archive.column_name] = by_archive[archive.column_name].get(month, "")
            writer.writerow(row)

    print(f"Wrote {OUTPUT_PATH}")


if __name__ == "__main__":
    main()

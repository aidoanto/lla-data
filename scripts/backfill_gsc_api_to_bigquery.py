"""Backfill historical Google Search Console data into BigQuery tables.

Run:
  uv run python scripts/backfill_gsc_api_to_bigquery.py --start-date 2025-01-01

This script writes two backfill tables:
  - searchconsole.searchdata_site_impression_backfill
  - searchconsole.searchdata_url_impression_backfill

It uses Search Console API data and keeps schema compatible with curated SQL.
"""

from __future__ import annotations

import argparse
import os
import sys
import time
from datetime import date, datetime, timedelta
from typing import Any

import google.auth
from googleapiclient.errors import HttpError
from google.api_core.exceptions import NotFound
from google.cloud import bigquery
from googleapiclient.discovery import build

# Allow running this script directly from repo root.
REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if REPO_ROOT not in sys.path:
    sys.path.insert(0, REPO_ROOT)

from lla_data import config
from lla_data.bq import get_client, run_query

WEBMASTERS_SCOPE = "https://www.googleapis.com/auth/webmasters"

SITE_BACKFILL_TABLE = "searchdata_site_impression_backfill"
URL_BACKFILL_TABLE = "searchdata_url_impression_backfill"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Backfill GSC API data into BigQuery.")
    parser.add_argument(
        "--start-date",
        required=True,
        help="Backfill start date in YYYY-MM-DD format.",
    )
    parser.add_argument(
        "--end-date",
        default=date.today().isoformat(),
        help="Backfill end date in YYYY-MM-DD format (default: today).",
    )
    parser.add_argument(
        "--site-url",
        default="",
        help="Search Console property URI (for example: sc-domain:lifeline.org.au).",
    )
    parser.add_argument(
        "--search-type",
        default="web",
        help="Search type for API query (default: web).",
    )
    parser.add_argument(
        "--row-limit",
        type=int,
        default=25_000,
        help="Rows per API page (max 25000, default 25000).",
    )
    parser.add_argument(
        "--mode",
        choices=("truncate", "append"),
        default="truncate",
        help="truncate: replace backfill tables, append: add rows (default: truncate).",
    )
    parser.add_argument(
        "--sleep-seconds",
        type=float,
        default=0.15,
        help="Pause between API pages to reduce rate-limit pressure.",
    )
    parser.add_argument(
        "--chunk-days",
        type=int,
        default=14,
        help="Number of days per API request window (default: 14).",
    )
    parser.add_argument(
        "--url-grain",
        choices=("page", "page_query"),
        default="page",
        help=(
            "Backfill URL table at page-level only (faster) or page+query "
            "(slower, larger). Default: page."
        ),
    )
    parser.add_argument(
        "--detail-level",
        choices=("minimal", "full"),
        default="minimal",
        help=(
            "minimal: fewer dimensions for faster historical loads "
            "(recommended), full: include country/device dimensions."
        ),
    )
    return parser.parse_args()


def as_date(value: str) -> date:
    return datetime.strptime(value, "%Y-%m-%d").date()


def detect_site_url(client: bigquery.Client) -> str:
    sql = f"""
    SELECT site_url, COUNT(*) AS n
    FROM `{config.PROJECT_ID}.{config.SEARCHCONSOLE_DATASET}.searchdata_site_impression`
    WHERE site_url IS NOT NULL AND site_url != ''
    GROUP BY site_url
    ORDER BY n DESC
    LIMIT 1
    """
    df = run_query(client, sql)
    if df.empty:
        raise RuntimeError(
            "Could not auto-detect site_url from raw export table. "
            "Pass --site-url explicitly."
        )
    return str(df.iloc[0]["site_url"])


def build_webmasters_client():
    creds, _ = google.auth.default(scopes=[WEBMASTERS_SCOPE])
    return build("webmasters", "v3", credentials=creds, cache_discovery=False)


def paged_search_analytics_rows(
    service: Any,
    *,
    site_url: str,
    start_date: date,
    end_date: date,
    dimensions: list[str],
    search_type: str,
    row_limit: int,
    sleep_seconds: float,
):
    start_row = 0
    while True:
        body = {
            "startDate": start_date.isoformat(),
            "endDate": end_date.isoformat(),
            "dimensions": dimensions,
            "type": search_type,
            "rowLimit": row_limit,
            "startRow": start_row,
            "dataState": "final",
        }
        response = execute_searchanalytics_query_with_retry(service, site_url, body)
        rows = response.get("rows", [])
        if not rows:
            break

        yield rows

        got = len(rows)
        if got < row_limit:
            break
        start_row += got
        time.sleep(sleep_seconds)


def execute_searchanalytics_query_with_retry(
    service: Any,
    site_url: str,
    body: dict[str, Any],
    max_attempts: int = 6,
) -> dict[str, Any]:
    last_error: Exception | None = None
    for attempt in range(1, max_attempts + 1):
        try:
            return (
                service.searchanalytics()
                .query(siteUrl=site_url, body=body)
                .execute()
            )
        except HttpError as err:
            status = getattr(err.resp, "status", None)
            if status in (429, 500, 502, 503, 504):
                last_error = err
            else:
                raise
        except ConnectionResetError as err:
            last_error = err
        except OSError as err:
            last_error = err

        if attempt == max_attempts:
            break
        delay = min(30.0, 1.5**attempt)
        print(
            f"Transient API error (attempt {attempt}/{max_attempts}); "
            f"retrying in {delay:.1f}s...",
            flush=True,
        )
        time.sleep(delay)

    if last_error is not None:
        raise last_error
    raise RuntimeError("Unknown error while querying Search Console API.")


def to_site_rows(
    api_rows: list[dict[str, Any]],
    site_url: str,
    search_type: str,
    dimensions: list[str],
) -> list[dict[str, Any]]:
    out: list[dict[str, Any]] = []
    for row in api_rows:
        keys = list(row.get("keys", []))
        key_by_dim = {dim: keys[i] for i, dim in enumerate(dimensions) if i < len(keys)}
        report_date = str(key_by_dim.get("date", ""))
        country = key_by_dim.get("country")
        device = key_by_dim.get("device")
        impressions = float(row.get("impressions", 0.0))
        position = float(row.get("position", 0.0))
        out.append(
            {
                "data_date": report_date,
                "site_url": site_url,
                "search_type": search_type,
                "country": country or None,
                "device": device or None,
                "clicks": int(round(float(row.get("clicks", 0.0)))),
                "impressions": int(round(impressions)),
                "sum_top_position": max(position - 1.0, 0.0) * impressions,
            }
        )
    return out


def to_url_rows(
    api_rows: list[dict[str, Any]],
    site_url: str,
    search_type: str,
    dimensions: list[str],
) -> list[dict[str, Any]]:
    out: list[dict[str, Any]] = []
    for row in api_rows:
        keys = list(row.get("keys", []))
        key_by_dim = {dim: keys[i] for i, dim in enumerate(dimensions) if i < len(keys)}
        report_date = str(key_by_dim.get("date", ""))
        country = key_by_dim.get("country")
        device = key_by_dim.get("device")
        page_url = str(key_by_dim.get("page", ""))
        query = key_by_dim.get("query")
        impressions = float(row.get("impressions", 0.0))
        position = float(row.get("position", 0.0))
        out.append(
            {
                "data_date": report_date,
                "site_url": site_url,
                "url": page_url,
                "query": query or None,
                "is_anonymized_query": None,
                "search_type": search_type,
                "country": country or None,
                "device": device or None,
                "clicks": int(round(float(row.get("clicks", 0.0)))),
                "impressions": int(round(impressions)),
                "sum_position": max(position - 1.0, 0.0) * impressions,
            }
        )
    return out


def ensure_backfill_tables(client: bigquery.Client) -> None:
    dataset_ref = f"{config.PROJECT_ID}.{config.SEARCHCONSOLE_DATASET}"

    site_table = bigquery.Table(
        f"{dataset_ref}.{SITE_BACKFILL_TABLE}",
        schema=[
            bigquery.SchemaField("data_date", "DATE"),
            bigquery.SchemaField("site_url", "STRING"),
            bigquery.SchemaField("search_type", "STRING"),
            bigquery.SchemaField("country", "STRING"),
            bigquery.SchemaField("device", "STRING"),
            bigquery.SchemaField("clicks", "INT64"),
            bigquery.SchemaField("impressions", "INT64"),
            bigquery.SchemaField("sum_top_position", "FLOAT64"),
        ],
    )
    site_table.time_partitioning = bigquery.TimePartitioning(field="data_date")

    url_table = bigquery.Table(
        f"{dataset_ref}.{URL_BACKFILL_TABLE}",
        schema=[
            bigquery.SchemaField("data_date", "DATE"),
            bigquery.SchemaField("site_url", "STRING"),
            bigquery.SchemaField("url", "STRING"),
            bigquery.SchemaField("query", "STRING"),
            bigquery.SchemaField("is_anonymized_query", "BOOL"),
            bigquery.SchemaField("search_type", "STRING"),
            bigquery.SchemaField("country", "STRING"),
            bigquery.SchemaField("device", "STRING"),
            bigquery.SchemaField("clicks", "INT64"),
            bigquery.SchemaField("impressions", "INT64"),
            bigquery.SchemaField("sum_position", "FLOAT64"),
        ],
    )
    url_table.time_partitioning = bigquery.TimePartitioning(field="data_date")

    for table in (site_table, url_table):
        try:
            client.get_table(table.reference)
        except NotFound:
            client.create_table(table)


def maybe_truncate(client: bigquery.Client, mode: str) -> None:
    if mode != "truncate":
        return
    dataset_ref = f"{config.PROJECT_ID}.{config.SEARCHCONSOLE_DATASET}"
    for table_name in (SITE_BACKFILL_TABLE, URL_BACKFILL_TABLE):
        client.query(
            f"TRUNCATE TABLE `{dataset_ref}.{table_name}`"
        ).result()


def load_rows(
    client: bigquery.Client,
    table_id: str,
    rows: list[dict[str, Any]],
) -> int:
    if not rows:
        return 0
    job_config = bigquery.LoadJobConfig(write_disposition="WRITE_APPEND")
    job = client.load_table_from_json(rows, table_id, job_config=job_config)
    job.result()
    return len(rows)


def daterange(start: date, end: date):
    day = start
    while day <= end:
        yield day
        day += timedelta(days=1)


def date_chunks(start: date, end: date, chunk_days: int):
    current = start
    while current <= end:
        chunk_end = min(current + timedelta(days=chunk_days - 1), end)
        yield current, chunk_end
        current = chunk_end + timedelta(days=1)


def main() -> None:
    args = parse_args()
    start_date = as_date(args.start_date)
    end_date = as_date(args.end_date)
    if end_date < start_date:
        raise ValueError("--end-date must be >= --start-date")
    if args.row_limit < 1 or args.row_limit > 25_000:
        raise ValueError("--row-limit must be between 1 and 25000")
    if args.chunk_days < 1:
        raise ValueError("--chunk-days must be >= 1")

    client = get_client()
    ensure_backfill_tables(client)
    maybe_truncate(client, args.mode)

    site_url = args.site_url.strip() or detect_site_url(client)
    print(f"Project: {config.PROJECT_ID}", flush=True)
    print(f"Dataset: {config.SEARCHCONSOLE_DATASET}", flush=True)
    print(f"Site URL: {site_url}", flush=True)
    print(f"Range: {start_date} to {end_date}", flush=True)
    print(f"Mode: {args.mode}", flush=True)
    print(f"Chunk days: {args.chunk_days}", flush=True)
    print(f"URL grain: {args.url_grain}", flush=True)
    print(f"Detail level: {args.detail_level}", flush=True)

    service = build_webmasters_client()
    dataset_ref = f"{config.PROJECT_ID}.{config.SEARCHCONSOLE_DATASET}"
    site_table_id = f"{dataset_ref}.{SITE_BACKFILL_TABLE}"
    url_table_id = f"{dataset_ref}.{URL_BACKFILL_TABLE}"

    total_site_rows = 0
    total_url_rows = 0

    for chunk_start, chunk_end in date_chunks(start_date, end_date, args.chunk_days):
        chunk_site_rows = 0
        chunk_url_rows = 0

        site_dimensions = (
            ["date", "country", "device"]
            if args.detail_level == "full"
            else ["date"]
        )
        url_dimensions = (
            ["date", "country", "device", "page", "query"]
            if args.url_grain == "page_query" and args.detail_level == "full"
            else ["date", "country", "device", "page"]
            if args.url_grain == "page" and args.detail_level == "full"
            else ["date", "page", "query"]
            if args.url_grain == "page_query"
            else ["date", "page"]
        )

        for page in paged_search_analytics_rows(
            service,
            site_url=site_url,
            start_date=chunk_start,
            end_date=chunk_end,
            dimensions=site_dimensions,
            search_type=args.search_type,
            row_limit=args.row_limit,
            sleep_seconds=args.sleep_seconds,
        ):
            rows = to_site_rows(page, site_url, args.search_type, site_dimensions)
            chunk_site_rows += load_rows(client, site_table_id, rows)

        for page in paged_search_analytics_rows(
            service,
            site_url=site_url,
            start_date=chunk_start,
            end_date=chunk_end,
            dimensions=url_dimensions,
            search_type=args.search_type,
            row_limit=args.row_limit,
            sleep_seconds=args.sleep_seconds,
        ):
            rows = to_url_rows(page, site_url, args.search_type, url_dimensions)
            chunk_url_rows += load_rows(client, url_table_id, rows)

        total_site_rows += chunk_site_rows
        total_url_rows += chunk_url_rows
        print(
            f"{chunk_start}..{chunk_end}: loaded site_rows={chunk_site_rows:,} "
            f"url_rows={chunk_url_rows:,}"
            ,
            flush=True,
        )

    print("Done.", flush=True)
    print(f"Loaded site rows: {total_site_rows:,}", flush=True)
    print(f"Loaded URL rows:  {total_url_rows:,}", flush=True)


if __name__ == "__main__":
    main()

"""Minimal BigQuery API example for GA4 analysis.

Run with:
  uv run python scripts/bigquery_ga4_api_example.py

If dependencies are missing:
  uv add google-cloud-bigquery pandas
"""

from __future__ import annotations

# Local environments may not have dependency installed yet.
# pylint: disable=import-error
from google.cloud import bigquery


PROJECT_ID = "lifeline-website-480522"
DATASET = "analytics_315584957"


def dry_run_bytes(client: bigquery.Client, query: str) -> int:
    """Return bytes scanned estimate without executing the query."""
    job_config = bigquery.QueryJobConfig(dry_run=True, use_query_cache=False)
    query_job = client.query(query, job_config=job_config)
    return query_job.total_bytes_processed


def run_query(client: bigquery.Client, query: str):
    """Execute query and return an iterator of rows."""
    query_job = client.query(query)
    return query_job.result()


def main() -> None:
    client = bigquery.Client(project=PROJECT_ID)

    query = f"""
    SELECT
      PARSE_DATE('%Y%m%d', event_date) AS event_day,
      event_name,
      COUNT(*) AS events
    FROM `{PROJECT_ID}.{DATASET}.events_*`
    WHERE _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY))
      AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
    GROUP BY event_day, event_name
    ORDER BY event_day DESC, events DESC
    LIMIT 50
    """

    estimated_bytes = dry_run_bytes(client, query)
    print(f"Estimated bytes scanned (dry run): {estimated_bytes:,}")

    rows = run_query(client, query)
    print("Top results:")
    for row in rows:
        print(f"{row.event_day} | {row.event_name:<25} | {row.events}")


if __name__ == "__main__":
    main()

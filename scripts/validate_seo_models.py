"""Validate freshness and shape of curated SEO models.

Run:
  uv run python scripts/validate_seo_models.py
"""

from __future__ import annotations

from lla_data import config
from lla_data.bq import get_client, run_query


def main() -> None:
    client = get_client()
    table = f"`{config.PROJECT_ID}.{config.SEARCHCONSOLE_DATASET}.seo_page_daily`"

    freshness_sql = f"""
    SELECT
      MAX(report_date) AS max_report_date,
      MIN(report_date) AS min_report_date,
      COUNT(*) AS total_rows
    FROM {table}
    """

    null_rate_sql = f"""
    SELECT
      SAFE_DIVIDE(COUNTIF(page_path IS NULL OR page_path = ''), COUNT(*)) AS null_or_blank_page_path_rate,
      SAFE_DIVIDE(COUNTIF(report_date IS NULL), COUNT(*)) AS null_report_date_rate
    FROM {table}
    """

    duplicate_sql = f"""
    SELECT COUNT(*) AS duplicate_row_count
    FROM (
      SELECT report_date, page_path, COUNT(*) AS n
      FROM {table}
      GROUP BY report_date, page_path
      HAVING n > 1
    )
    """

    print("=== SEO model freshness ===")
    print(run_query(client, freshness_sql).to_string(index=False))
    print("\n=== Null-rate checks ===")
    print(run_query(client, null_rate_sql).to_string(index=False))
    print("\n=== Duplicate checks at expected grain ===")
    print(run_query(client, duplicate_sql).to_string(index=False))


if __name__ == "__main__":
    main()

"""Reusable BigQuery helpers for notebooks and scripts."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import date, timedelta
from typing import Iterable

import pandas as pd
from google.cloud import bigquery

from lla_data.config import BIGQUERY_LOCATION, PROJECT_ID


@dataclass(frozen=True)
class QueryWindow:
    """Small date-range container for parameterized SQL queries."""

    start_date: date
    end_date: date


def default_query_window(days_back: int = 28) -> QueryWindow:
    """Return [today-days_back, today] date range."""
    end = date.today()
    start = end - timedelta(days=days_back)
    return QueryWindow(start_date=start, end_date=end)


def build_date_params(window: QueryWindow) -> list[bigquery.ScalarQueryParameter]:
    """Build BigQuery date parameters from a QueryWindow."""
    return [
        bigquery.ScalarQueryParameter("start_date", "DATE", window.start_date),
        bigquery.ScalarQueryParameter("end_date", "DATE", window.end_date),
    ]


def get_client(project_id: str = PROJECT_ID, location: str = BIGQUERY_LOCATION) -> bigquery.Client:
    """Create a BigQuery client with project and location defaults."""
    return bigquery.Client(project=project_id, location=location)


def dry_run_bytes(
    client: bigquery.Client,
    sql: str,
    params: Iterable[bigquery.ScalarQueryParameter] | None = None,
) -> int:
    """Return estimated bytes scanned by a query."""
    job_config = bigquery.QueryJobConfig(
        dry_run=True,
        use_query_cache=False,
        query_parameters=list(params or []),
    )
    job = client.query(sql, job_config=job_config)
    return int(job.total_bytes_processed or 0)


def run_query(
    client: bigquery.Client,
    sql: str,
    params: Iterable[bigquery.ScalarQueryParameter] | None = None,
    dry_run: bool = False,
    max_bytes_billed: int | None = None,
) -> pd.DataFrame:
    """Execute SQL and return a pandas DataFrame.

    Set dry_run=True while developing queries to inspect cost first.
    """
    job_config_kwargs: dict[str, object] = {
        "query_parameters": list(params or []),
        "dry_run": dry_run,
        "use_query_cache": not dry_run,
    }
    if max_bytes_billed is not None:
        job_config_kwargs["maximum_bytes_billed"] = max_bytes_billed

    job_config = bigquery.QueryJobConfig(**job_config_kwargs)
    job = client.query(sql, job_config=job_config)

    if dry_run:
        processed = int(job.total_bytes_processed or 0)
        return pd.DataFrame([{"estimated_bytes_processed": processed}])

    return job.to_dataframe()

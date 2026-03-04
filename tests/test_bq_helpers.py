from datetime import date

import pandas as pd

from lla_data.bq import (
    QueryWindow,
    build_date_params,
    default_query_window,
    dry_run_bytes,
    load_sql_template,
    run_query,
)


def test_default_query_window_bounds() -> None:
    window = default_query_window(days_back=7)
    assert window.end_date >= window.start_date
    assert (window.end_date - window.start_date).days == 7


def test_build_date_params_names_and_values() -> None:
    window = QueryWindow(start_date=date(2026, 2, 1), end_date=date(2026, 2, 20))
    params = build_date_params(window)

    assert len(params) == 2
    assert params[0].name == "start_date"
    assert params[0].type_ == "DATE"
    assert params[0].value == date(2026, 2, 1)
    assert params[1].name == "end_date"
    assert params[1].type_ == "DATE"
    assert params[1].value == date(2026, 2, 20)


def test_load_sql_template_with_formatting() -> None:
    sql = load_sql_template(
        "sql/notebooks/seo_search_freshness.sql",
        project_id="my-project",
        searchconsole_dataset="my_gsc",
        ga4_dataset="my_ga4",
    )
    assert "`my-project.my_gsc.curated_search_url_daily`" in sql
    assert "`my-project.my_ga4.curated_ga4_page_daily`" in sql


class _FakeJob:
    def __init__(self, total_bytes_processed: int = 0, frame: pd.DataFrame | None = None) -> None:
        self.total_bytes_processed = total_bytes_processed
        self._frame = frame if frame is not None else pd.DataFrame([{"ok": 1}])

    def to_dataframe(self) -> pd.DataFrame:
        return self._frame


class _FakeClient:
    def __init__(self, job: _FakeJob) -> None:
        self.job = job
        self.captured_sql: str | None = None
        self.captured_job_config = None

    def query(self, sql: str, job_config=None):  # noqa: ANN001
        self.captured_sql = sql
        self.captured_job_config = job_config
        return self.job


def test_dry_run_bytes_returns_total_processed() -> None:
    fake_client = _FakeClient(_FakeJob(total_bytes_processed=1234))
    bytes_scanned = dry_run_bytes(fake_client, "SELECT 1")
    assert bytes_scanned == 1234
    assert fake_client.captured_job_config.dry_run is True


def test_run_query_dry_run_returns_estimate_dataframe() -> None:
    fake_client = _FakeClient(_FakeJob(total_bytes_processed=9876))
    df = run_query(fake_client, "SELECT 1", dry_run=True)
    assert list(df.columns) == ["estimated_bytes_processed"]
    assert int(df.iloc[0]["estimated_bytes_processed"]) == 9876


def test_run_query_exec_returns_job_dataframe() -> None:
    expected = pd.DataFrame([{"value": 42}])
    fake_client = _FakeClient(_FakeJob(frame=expected))
    df = run_query(fake_client, "SELECT 42")
    assert df.equals(expected)

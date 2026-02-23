from datetime import date

from lla_data.bq import QueryWindow, build_date_params, default_query_window


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


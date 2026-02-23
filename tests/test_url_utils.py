from lla_data.url_utils import normalize_url_for_join


def test_normalize_full_url_removes_query_fragment() -> None:
    value = "https://www.lifeline.org.au/get-help/?q=test#section"
    assert normalize_url_for_join(value) == "/get-help"


def test_normalize_path_adds_leading_slash() -> None:
    assert normalize_url_for_join("mental-health/article") == "/mental-health/article"


def test_normalize_keeps_root_path() -> None:
    assert normalize_url_for_join("https://www.lifeline.org.au") == "/"


def test_normalize_none_to_fallback() -> None:
    assert normalize_url_for_join(None) == "(unknown)"


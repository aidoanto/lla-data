import json
from pathlib import Path

import pandas as pd
import pytest

from lla_data.dataforseo import (
    CachedResponse,
    DataForSEOCredentialsError,
    DataForSEOLiveRunRequiredError,
    DataForSEOResponseError,
    build_cache_path,
    canonicalize_lifeline_url,
    extract_lifeline_page_path,
    get_auth,
    get_credentials,
    keywords_for_keywords,
    normalize_keyword_items,
    response_to_keyword_frame,
)


def test_get_credentials_requires_env(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.delenv("DATAFORSEO_EMAIL", raising=False)
    monkeypatch.delenv("DATAFORSEO_API_PASSWORD", raising=False)

    with pytest.raises(DataForSEOCredentialsError):
        get_credentials()


def test_get_auth_uses_basic_auth_from_env(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("DATAFORSEO_EMAIL", "user@example.com")
    monkeypatch.setenv("DATAFORSEO_API_PASSWORD", "secret")

    auth = get_auth()

    assert auth.username == "user@example.com"
    assert auth.password == "secret"


def test_build_cache_path_is_deterministic(tmp_path: Path) -> None:
    payload = {"location_name": "Australia", "keywords": ["anxiety"]}

    one = build_cache_path("/v3/example", payload, mode="sandbox", cache_dir=tmp_path)
    two = build_cache_path("/v3/example", payload, mode="sandbox", cache_dir=tmp_path)

    assert one == two


def test_keywords_for_keywords_uses_cache_when_present(monkeypatch: pytest.MonkeyPatch, tmp_path: Path) -> None:
    payload = {"location_name": "Australia", "language_name": "English", "keywords": ["anxiety"]}
    cache_path = build_cache_path(
        "/v3/keywords_data/google_ads/keywords_for_keywords/live",
        payload,
        mode="sandbox",
        cache_dir=tmp_path,
    )
    cache_path.parent.mkdir(parents=True, exist_ok=True)
    cache_path.write_text(json.dumps({"tasks": [{"result": [{"items": [{"keyword": "anxiety"}]}]}]}), encoding="utf-8")

    def fail_post(*args, **kwargs):  # noqa: ANN001, ANN002
        raise AssertionError("network call should not be reached when cache exists")

    monkeypatch.setattr("lla_data.dataforseo.requests.post", fail_post)

    response = keywords_for_keywords(
        ["anxiety"],
        mode="sandbox",
        use_cache=True,
        cache_dir=tmp_path,
    )

    assert response.from_cache is True
    assert response.path == cache_path


def test_keywords_for_keywords_requires_live_toggle(tmp_path: Path) -> None:
    with pytest.raises(DataForSEOLiveRunRequiredError):
        keywords_for_keywords(
            ["anxiety"],
            mode="live",
            run_live=False,
            use_cache=False,
            cache_dir=tmp_path,
        )


def test_normalize_keyword_items_handles_missing_fields() -> None:
    frame = normalize_keyword_items([{"keyword": "anxiety", "search_volume": 9900}])

    assert list(frame.columns) == [
        "keyword",
        "search_volume",
        "competition",
        "competition_index",
        "cpc",
        "low_top_of_page_bid",
        "high_top_of_page_bid",
        "monthly_searches",
    ]
    assert frame.iloc[0]["keyword"] == "anxiety"
    assert frame.iloc[0]["search_volume"] == 9900
    assert frame.iloc[0]["monthly_searches"] == []


def test_response_to_keyword_frame_handles_empty_items() -> None:
    response = CachedResponse(
        path=Path("/tmp/fake.json"),
        payload={"tasks": [{"result": [{"items": []}]}]},
        from_cache=True,
        mode="sandbox",
    )

    frame = response_to_keyword_frame(response)

    assert isinstance(frame, pd.DataFrame)
    assert frame.empty


def test_response_to_keyword_frame_handles_direct_result_rows() -> None:
    response = CachedResponse(
        path=Path("/tmp/fake.json"),
        payload={"tasks": [{"result": [{"keyword": "anxiety", "search_volume": 9900}]}]},
        from_cache=True,
        mode="sandbox",
    )

    frame = response_to_keyword_frame(response)

    assert len(frame) == 1
    assert frame.iloc[0]["keyword"] == "anxiety"


def test_response_to_keyword_frame_rejects_malformed_payload() -> None:
    response = CachedResponse(
        path=Path("/tmp/fake.json"),
        payload={"tasks": []},
        from_cache=True,
        mode="sandbox",
    )

    with pytest.raises(DataForSEOResponseError):
        response_to_keyword_frame(response)


def test_extract_lifeline_page_path_from_full_url() -> None:
    path = extract_lifeline_page_path("https://www.lifeline.org.au/get-help/support-toolkit/anxiety/?a=1")
    assert path == "/get-help/support-toolkit/anxiety"


def test_extract_lifeline_page_path_rejects_other_domains() -> None:
    with pytest.raises(ValueError):
        extract_lifeline_page_path("https://example.com/get-help")


def test_canonicalize_lifeline_url_accepts_path() -> None:
    assert canonicalize_lifeline_url("/get-help/support-toolkit/anxiety") == (
        "https://www.lifeline.org.au/get-help/support-toolkit/anxiety"
    )

"""Helpers for conservative DataForSEO keyword research workflows."""

from __future__ import annotations

import hashlib
import json
import os
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable, Literal
from urllib.parse import urljoin, urlparse

import pandas as pd
import requests
from requests.auth import HTTPBasicAuth

from lla_data.config import (
    DEFAULT_KEYWORD_LANGUAGE,
    DEFAULT_KEYWORD_LOCATION,
    SITE_BASE_URL,
)
from lla_data.url_utils import normalize_url_for_join


RunMode = Literal["sandbox", "live"]

REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_CACHE_DIR = REPO_ROOT / "notebooks" / "output"


class DataForSEOError(RuntimeError):
    """Base error for DataForSEO notebook helpers."""


class DataForSEOCredentialsError(DataForSEOError):
    """Raised when API credentials are missing."""


class DataForSEOAuthorizationError(DataForSEOError):
    """Raised when API credentials are rejected."""


class DataForSEOLiveRunRequiredError(DataForSEOError):
    """Raised when a notebook attempts a live request without explicit opt-in."""


class DataForSEOResponseError(DataForSEOError):
    """Raised when the API response is malformed or unusable."""


@dataclass(frozen=True)
class DataForSEOCredentials:
    email: str
    password: str


@dataclass(frozen=True)
class CachedResponse:
    path: Path
    payload: dict[str, Any]
    from_cache: bool
    mode: RunMode


def get_credentials() -> DataForSEOCredentials:
    """Load DataForSEO credentials from the environment."""
    email = os.getenv("DATAFORSEO_EMAIL", "").strip()
    password = os.getenv("DATAFORSEO_API_PASSWORD", "").strip()
    if not email or not password:
        raise DataForSEOCredentialsError(
            "Missing DataForSEO credentials. Set DATAFORSEO_EMAIL and DATAFORSEO_API_PASSWORD."
        )
    return DataForSEOCredentials(email=email, password=password)


def get_auth() -> HTTPBasicAuth:
    """Return HTTP basic auth for requests."""
    creds = get_credentials()
    return HTTPBasicAuth(creds.email, creds.password)


def get_base_url(mode: RunMode) -> str:
    if mode == "sandbox":
        return "https://sandbox.dataforseo.com"
    if mode == "live":
        return "https://api.dataforseo.com"
    raise ValueError(f"Unsupported run mode: {mode}")


def build_cache_path(
    endpoint: str,
    payload: dict[str, Any],
    mode: RunMode,
    cache_dir: Path | None = None,
) -> Path:
    """Build a deterministic cache path from endpoint + payload + mode."""
    normalized_payload = json.dumps(payload, sort_keys=True, separators=(",", ":"))
    digest = hashlib.sha256(f"{mode}|{endpoint}|{normalized_payload}".encode("utf-8")).hexdigest()[:16]
    safe_endpoint = endpoint.strip("/").replace("/", "__")
    target_dir = Path(cache_dir or DEFAULT_CACHE_DIR)
    return target_dir / f"dataforseo_{safe_endpoint}_{digest}.json"


def extract_lifeline_page_path(page_url: str, site_base_url: str = SITE_BASE_URL) -> str:
    """Validate a Lifeline URL and return the normalized page path."""
    value = str(page_url or "").strip()
    if not value:
        raise ValueError("PAGE_URL is required.")

    parsed = urlparse(value)
    if not parsed.scheme or not parsed.netloc:
        raise ValueError("PAGE_URL must be a full URL.")

    expected = urlparse(site_base_url)
    if parsed.netloc != expected.netloc:
        raise ValueError(f"PAGE_URL must use {expected.netloc}.")

    return normalize_url_for_join(value)


def canonicalize_lifeline_url(page_url_or_path: str, site_base_url: str = SITE_BASE_URL) -> str:
    """Return a canonical absolute Lifeline URL for DataForSEO page lookups."""
    value = str(page_url_or_path or "").strip()
    if not value:
        raise ValueError("A page URL or path is required.")

    parsed = urlparse(value)
    if parsed.scheme and parsed.netloc:
        extract_lifeline_page_path(value, site_base_url=site_base_url)
        path = normalize_url_for_join(value)
    else:
        path = normalize_url_for_join(value)

    return urljoin(site_base_url.rstrip("/") + "/", path.lstrip("/"))


def _request_json(
    endpoint: str,
    payload: dict[str, Any],
    *,
    mode: RunMode,
    use_cache: bool = True,
    run_live: bool = False,
    cache_dir: Path | None = None,
    timeout: int = 30,
) -> CachedResponse:
    cache_path = build_cache_path(endpoint=endpoint, payload=payload, mode=mode, cache_dir=cache_dir)
    if use_cache and cache_path.exists():
        return CachedResponse(
            path=cache_path,
            payload=json.loads(cache_path.read_text(encoding="utf-8")),
            from_cache=True,
            mode=mode,
        )

    if mode == "live" and not run_live:
        raise DataForSEOLiveRunRequiredError(
            "Live DataForSEO requests are disabled. Set RUN_LIVE=True after previewing the request."
        )

    response = requests.post(
        f"{get_base_url(mode)}{endpoint}",
        auth=get_auth(),
        json=[payload],
        timeout=timeout,
    )

    if response.status_code in {401, 403}:
        raise DataForSEOAuthorizationError("DataForSEO rejected the supplied credentials.")
    response.raise_for_status()

    parsed = response.json()
    if parsed.get("status_code") == 40100:
        raise DataForSEOAuthorizationError(parsed.get("status_message", "DataForSEO authorization failed."))
    if parsed.get("status_code", 0) >= 40000:
        raise DataForSEOResponseError(parsed.get("status_message", "DataForSEO request failed."))

    task = _extract_single_task(parsed)
    if task.get("status_code", 0) >= 40000:
        raise DataForSEOResponseError(task.get("status_message", "DataForSEO task failed."))

    cache_path.parent.mkdir(parents=True, exist_ok=True)
    cache_path.write_text(json.dumps(parsed, indent=2), encoding="utf-8")
    return CachedResponse(path=cache_path, payload=parsed, from_cache=False, mode=mode)


def _extract_single_task(payload: dict[str, Any]) -> dict[str, Any]:
    tasks = payload.get("tasks")
    if not isinstance(tasks, list) or not tasks:
        raise DataForSEOResponseError("DataForSEO response did not include any tasks.")
    task = tasks[0]
    if not isinstance(task, dict):
        raise DataForSEOResponseError("DataForSEO task payload is malformed.")
    return task


def _extract_items(payload: dict[str, Any]) -> list[dict[str, Any]]:
    task = _extract_single_task(payload)
    results = task.get("result")
    if not isinstance(results, list) or not results:
        return []
    if all(isinstance(item, dict) and "keyword" in item for item in results):
        return list(results)

    first_result = results[0]
    if not isinstance(first_result, dict):
        raise DataForSEOResponseError("DataForSEO result payload is malformed.")
    items = first_result.get("items") or []
    if not isinstance(items, list):
        raise DataForSEOResponseError("DataForSEO items payload is malformed.")
    return [item for item in items if isinstance(item, dict)]


def normalize_keyword_items(items: Iterable[dict[str, Any]]) -> pd.DataFrame:
    """Normalize keyword items into a stable pandas DataFrame."""
    rows: list[dict[str, Any]] = []
    for item in items:
        rows.append(
            {
                "keyword": item.get("keyword"),
                "search_volume": item.get("search_volume"),
                "competition": item.get("competition"),
                "competition_index": item.get("competition_index"),
                "cpc": item.get("cpc"),
                "low_top_of_page_bid": item.get("low_top_of_page_bid"),
                "high_top_of_page_bid": item.get("high_top_of_page_bid"),
                "monthly_searches": item.get("monthly_searches") or [],
            }
        )

    frame = pd.DataFrame(rows)
    if frame.empty:
        return pd.DataFrame(
            columns=[
                "keyword",
                "search_volume",
                "competition",
                "competition_index",
                "cpc",
                "low_top_of_page_bid",
                "high_top_of_page_bid",
                "monthly_searches",
            ]
        )
    return frame


def get_user_data(
    *,
    mode: RunMode = "live",
    run_live: bool = False,
    use_cache: bool = True,
    cache_dir: Path | None = None,
) -> CachedResponse:
    """Fetch account metadata from the appendix endpoint."""
    return _request_json(
        endpoint="/v3/appendix/user_data",
        payload={"api": "appendix", "function": "user_data"},
        mode=mode,
        run_live=run_live,
        use_cache=use_cache,
        cache_dir=cache_dir,
    )


def keywords_for_site(
    page_url: str,
    *,
    location_name: str = DEFAULT_KEYWORD_LOCATION,
    language_name: str = DEFAULT_KEYWORD_LANGUAGE,
    mode: RunMode = "sandbox",
    use_cache: bool = True,
    run_live: bool = False,
    cache_dir: Path | None = None,
) -> CachedResponse:
    """Fetch keyword ideas for a specific page URL."""
    payload = {
        "location_name": location_name,
        "language_name": language_name,
        "target": canonicalize_lifeline_url(page_url),
        "target_type": "page",
    }
    return _request_json(
        endpoint="/v3/keywords_data/google_ads/keywords_for_site/live",
        payload=payload,
        mode=mode,
        use_cache=use_cache,
        run_live=run_live,
        cache_dir=cache_dir,
    )


def keywords_for_keywords(
    seed_keywords: Iterable[str],
    *,
    location_name: str = DEFAULT_KEYWORD_LOCATION,
    language_name: str = DEFAULT_KEYWORD_LANGUAGE,
    mode: RunMode = "sandbox",
    use_cache: bool = True,
    run_live: bool = False,
    cache_dir: Path | None = None,
) -> CachedResponse:
    """Fetch related keyword ideas for one or more seed keywords."""
    cleaned = [str(keyword).strip() for keyword in seed_keywords if str(keyword).strip()]
    if not cleaned:
        raise ValueError("At least one seed keyword is required.")

    payload = {
        "location_name": location_name,
        "language_name": language_name,
        "keywords": cleaned,
    }
    return _request_json(
        endpoint="/v3/keywords_data/google_ads/keywords_for_keywords/live",
        payload=payload,
        mode=mode,
        use_cache=use_cache,
        run_live=run_live,
        cache_dir=cache_dir,
    )


def response_to_keyword_frame(response: CachedResponse) -> pd.DataFrame:
    """Convert a cached/raw API response into a normalized DataFrame."""
    return normalize_keyword_items(_extract_items(response.payload))

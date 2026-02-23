"""URL normalization utilities for GA4 and Search Console joins."""

from __future__ import annotations

from urllib.parse import urlparse


def normalize_url_for_join(url: str | None, fallback: str = "(unknown)") -> str:
    """Normalize a URL/path to a canonical page path for cross-source joins.

    Rules:
    - drop query string and fragment
    - keep path only (domain removed)
    - ensure a leading slash
    - remove trailing slash, except for root
    """
    if url is None:
        return fallback

    value = str(url).strip()
    if not value or value == "(unknown)":
        return fallback

    try:
        parsed = urlparse(value)
        path = parsed.path if (parsed.scheme or parsed.netloc) else value
    except Exception:
        path = value

    if not path:
        path = "/"

    # Drop query/fragment if the input was path-like and included them.
    path = path.split("?", maxsplit=1)[0].split("#", maxsplit=1)[0]

    if not path.startswith("/"):
        path = f"/{path}"

    if path != "/":
        path = path.rstrip("/")

    return path or "/"


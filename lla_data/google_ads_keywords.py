"""Google Ads keyword-planning helpers for editorial SEO notebooks."""

from __future__ import annotations

from dataclasses import dataclass
import os
import re
from typing import Any, Iterable, Sequence

import pandas as pd


DEFAULT_LOCATION_NAME = "Australia"
DEFAULT_LANGUAGE_NAME = "English"
DEFAULT_LOCATION_ID = "2840"
DEFAULT_LANGUAGE_ID = "1000"

_DEFAULT_LOCATION_IDS = {
    "australia": DEFAULT_LOCATION_ID,
}

_DEFAULT_LANGUAGE_IDS = {
    "english": DEFAULT_LANGUAGE_ID,
}

_KEYWORD_RESULT_COLUMNS = [
    "keyword",
    "source_seed",
    "seed_type",
    "avg_monthly_searches",
    "competition",
    "competition_index",
    "low_top_of_page_bid",
    "high_top_of_page_bid",
    "monthly_search_volumes",
    "close_variants",
    "location_name",
    "language_name",
]


class GoogleAdsConfigurationError(RuntimeError):
    """Raised when Google Ads credentials or package dependencies are missing."""


@dataclass(frozen=True)
class GoogleAdsRequestContext:
    """Resolved request metadata for a keyword-planning request."""

    customer_id: str
    location_id: str
    location_name: str
    language_id: str
    language_name: str

    @property
    def location_resource_name(self) -> str:
        return f"geoTargetConstants/{self.location_id}"

    @property
    def language_resource_name(self) -> str:
        return f"languageConstants/{self.language_id}"


def _empty_keyword_frame() -> pd.DataFrame:
    return pd.DataFrame(columns=_KEYWORD_RESULT_COLUMNS)


def _coerce_list(value: Any) -> list[Any]:
    if value is None:
        return []
    if isinstance(value, list):
        return value
    if isinstance(value, tuple):
        return list(value)
    try:
        return list(value)
    except TypeError:
        return [value]


def _micros_to_units(value: Any) -> float | None:
    if value in (None, ""):
        return None
    return round(float(value) / 1_000_000, 2)


def _coalesce_numeric(value: Any, default: float = 0.0) -> float:
    if value in (None, "") or pd.isna(value):
        return default
    return float(value)


def _enum_name(value: Any) -> str | None:
    if value is None:
        return None
    if hasattr(value, "name") and getattr(value, "name"):
        return str(getattr(value, "name"))
    text = str(value)
    return text.rsplit(".", maxsplit=1)[-1]


def _monthly_search_volume_rows(metrics: Any) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for item in _coerce_list(getattr(metrics, "monthly_search_volumes", None)):
        rows.append(
            {
                "year": getattr(item, "year", None),
                "month": _enum_name(getattr(item, "month", None)),
                "monthly_searches": getattr(item, "monthly_searches", None),
            }
        )
    return rows


def _close_variants(result: Any) -> list[str]:
    return [str(value) for value in _coerce_list(getattr(result, "close_variants", None))]


def _keyword_metrics_row(
    result: Any,
    *,
    metrics_attr: str,
    source_seed: str,
    seed_type: str,
    location_name: str,
    language_name: str,
) -> dict[str, Any]:
    metrics = getattr(result, metrics_attr, None)
    keyword = str(getattr(result, "text", "") or "").strip()

    return {
        "keyword": keyword,
        "source_seed": source_seed,
        "seed_type": seed_type,
        "avg_monthly_searches": getattr(metrics, "avg_monthly_searches", None) if metrics else None,
        "competition": _enum_name(getattr(metrics, "competition", None)) if metrics else None,
        "competition_index": getattr(metrics, "competition_index", None) if metrics else None,
        "low_top_of_page_bid": _micros_to_units(getattr(metrics, "low_top_of_page_bid_micros", None)) if metrics else None,
        "high_top_of_page_bid": _micros_to_units(getattr(metrics, "high_top_of_page_bid_micros", None)) if metrics else None,
        "monthly_search_volumes": _monthly_search_volume_rows(metrics) if metrics else [],
        "close_variants": _close_variants(result),
        "location_name": location_name,
        "language_name": language_name,
    }


def normalize_keyword_idea_results(
    results: Iterable[Any],
    *,
    source_seed: str,
    seed_type: str,
    location_name: str = DEFAULT_LOCATION_NAME,
    language_name: str = DEFAULT_LANGUAGE_NAME,
) -> pd.DataFrame:
    """Flatten Google Ads keyword idea results into a stable DataFrame."""
    rows = [
        _keyword_metrics_row(
            result,
            metrics_attr="keyword_idea_metrics",
            source_seed=source_seed,
            seed_type=seed_type,
            location_name=location_name,
            language_name=language_name,
        )
        for result in results
    ]
    if not rows:
        return _empty_keyword_frame()
    return pd.DataFrame(rows, columns=_KEYWORD_RESULT_COLUMNS)


def normalize_historical_metrics_results(
    results: Iterable[Any],
    *,
    source_seed: str,
    seed_type: str,
    location_name: str = DEFAULT_LOCATION_NAME,
    language_name: str = DEFAULT_LANGUAGE_NAME,
) -> pd.DataFrame:
    """Flatten Google Ads historical metrics results into a stable DataFrame."""
    rows = [
        _keyword_metrics_row(
            result,
            metrics_attr="keyword_metrics",
            source_seed=source_seed,
            seed_type=seed_type,
            location_name=location_name,
            language_name=language_name,
        )
        for result in results
    ]
    if not rows:
        return _empty_keyword_frame()
    return pd.DataFrame(rows, columns=_KEYWORD_RESULT_COLUMNS)


def normalize_keyword_text(value: str) -> str:
    """Normalize a keyword for exact and fuzzy matching."""
    text = str(value or "").lower()
    text = re.sub(r"[^a-z0-9]+", " ", text)
    return re.sub(r"\s+", " ", text).strip()


def keyword_token_set(value: str) -> set[str]:
    return set(normalize_keyword_text(value).split())


def lexical_similarity(value: str, candidates: Sequence[str]) -> float:
    """Return the strongest token-overlap match against candidate terms."""
    source_tokens = keyword_token_set(value)
    if not source_tokens or not candidates:
        return 0.0

    best = 0.0
    for candidate in candidates:
        candidate_tokens = keyword_token_set(candidate)
        if not candidate_tokens:
            continue
        overlap = len(source_tokens & candidate_tokens)
        union = len(source_tokens | candidate_tokens)
        similarity = overlap / union if union else 0.0
        if similarity > best:
            best = similarity
    return round(best, 4)


def score_page_opportunity(
    *,
    avg_monthly_searches: float | int | None,
    current_clicks: float | int | None,
    current_impressions: float | int | None,
    current_avg_position: float | int | None,
    lexical_similarity_score: float,
) -> float:
    """Transparent 0-100 keyword opportunity score for page expansion."""
    avg_monthly_searches = _coalesce_numeric(avg_monthly_searches)
    current_clicks = _coalesce_numeric(current_clicks)
    current_impressions = _coalesce_numeric(current_impressions)

    demand_score = min(avg_monthly_searches / 1000.0, 1.0)
    coverage_score = 1.0 if current_impressions <= 0 else max(0.0, 1.0 - min(current_clicks / max(avg_monthly_searches, 1.0), 1.0))
    position_gap_score = 1.0
    if current_avg_position not in (None, "") and not pd.isna(current_avg_position):
        position_gap_score = min(max((_coalesce_numeric(current_avg_position) - 3.0) / 10.0, 0.0), 1.0)

    score = (
        (0.45 * demand_score)
        + (0.25 * coverage_score)
        + (0.20 * position_gap_score)
        + (0.10 * lexical_similarity_score)
    ) * 100
    return round(score, 1)


def classify_page_keyword(
    *,
    avg_monthly_searches: float | int | None,
    current_impressions: float | int | None,
    current_avg_position: float | int | None,
    lexical_similarity_score: float,
) -> str:
    """Classify a keyword into practical editorial action buckets."""
    impressions = _coalesce_numeric(current_impressions)
    avg_monthly_searches = _coalesce_numeric(avg_monthly_searches)
    position = None
    if current_avg_position not in (None, "") and not pd.isna(current_avg_position):
        position = _coalesce_numeric(current_avg_position)

    if impressions > 0 and lexical_similarity_score >= 0.8 and (position is None or position <= 10):
        return "already_captured"
    if avg_monthly_searches >= 100 and impressions <= 0 and lexical_similarity_score >= 0.45:
        return "high-demand_gap"
    if lexical_similarity_score >= 0.3:
        return "adjacent_opportunity"
    return "candidate_new_article"


def recommended_editorial_action(category: str) -> str:
    if category == "already_captured":
        return "keep_as_supporting_term"
    if category in {"adjacent_opportunity", "high-demand_gap"}:
        return "expand_on_page"
    return "consider_new_article"


def annotate_page_opportunities(
    external_keywords: pd.DataFrame,
    existing_queries: pd.DataFrame,
) -> pd.DataFrame:
    """Merge external keyword demand with current page query coverage."""
    if external_keywords.empty:
        return external_keywords.copy()

    working = external_keywords.copy()
    working["keyword_normalized"] = working["keyword"].map(normalize_keyword_text)

    existing = existing_queries.copy()
    if existing.empty:
        existing = pd.DataFrame(columns=["query", "clicks", "impressions", "avg_position"])

    existing["query_normalized"] = existing["query"].map(normalize_keyword_text)
    existing_lookup = (
        existing.groupby("query_normalized", as_index=False)
        .agg(
            current_query=("query", "first"),
            current_clicks=("clicks", "sum"),
            current_impressions=("impressions", "sum"),
            current_avg_position=("avg_position", "mean"),
        )
    )

    working = working.merge(
        existing_lookup,
        how="left",
        left_on="keyword_normalized",
        right_on="query_normalized",
    )

    candidate_queries = existing["query"].dropna().astype(str).tolist()
    working["lexical_similarity"] = working["keyword"].map(lambda value: lexical_similarity(value, candidate_queries))
    working["current_clicks"] = working["current_clicks"].fillna(0)
    working["current_impressions"] = working["current_impressions"].fillna(0)
    working["opportunity_category"] = working.apply(
        lambda row: classify_page_keyword(
            avg_monthly_searches=row.get("avg_monthly_searches"),
            current_impressions=row.get("current_impressions"),
            current_avg_position=row.get("current_avg_position"),
            lexical_similarity_score=float(row.get("lexical_similarity") or 0),
        ),
        axis=1,
    )
    working["recommended_action"] = working["opportunity_category"].map(recommended_editorial_action)
    working["opportunity_score"] = working.apply(
        lambda row: score_page_opportunity(
            avg_monthly_searches=row.get("avg_monthly_searches"),
            current_clicks=row.get("current_clicks"),
            current_impressions=row.get("current_impressions"),
            current_avg_position=row.get("current_avg_position"),
            lexical_similarity_score=float(row.get("lexical_similarity") or 0),
        ),
        axis=1,
    )

    ordered_columns = _KEYWORD_RESULT_COLUMNS + [
        "keyword_normalized",
        "current_query",
        "current_clicks",
        "current_impressions",
        "current_avg_position",
        "lexical_similarity",
        "opportunity_category",
        "recommended_action",
        "opportunity_score",
    ]
    return working[ordered_columns].sort_values(
        ["opportunity_score", "avg_monthly_searches"],
        ascending=[False, False],
    )


def label_site_coverage(
    *,
    site_clicks: float | int | None,
    site_impressions: float | int | None,
) -> str:
    impressions = _coalesce_numeric(site_impressions)
    clicks = _coalesce_numeric(site_clicks)
    if impressions >= 100 or clicks >= 10:
        return "already_served"
    if impressions > 0:
        return "weakly_served"
    return "not_served"


def cluster_keywords(
    keywords: pd.DataFrame,
    *,
    similarity_threshold: float = 0.5,
) -> pd.DataFrame:
    """Assign lightweight editorial clusters to keyword ideas."""
    if keywords.empty:
        return keywords.copy()

    working = keywords.copy()
    working["keyword_normalized"] = working["keyword"].map(normalize_keyword_text)
    if "avg_monthly_searches" not in working:
        working["avg_monthly_searches"] = 0
    working = working.sort_values("avg_monthly_searches", ascending=False).reset_index(drop=True)

    clusters: list[dict[str, Any]] = []
    cluster_ids: list[int] = []
    cluster_labels: list[str] = []

    for row in working.itertuples(index=False):
        keyword = getattr(row, "keyword")
        normalized = normalize_keyword_text(keyword)
        close_variants = {normalize_keyword_text(value) for value in _coerce_list(getattr(row, "close_variants", []))}
        tokens = keyword_token_set(keyword)

        cluster_id = None
        for cluster in clusters:
            cluster_tokens = cluster["token_union"]
            similarity = 0.0
            union = len(tokens | cluster_tokens)
            if union:
                similarity = len(tokens & cluster_tokens) / union

            if (
                normalized == cluster["label_normalized"]
                or normalized in cluster["variant_terms"]
                or cluster["label_normalized"] in close_variants
                or close_variants & cluster["variant_terms"]
                or similarity >= similarity_threshold
            ):
                cluster_id = cluster["cluster_id"]
                cluster["token_union"] = cluster_tokens | tokens
                cluster["variant_terms"].add(normalized)
                cluster["variant_terms"].update(close_variants)
                break

        if cluster_id is None:
            cluster_id = len(clusters) + 1
            clusters.append(
                {
                    "cluster_id": cluster_id,
                    "label": keyword,
                    "label_normalized": normalized,
                    "token_union": tokens,
                    "variant_terms": {normalized, *close_variants},
                }
            )

        cluster_ids.append(cluster_id)
        cluster_labels.append(next(cluster["label"] for cluster in clusters if cluster["cluster_id"] == cluster_id))

    working["cluster_id"] = cluster_ids
    working["cluster_label"] = cluster_labels
    return working


def summarize_keyword_clusters(clustered_keywords: pd.DataFrame) -> pd.DataFrame:
    """Summarize editorial clusters and suggest content shape."""
    if clustered_keywords.empty:
        return pd.DataFrame(
            columns=[
                "cluster_id",
                "cluster_label",
                "representative_keyword",
                "cluster_avg_monthly_searches",
                "keyword_count",
                "top_keywords",
                "mean_competition_index",
                "recommended_content_shape",
            ]
        )

    summary = (
        clustered_keywords.groupby(["cluster_id", "cluster_label"], as_index=False)
        .agg(
            representative_keyword=("keyword", "first"),
            cluster_avg_monthly_searches=("avg_monthly_searches", "sum"),
            keyword_count=("keyword", "nunique"),
            mean_competition_index=("competition_index", "mean"),
        )
    )

    top_keywords = (
        clustered_keywords.sort_values(["cluster_id", "avg_monthly_searches"], ascending=[True, False])
        .groupby("cluster_id")["keyword"]
        .apply(lambda values: ", ".join(values.head(5)))
        .rename("top_keywords")
        .reset_index()
    )

    summary = summary.merge(top_keywords, on="cluster_id", how="left")

    def _shape(row: pd.Series) -> str:
        total = float(row["cluster_avg_monthly_searches"] or 0)
        count = int(row["keyword_count"] or 0)
        if total < 100:
            return "not enough demand"
        if total >= 1500 and count >= 3:
            return "split article set"
        return "single article"

    summary["recommended_content_shape"] = summary.apply(_shape, axis=1)
    return summary.sort_values("cluster_avg_monthly_searches", ascending=False)


def build_request_context(
    *,
    customer_id: str | None = None,
    location_name: str = DEFAULT_LOCATION_NAME,
    language_name: str = DEFAULT_LANGUAGE_NAME,
) -> GoogleAdsRequestContext:
    resolved_customer_id = normalize_customer_id(customer_id or os.getenv("GOOGLE_ADS_CUSTOMER_ID"))
    if not resolved_customer_id:
        raise GoogleAdsConfigurationError(
            "Missing Google Ads customer ID. Set GOOGLE_ADS_CUSTOMER_ID or pass customer_id explicitly."
        )

    location_id, resolved_location_name = _resolve_market_id(
        value=location_name,
        mapping=_DEFAULT_LOCATION_IDS,
        default_name=DEFAULT_LOCATION_NAME,
        default_id=DEFAULT_LOCATION_ID,
        kind="location",
    )
    language_id, resolved_language_name = _resolve_market_id(
        value=language_name,
        mapping=_DEFAULT_LANGUAGE_IDS,
        default_name=DEFAULT_LANGUAGE_NAME,
        default_id=DEFAULT_LANGUAGE_ID,
        kind="language",
    )

    return GoogleAdsRequestContext(
        customer_id=resolved_customer_id,
        location_id=location_id,
        location_name=resolved_location_name,
        language_id=language_id,
        language_name=resolved_language_name,
    )


def normalize_customer_id(value: str | None) -> str | None:
    if value is None:
        return None
    cleaned = re.sub(r"[^0-9]", "", str(value))
    return cleaned or None


def _resolve_market_id(
    *,
    value: str,
    mapping: dict[str, str],
    default_name: str,
    default_id: str,
    kind: str,
) -> tuple[str, str]:
    cleaned = str(value or "").strip()
    if not cleaned:
        return default_id, default_name
    if cleaned.isdigit():
        return cleaned, cleaned

    lookup = mapping.get(cleaned.lower())
    if lookup:
        return lookup, cleaned

    raise ValueError(
        f"Unsupported {kind} '{cleaned}'. Use the default {default_name!r} or pass the Google Ads numeric ID."
    )


def _load_google_ads_client():
    try:
        from google.ads.googleads.client import GoogleAdsClient
    except ImportError as exc:
        raise GoogleAdsConfigurationError(
            "The 'google-ads' package is not installed. Add it to the environment before running these notebooks."
        ) from exc

    config_path = os.getenv("GOOGLE_ADS_CONFIGURATION_FILE")
    if config_path:
        return GoogleAdsClient.load_from_storage(path=config_path)

    required_env_vars = {
        "GOOGLE_ADS_DEVELOPER_TOKEN": os.getenv("GOOGLE_ADS_DEVELOPER_TOKEN"),
        "GOOGLE_ADS_CLIENT_ID": os.getenv("GOOGLE_ADS_CLIENT_ID"),
        "GOOGLE_ADS_CLIENT_SECRET": os.getenv("GOOGLE_ADS_CLIENT_SECRET"),
        "GOOGLE_ADS_REFRESH_TOKEN": os.getenv("GOOGLE_ADS_REFRESH_TOKEN"),
    }
    missing = [name for name, value in required_env_vars.items() if not value]
    if missing:
        missing_str = ", ".join(sorted(missing))
        raise GoogleAdsConfigurationError(
            f"Missing Google Ads credentials: {missing_str}. Set those env vars or GOOGLE_ADS_CONFIGURATION_FILE."
        )

    config_dict: dict[str, Any] = {
        "developer_token": required_env_vars["GOOGLE_ADS_DEVELOPER_TOKEN"],
        "client_id": required_env_vars["GOOGLE_ADS_CLIENT_ID"],
        "client_secret": required_env_vars["GOOGLE_ADS_CLIENT_SECRET"],
        "refresh_token": required_env_vars["GOOGLE_ADS_REFRESH_TOKEN"],
        "use_proto_plus": True,
    }
    login_customer_id = normalize_customer_id(os.getenv("GOOGLE_ADS_LOGIN_CUSTOMER_ID"))
    if login_customer_id:
        config_dict["login_customer_id"] = login_customer_id

    return GoogleAdsClient.load_from_dict(config_dict)


def _extract_response_results(response: Any) -> list[Any]:
    if hasattr(response, "results"):
        return list(response.results)
    return list(response)


def _clean_keyword_seed_texts(keyword_texts: Sequence[str] | None) -> list[str]:
    cleaned: list[str] = []
    for keyword in keyword_texts or []:
        value = str(keyword or "").strip()
        if value and value not in cleaned:
            cleaned.append(value)
    return cleaned


def generate_keyword_ideas(
    *,
    keyword_texts: Sequence[str] | None = None,
    page_url: str | None = None,
    customer_id: str | None = None,
    location_name: str = DEFAULT_LOCATION_NAME,
    language_name: str = DEFAULT_LANGUAGE_NAME,
    max_ideas: int = 100,
    client: Any | None = None,
) -> pd.DataFrame:
    """Request Google Ads keyword ideas and return normalized results."""
    cleaned_keywords = _clean_keyword_seed_texts(keyword_texts)
    if not cleaned_keywords and not page_url:
        raise ValueError("Provide keyword_texts, page_url, or both.")

    ads_client = client or _load_google_ads_client()
    context = build_request_context(
        customer_id=customer_id,
        location_name=location_name,
        language_name=language_name,
    )

    request = ads_client.get_type("GenerateKeywordIdeasRequest")
    request.customer_id = context.customer_id
    request.language = context.language_resource_name
    request.geo_target_constants.append(context.location_resource_name)
    request.include_adult_keywords = False
    request.keyword_plan_network = ads_client.enums.KeywordPlanNetworkEnum.GOOGLE_SEARCH

    if cleaned_keywords and page_url:
        request.keyword_and_url_seed.url = page_url
        request.keyword_and_url_seed.keywords.extend(cleaned_keywords)
        source_seed = page_url
        seed_type = "keyword_and_url"
    elif cleaned_keywords:
        request.keyword_seed.keywords.extend(cleaned_keywords)
        source_seed = ", ".join(cleaned_keywords[:5])
        seed_type = "keyword"
    else:
        request.url_seed.url = str(page_url)
        source_seed = str(page_url)
        seed_type = "url"

    service = ads_client.get_service("KeywordPlanIdeaService")
    response = service.generate_keyword_ideas(request=request)
    normalized = normalize_keyword_idea_results(
        _extract_response_results(response),
        source_seed=source_seed,
        seed_type=seed_type,
        location_name=context.location_name,
        language_name=context.language_name,
    )
    return normalized.sort_values(["avg_monthly_searches", "keyword"], ascending=[False, True]).head(max_ideas)


def generate_historical_metrics(
    *,
    keywords: Sequence[str],
    customer_id: str | None = None,
    location_name: str = DEFAULT_LOCATION_NAME,
    language_name: str = DEFAULT_LANGUAGE_NAME,
    client: Any | None = None,
) -> pd.DataFrame:
    """Request Google Ads keyword historical metrics and return normalized results."""
    cleaned_keywords = _clean_keyword_seed_texts(keywords)
    if not cleaned_keywords:
        raise ValueError("Provide at least one keyword.")

    ads_client = client or _load_google_ads_client()
    context = build_request_context(
        customer_id=customer_id,
        location_name=location_name,
        language_name=language_name,
    )

    request = ads_client.get_type("GenerateKeywordHistoricalMetricsRequest")
    request.customer_id = context.customer_id
    request.language = context.language_resource_name
    request.geo_target_constants.append(context.location_resource_name)
    request.keyword_plan_network = ads_client.enums.KeywordPlanNetworkEnum.GOOGLE_SEARCH
    request.keywords.extend(cleaned_keywords)

    service = ads_client.get_service("KeywordPlanIdeaService")
    response = service.generate_keyword_historical_metrics(request=request)
    normalized = normalize_historical_metrics_results(
        _extract_response_results(response),
        source_seed=", ".join(cleaned_keywords[:5]),
        seed_type="historical_metrics",
        location_name=context.location_name,
        language_name=context.language_name,
    )
    return normalized.sort_values(["avg_monthly_searches", "keyword"], ascending=[False, True]).reset_index(drop=True)

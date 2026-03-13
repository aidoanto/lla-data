from types import SimpleNamespace

import pandas as pd

from lla_data.google_ads_keywords import (
    annotate_page_opportunities,
    cluster_keywords,
    label_site_coverage,
    normalize_historical_metrics_results,
    normalize_keyword_idea_results,
    summarize_keyword_clusters,
)


def _metrics(
    *,
    avg_monthly_searches: int | None = 1200,
    competition: str | None = "HIGH",
    competition_index: int | None = 80,
    low_bid_micros: int | None = 1_500_000,
    high_bid_micros: int | None = 4_000_000,
    monthly: list[SimpleNamespace] | None = None,
) -> SimpleNamespace:
    return SimpleNamespace(
        avg_monthly_searches=avg_monthly_searches,
        competition=SimpleNamespace(name=competition) if competition else None,
        competition_index=competition_index,
        low_top_of_page_bid_micros=low_bid_micros,
        high_top_of_page_bid_micros=high_bid_micros,
        monthly_search_volumes=monthly or [
            SimpleNamespace(year=2025, month=SimpleNamespace(name="JANUARY"), monthly_searches=800),
            SimpleNamespace(year=2025, month=SimpleNamespace(name="FEBRUARY"), monthly_searches=900),
        ],
    )


def test_normalize_keyword_idea_results_flattens_metrics() -> None:
    results = [
        SimpleNamespace(
            text="nervousness",
            keyword_idea_metrics=_metrics(),
            close_variants=["nervousness symptoms", "what is nervousness"],
        )
    ]

    df = normalize_keyword_idea_results(
        results,
        source_seed="/help/anxiety",
        seed_type="keyword_and_url",
    )

    assert list(df.columns)[:5] == [
        "keyword",
        "source_seed",
        "seed_type",
        "avg_monthly_searches",
        "competition",
    ]
    assert df.loc[0, "keyword"] == "nervousness"
    assert df.loc[0, "avg_monthly_searches"] == 1200
    assert df.loc[0, "competition"] == "HIGH"
    assert df.loc[0, "low_top_of_page_bid"] == 1.5
    assert df.loc[0, "close_variants"] == ["nervousness symptoms", "what is nervousness"]
    assert df.loc[0, "monthly_search_volumes"][0]["month"] == "JANUARY"


def test_normalize_historical_metrics_results_handles_missing_metrics() -> None:
    results = [SimpleNamespace(text="bushfires", keyword_metrics=None, close_variants=[])]

    df = normalize_historical_metrics_results(
        results,
        source_seed="bushfires",
        seed_type="historical_metrics",
    )

    assert df.loc[0, "keyword"] == "bushfires"
    assert pd.isna(df.loc[0, "avg_monthly_searches"])
    assert df.loc[0, "monthly_search_volumes"] == []


def test_normalize_keyword_idea_results_empty_frame_has_stable_columns() -> None:
    df = normalize_keyword_idea_results([], source_seed="seed", seed_type="keyword")
    assert df.empty
    assert "monthly_search_volumes" in df.columns
    assert "close_variants" in df.columns


def test_annotate_page_opportunities_scores_and_labels() -> None:
    external = pd.DataFrame(
        [
            {
                "keyword": "nervousness symptoms",
                "source_seed": "/help/anxiety",
                "seed_type": "keyword_and_url",
                "avg_monthly_searches": 5400,
                "competition": "HIGH",
                "competition_index": 90,
                "low_top_of_page_bid": 1.2,
                "high_top_of_page_bid": 3.4,
                "monthly_search_volumes": [],
                "close_variants": ["nervousness symptoms"],
                "location_name": "Australia",
                "language_name": "English",
            }
        ]
    )
    existing = pd.DataFrame(
        [
            {"query": "anxiety symptoms", "clicks": 50, "impressions": 500, "avg_position": 6.2},
        ]
    )

    annotated = annotate_page_opportunities(external, existing)

    assert annotated.loc[0, "opportunity_category"] == "adjacent_opportunity"
    assert annotated.loc[0, "recommended_action"] == "expand_on_page"
    assert annotated.loc[0, "opportunity_score"] > 0


def test_cluster_keywords_uses_close_variants_and_similarity() -> None:
    df = pd.DataFrame(
        [
            {
                "keyword": "bushfire anxiety",
                "avg_monthly_searches": 1000,
                "competition_index": 50,
                "close_variants": ["anxiety after bushfire"],
            },
            {
                "keyword": "anxiety after bushfire",
                "avg_monthly_searches": 800,
                "competition_index": 45,
                "close_variants": [],
            },
            {
                "keyword": "cyclone anxiety",
                "avg_monthly_searches": 120,
                "competition_index": 30,
                "close_variants": [],
            },
        ]
    )

    clustered = cluster_keywords(df)
    summary = summarize_keyword_clusters(clustered)

    assert clustered.loc[0, "cluster_id"] == clustered.loc[1, "cluster_id"]
    assert summary.iloc[0]["cluster_avg_monthly_searches"] >= 1800


def test_label_site_coverage_thresholds() -> None:
    assert label_site_coverage(site_clicks=12, site_impressions=50) == "already_served"
    assert label_site_coverage(site_clicks=1, site_impressions=4) == "weakly_served"
    assert label_site_coverage(site_clicks=0, site_impressions=0) == "not_served"

# SEO First-Run Checklist (GA4 + Search Console)

Use this checklist the first time you stand up the curated SEO models in BigQuery.

Scope:
- Project: `lifeline-website-480522`
- Datasets: `analytics_315584957`, `searchconsole`
- Location: Sydney (`australia-southeast1`)

## 1) Pre-flight Checks

1. Confirm local auth:
   ```bash
   gcloud auth application-default login
   ```
2. Confirm raw Search Console tables exist:
   - `searchconsole.searchdata_site_impression`
   - `searchconsole.searchdata_url_impression`
3. Confirm GA4 raw export exists:
   - `analytics_315584957.events_*`

## 2) Run SQL Models In Dependency Order

Run these files in this exact order:

1. `sql/gsc_curated_site_daily.sql`
2. `sql/gsc_curated_url_daily.sql`
3. `sql/gsc_curated_query_page_daily.sql`
4. `sql/ga4_curated_page_daily.sql`
5. `sql/seo_page_daily.sql`

Why this order:
- `seo_page_daily` depends on both curated GSC URL data and curated GA4 page data.
- The two GSC curated tables are independent and can run first.

## 3) Smoke Checks After Each Model

Run checks from `sql/seo_smoke_checks.sql` after each model creation.

Minimum checks:
1. Row counts are non-zero for at least recent days.
2. `MAX(report_date)` is recent (expect slight lag for Search Console).
3. No duplicate keys at expected grain.
4. Key fields (`report_date`, `page_path`) are mostly populated.

Early-import note:
- Since import started recently, low row counts are expected at first.
- Focus on schema correctness and freshness progression day by day.

## 4) Set Up Scheduled Queries

Recommended schedule:
- Daily (early morning Sydney):
  - `sql/gsc_curated_site_daily.sql`
  - `sql/gsc_curated_url_daily.sql`
  - `sql/gsc_curated_query_page_daily.sql`
  - `sql/ga4_curated_page_daily.sql`
  - `sql/seo_page_daily.sql`
- Weekly (Monday morning Sydney):
  - `sql/weekly_seo_health_check.sql`

Tip:
- Keep destination tables exactly as defined in each SQL file.
- If you use a scheduler chain, ensure `seo_page_daily` runs last.

## 5) Validate With Python Script

Run:

```bash
uv run python scripts/validate_seo_models.py
```

Look for:
- Fresh `max_report_date`
- Near-zero null-rate for `page_path` and `report_date`
- Zero duplicates at (`report_date`, `page_path`) in `seo_page_daily`

## 6) First Notebook Smoke Run

Run these notebooks in order:
1. `notebooks/seo/01_search_contribution_overview.ipynb`
2. `notebooks/seo/02_top_pages_search_performance.ipynb`
3. `notebooks/seo/03_query_drivers_by_page.ipynb`
4. `notebooks/seo/04_opportunity_watchlist.ipynb`

If outputs look sparse:
- Reduce date window to 7 days
- Lower impression thresholds temporarily
- Recheck again after another day of ingest

## 7) Go/No-Go Criteria

You are ready for regular use when:
- All curated tables build successfully
- `seo_page_daily` has recent data and expected columns
- Smoke checks pass with no duplicate grain issues
- At least one SEO notebook renders end-to-end without edits


# Search Console Historical Backfill (API -> BigQuery)

Use this when your bulk export only has recent weeks but you need older history (for example from `2025-01-01`).

## What this does

1. Pulls historical Search Console data from API (daily slices).
2. Writes into backfill tables:
   - `searchconsole.searchdata_site_impression_backfill`
   - `searchconsole.searchdata_url_impression_backfill`
3. Creates combined source views:
   - `searchconsole.searchdata_site_impression_all`
   - `searchconsole.searchdata_url_impression_all`
4. Curated SQL models read from these `_all` views.

Overlap rule:
- Live bulk export rows win for overlapping dates.
- Backfill rows are only used for dates before live export starts.

## One-time setup

Install dependencies (already tracked in project):

```bash
uv sync
```

Ensure local auth works:

```bash
gcloud auth application-default login
```

## Run historical backfill

Example for Jan 1, 2025 until today:

```bash
uv run python scripts/backfill_gsc_api_to_bigquery.py --start-date 2025-01-01
```

Notes:
- The script auto-detects `site_url` from existing raw tables.
- If needed, pass a specific property:

```bash
uv run python scripts/backfill_gsc_api_to_bigquery.py \
  --start-date 2025-01-01 \
  --site-url "sc-domain:lifeline.org.au"
```

## Apply combined views and rebuild curated models

```bash
bq query --use_legacy_sql=false < sql/searchconsole_combined_raw_views.sql
bq query --use_legacy_sql=false < sql/gsc_curated_site_daily.sql
bq query --use_legacy_sql=false < sql/gsc_curated_url_daily.sql
bq query --use_legacy_sql=false < sql/gsc_curated_query_page_daily.sql
bq query --use_legacy_sql=false < sql/ga4_curated_page_daily.sql
bq query --use_legacy_sql=false < sql/seo_page_daily.sql
```

## Validate

```bash
uv run python scripts/validate_seo_models.py
```

Quick date check:

```bash
bq query --use_legacy_sql=false '
SELECT
  MIN(report_date) AS min_report_date,
  MAX(report_date) AS max_report_date
FROM `lifeline-website-480522.searchconsole.seo_page_daily`'
```

# Search Console Data Dictionary

This document explains the Search Console tables used in this repo and how they map to curated models.

## Scope

- Project: `lifeline-website-480522`
- Dataset: `searchconsole`
- Location: Sydney (`australia-southeast1`)

## Raw Source Tables

### `searchdata_site_impression`

Expected grain:
- One row per day and Search Console dimensions (site/search type/device/country).

Common columns used:
- `data_date` (`DATE`)
- `site_url` (`STRING`)
- `search_type` (`STRING`)
- `country` (`STRING`)
- `device` (`STRING`)
- `clicks` (`INT64`)
- `impressions` (`INT64`)
- `sum_top_position` (`FLOAT64`), used to derive average position

### `searchdata_url_impression`

Expected grain:
- One row per day + URL + query and related dimensions.

Common columns used:
- `data_date` (`DATE`)
- `site_url` (`STRING`)
- `url` (`STRING`)
- `query` (`STRING`)
- `is_anonymized_query` (`BOOL`)
- `search_type` (`STRING`)
- `country` (`STRING`)
- `device` (`STRING`)
- `clicks` (`INT64`)
- `impressions` (`INT64`)
- `sum_top_position` (`FLOAT64`)

## Curated Tables In This Repo

### `curated_search_site_daily`

Built by `sql/gsc_curated_site_daily.sql`.

Grain:
- `report_date`, `site_url`, `search_type`, `country`, `device`

Metrics:
- `clicks`, `impressions`, `ctr`, `avg_position`

### `curated_search_url_daily`

Built by `sql/gsc_curated_url_daily.sql`.

Grain:
- `report_date`, `site_url`, `url`, `search_type`, `country`, `device`, `page_path`

Metrics:
- `clicks`, `impressions`, `ctr`, `avg_position`

### `curated_search_query_page_daily`

Built by `sql/gsc_curated_query_page_daily.sql`.

Grain:
- `report_date`, `site_url`, `page_path`, `query`, `is_anonymized_query`, `search_type`, `country`, `device`

Metrics:
- `clicks`, `impressions`, `ctr`, `avg_position`

### `seo_page_daily`

Built by `sql/seo_page_daily.sql` (joins Search Console and GA4 page-day metrics).

Grain:
- `report_date`, `page_path`

Core fields:
- GSC: `gsc_clicks`, `gsc_impressions`, `gsc_ctr`, `gsc_avg_position`
- GA4: `total_sessions`, `organic_sessions`, `users`, `page_views`, `engaged_sessions`
- Derived: `search_share`, `click_to_session_ratio`, `impression_to_click_band`

## Join Key Standard

Join key between GA4 and Search Console is:
- Date (`report_date` / `event_day`)
- Canonical page path (`page_path`)

Canonicalization rules:
- Remove domain
- Remove query strings/fragments
- Keep leading slash
- Remove trailing slash (except `/`)

## Important Caveats

- Search Console can lag behind same-day activity; treat most recent days carefully.
- Query anonymization can hide some low-volume terms.
- Early weeks after enabling export will have sparse history.
- Position is derived from `sum_top_position / impressions + 1`, so low-impression rows are noisy.

## Safety Checks Before Analysis

1. Confirm yesterday has rows in curated tables.
2. Check `page_path` null/unknown rate.
3. Check duplicate rows at expected grain.
4. Filter very low-impression rows before making optimization decisions.


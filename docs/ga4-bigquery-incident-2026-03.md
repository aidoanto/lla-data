# GA4 BigQuery Incident Summary (March 2026)

## Summary

In March 2026, the original GA4 BigQuery dataset in project `lifeline-website-480522` was deleted and could not be restored in-place because BigQuery kept the dataset ID locked after an undelete of the wrong version.

Forward GA4 export has now been re-established in a new Google Cloud project:

- GA4 raw export project: `lifeline-web-analytics`
- GA4 raw export dataset: `analytics_315584957`
- Location: `australia-southeast1`

Search Console remains in the original project:

- Search Console project: `lifeline-website-480522`
- Search Console dataset: `searchconsole`

The repo has been updated to support this split-project setup.

## What Happened

The original GA4 export dataset was `lifeline-website-480522.analytics_315584957`.

Audit logs showed:

- `cassie.chen@lifeline.org.au` deleted `analytics_315584957` on `2026-03-18 23:02:24 UTC`
- the dataset was recreated as an empty `US` dataset on `2026-03-18 23:09:14 UTC`
- `cassie.chen@lifeline.org.au` deleted `analytics_315584957` again on `2026-03-18 23:13:01 UTC`
- the newly created empty dataset was then undeleted on `2026-03-18 23:14:00 UTC`

The result was that the project ended up with an empty dataset called `analytics_315584957` in the wrong location (`US`), while the original historical GA4 export data was no longer accessible.

## Why The Old Dataset Could Not Be Restored

Two BigQuery constraints blocked in-place recovery:

1. Datasets cannot be renamed.
2. The undeleted empty dataset could not be deleted again because BigQuery applies a 7-day undelete cooldown.

Because the dataset ID `analytics_315584957` already existed in the old project, BigQuery would not allow the earlier deleted version to be restored over the top of it.

## Recovery Actions Taken

### 1. Search Console Dataset Health Check

The `searchconsole` dataset in `lifeline-website-480522` was checked and found to be structurally healthy.

Healthy tables included:

- `searchconsole.curated_search_site_daily`
- `searchconsole.curated_search_url_daily`
- `searchconsole.curated_search_query_page_daily`
- `searchconsole.seo_page_daily`

Structural checks passed:

- no duplicate `(report_date, page_path)` rows in `seo_page_daily`
- no null/blank `page_path`
- no null `report_date`

### 2. New GA4 Export Project Created

A new GA4 export destination was created and linked in GA4:

- project: `lifeline-web-analytics`
- dataset: `analytics_315584957`
- location: `australia-southeast1`

GA4 export is now active there.

Verified raw GA4 tables now include:

- `events_20260319`
- `events_intraday_20260320`
- `pseudonymous_users_20260319`

### 3. Repo Updated For Split-Project Operation

The repo was changed so GA4 and Search Console can come from different projects.

Updated files:

- [config.py](/home/aido/projects/lla-data/lla_data/config.py)
- [validate_seo_models.py](/home/aido/projects/lla-data/scripts/validate_seo_models.py)
- [ga4_curated_page_daily.sql](/home/aido/projects/lla-data/sql/ga4_curated_page_daily.sql)
- [ga4_curated_daily_traffic.sql](/home/aido/projects/lla-data/sql/ga4_curated_daily_traffic.sql)
- [seo_page_daily.sql](/home/aido/projects/lla-data/sql/seo_page_daily.sql)
- [seo_smoke_checks.sql](/home/aido/projects/lla-data/sql/seo_smoke_checks.sql)

Default split-project config is now:

- Search Console project: `lifeline-website-480522`
- GA4 project: `lifeline-web-analytics`

### 4. Core Models Rebuilt

The following models were rebuilt successfully:

- `lifeline-web-analytics.analytics_315584957.curated_ga4_page_daily`
- `lifeline-web-analytics.analytics_315584957.curated_daily_traffic`
- `lifeline-website-480522.searchconsole.seo_page_daily`

## Current Data State

As of the rebuild:

- `curated_ga4_page_daily` had resumed with data through `2026-03-19`
- Search Console curated tables were current through `2026-03-15`
- `searchconsole.seo_page_daily` was structurally healthy and included resumed GA4 data

Example smoke-check outputs at that point:

- `curated_ga4_page_daily`: `438` rows, max date `2026-03-19`
- `curated_search_site_daily`: max date `2026-03-15`
- `curated_search_url_daily`: max date `2026-03-15`
- `curated_search_query_page_daily`: max date `2026-03-15`
- `seo_page_daily`: max date `2026-03-17`
- null rates in `seo_page_daily`: `0`
- duplicate key rows in `seo_page_daily`: `0`

## Remaining Gap

Forward export is fixed, but historical GA4 BigQuery raw export data from the deleted dataset has not yet been restored into the new project.

That means:

- GA4 export is healthy going forward
- historical GA4 coverage in BigQuery is still incomplete
- analytical continuity depends on backfilling the lost raw export history

## New Backfill Lead: Azure / Datahub

Cassie advised that the historical GA4 web export is also stored in Datahub / Azure storage, including:

- `events_YYYYMMDD`
- `user_YYYYMMDD` / `pseudonymous_users_YYYYMMDD`
- coverage from `2025-12-08` onward

If that Azure copy is a near-raw copy of the BigQuery GA4 export tables, then the missing history can likely be restored into:

- `lifeline-web-analytics.analytics_315584957`

That would make the warehouse functionally whole again by:

1. backfilling historical raw GA4 tables into the new project
2. preserving current forward export in the new project
3. rebuilding curated GA4 tables
4. rebuilding `searchconsole.seo_page_daily`

## Next Recommended Steps

1. Confirm the Azure/Datahub copy format and schema.
2. Validate whether those files are raw-equivalent GA4 export tables or transformed derivatives.
3. Load missing historical daily tables into `lifeline-web-analytics.analytics_315584957`.
4. Avoid overwriting dates already arriving from the live GA4 export.
5. Rebuild:
   - `curated_ga4_page_daily`
   - `curated_daily_traffic`
   - `searchconsole.seo_page_daily`
6. Re-run smoke checks.

## Notes

- The original project `lifeline-website-480522` still contains an unusable `US` dataset called `analytics_315584957` created during the failed restore attempt.
- Without Google Cloud support, that original dataset ID could not be cleaned up immediately.
- The practical recovery path is now to treat `lifeline-web-analytics.analytics_315584957` as the GA4 source of truth and backfill history into it if the Azure copy proves usable.

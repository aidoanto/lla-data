# GA4 BigQuery Access and Guardrails

This guide helps you safely run traffic analysis on the GA4 export in project `lifeline-website-480522`.

## 1) What is already confirmed

- Project: `lifeline-website-480522`
- Dataset: `analytics_315584957`
- Tables present: `events_YYYYMMDD` and `pseudonymous_users_YYYYMMDD`
- Schema matches GA4 export shape (`event_name`, `event_params`, `user_pseudo_id`, `device`, `geo`, `traffic_source`, etc.)

## 2) Minimum IAM permissions you need

Ask your GCP admin for these roles at project level (or at least on this dataset):

- `roles/bigquery.jobUser` (run queries)
- `roles/bigquery.dataViewer` (read tables)

Optional but useful:

- `roles/bigquery.metadataViewer` (browse schema/metadata)
- `roles/bigquery.user` (create datasets/tables if needed)

## 3) Confirm your access in console (quick checks)

1. Open BigQuery in `lifeline-website-480522`.
2. Open table `analytics_315584957.events_20260216`.
3. Click **Preview** and confirm rows are visible.
4. Run a small query from `sql/ga4_starter_queries.sql`.

If these fail with `Access Denied`, share the exact error with your GCP admin.

## 4) Cost guardrails before querying

Use these defaults for safe exploration:

- Start with a tight date filter on `_TABLE_SUFFIX`.
- Always start with `LIMIT 100` while testing.
- Prefer aggregate queries (`COUNT`, `GROUP BY`) over raw event dumps.
- Use dry runs for cost estimates before running heavy queries.

### Dry-run pattern

In the BigQuery UI:

1. Paste your SQL.
2. Open query settings.
3. Enable dry run to estimate bytes scanned.

In Python API:

- Use `QueryJobConfig(dry_run=True, use_query_cache=False)`.

## 5) Simple bytes-control template

Use this suffix filter pattern in every starter query:

```sql
WHERE _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY))
  AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
```

## 6) Data handling reminders

- GA4 export is event-level raw data, not a reporting table.
- Avoid exporting personal data to local files unless approved by policy.
- Build curated summary tables for routine reporting and Databricks ingestion.

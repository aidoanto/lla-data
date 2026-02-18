# GA4 BigQuery to Databricks Integration Checklist

This checklist helps confirm how data currently flows and what to standardize.

## 1) Likely integration patterns

Common patterns between BigQuery and Databricks:

1. Databricks reads BigQuery tables directly (connector).
2. BigQuery writes files to Cloud Storage, then Databricks ingests files.
3. Scheduled queries build curated tables that Databricks pulls on a schedule.
4. A custom ETL job copies GA4 data into Delta tables.

## 2) What to verify in BigQuery

In BigQuery UI:

- `Scheduled queries`: check if `events_*` is transformed into curated tables.
- `Data transfers`: check if any transfer config exports data out.
- `Jobs explorer`: search jobs referencing `analytics_315584957`.
- Dataset/table access: identify service accounts used by automation.

Useful questions:

- Which table is the official source for Databricks (`events_*` vs curated)?
- Is ingestion incremental (daily) or full refresh?
- What is the SLA (run time, freshness, retry behavior)?

## 3) What to verify in Databricks

- Which job/notebook ingests BigQuery data?
- Which service principal is used?
- Where is the output stored (Delta table path/schema)?
- Is schema drift handled (new GA4 fields)?
- Is there data quality validation (row counts, null spikes, duplicate sessions)?

## 4) Recommended canonical contract

Use one canonical table from BigQuery:

- `lifeline-website-480522.analytics_315584957.curated_daily_traffic`

Suggested columns:

- `event_day` DATE
- `source` STRING
- `medium` STRING
- `events` INT64
- `page_views` INT64
- `users` INT64
- `sessions` INT64
- `unique_pages_viewed` INT64

Why this helps:

- Stable schema for Databricks jobs.
- Lower scan cost than raw `events_*`.
- Easier for non-technical stakeholders to consume.

## 5) Operational checks to add

- Daily reconciliation: yesterday's rows in BigQuery vs Databricks.
- Alert on late/missing partition.
- Alert on schema changes in GA4 export tables.
- Keep job run logs for audit and troubleshooting.

SELECT COUNT(*) AS table_count
FROM `{project_id}.{ga4_dataset}.INFORMATION_SCHEMA.TABLES`
WHERE table_name = 'curated_daily_traffic'

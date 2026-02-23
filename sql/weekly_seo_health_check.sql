-- Weekly health check for curated SEO model quality.
-- Suggested schedule: once per week (Monday morning, Sydney time).

SELECT
  CURRENT_DATE() AS run_date,
  MAX(report_date) AS latest_report_date,
  DATE_DIFF(CURRENT_DATE(), MAX(report_date), DAY) AS freshness_lag_days,
  COUNT(*) AS rows_last_35_days,
  COUNTIF(page_path IS NULL OR page_path = '') AS null_or_blank_page_path_rows,
  COUNTIF(gsc_impressions < 0 OR gsc_clicks < 0) AS negative_metric_rows
FROM `lifeline-website-480522.searchconsole.seo_page_daily`
WHERE report_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 35 DAY);


-- Smoke checks for first-run validation of curated SEO models.
-- Run sections individually in BigQuery UI, or run all for a quick health pass.

-- 1) Row counts + freshness for each curated table.
SELECT 'curated_search_site_daily' AS table_name, COUNT(*) AS row_count, MAX(report_date) AS max_date
FROM `lifeline-website-480522.searchconsole.curated_search_site_daily`
UNION ALL
SELECT 'curated_search_url_daily' AS table_name, COUNT(*) AS row_count, MAX(report_date) AS max_date
FROM `lifeline-website-480522.searchconsole.curated_search_url_daily`
UNION ALL
SELECT 'curated_search_query_page_daily' AS table_name, COUNT(*) AS row_count, MAX(report_date) AS max_date
FROM `lifeline-website-480522.searchconsole.curated_search_query_page_daily`
UNION ALL
SELECT 'curated_ga4_page_daily' AS table_name, COUNT(*) AS row_count, MAX(event_day) AS max_date
FROM `lifeline-website-480522.analytics_315584957.curated_ga4_page_daily`
UNION ALL
SELECT 'seo_page_daily' AS table_name, COUNT(*) AS row_count, MAX(report_date) AS max_date
FROM `lifeline-website-480522.searchconsole.seo_page_daily`;

-- 2) Null-rate checks on join keys in seo_page_daily.
SELECT
  SAFE_DIVIDE(COUNTIF(report_date IS NULL), COUNT(*)) AS null_report_date_rate,
  SAFE_DIVIDE(COUNTIF(page_path IS NULL OR page_path = ''), COUNT(*)) AS null_or_blank_page_path_rate
FROM `lifeline-website-480522.searchconsole.seo_page_daily`;

-- 3) Duplicate grain check: expected unique key is (report_date, page_path).
SELECT
  COUNT(*) AS duplicate_key_rows
FROM (
  SELECT report_date, page_path, COUNT(*) AS n
  FROM `lifeline-website-480522.searchconsole.seo_page_daily`
  GROUP BY report_date, page_path
  HAVING n > 1
);

-- 4) Recent-day sample for sanity.
SELECT
  report_date,
  page_path,
  gsc_clicks,
  gsc_impressions,
  total_sessions,
  organic_sessions,
  search_share
FROM `lifeline-website-480522.searchconsole.seo_page_daily`
WHERE report_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
ORDER BY report_date DESC, gsc_clicks DESC
LIMIT 100;


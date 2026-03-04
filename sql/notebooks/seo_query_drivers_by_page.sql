SELECT
  report_date,
  page_path,
  query,
  SUM(clicks) AS clicks,
  SUM(impressions) AS impressions,
  SAFE_DIVIDE(SUM(clicks), NULLIF(SUM(impressions), 0)) AS ctr,
  SAFE_DIVIDE(SUM(avg_position * impressions), NULLIF(SUM(impressions), 0)) AS avg_position
FROM `{project_id}.{searchconsole_dataset}.curated_search_query_page_daily`
WHERE report_date BETWEEN DATE(@start_date) AND DATE(@end_date)
  AND page_path = @page_path
GROUP BY report_date, page_path, query
ORDER BY report_date DESC, clicks DESC

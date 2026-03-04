SELECT
  page_path,
  SUM(gsc_clicks) AS clicks,
  SUM(gsc_impressions) AS impressions,
  SAFE_DIVIDE(SUM(gsc_clicks), NULLIF(SUM(gsc_impressions), 0)) AS ctr,
  SAFE_DIVIDE(SUM(gsc_avg_position * gsc_impressions), NULLIF(SUM(gsc_impressions), 0)) AS avg_position,
  SUM(organic_sessions) AS organic_sessions
FROM `{project_id}.{searchconsole_dataset}.seo_page_daily`
WHERE report_date BETWEEN DATE(@start_date) AND DATE(@end_date)
GROUP BY page_path
HAVING impressions > 0
ORDER BY clicks DESC
LIMIT @top_n

SELECT
  report_date,
  SUM(gsc_clicks) AS gsc_clicks,
  SUM(gsc_impressions) AS gsc_impressions,
  SUM(organic_sessions) AS organic_sessions,
  SUM(total_sessions) AS total_sessions,
  SAFE_DIVIDE(SUM(organic_sessions), NULLIF(SUM(total_sessions), 0)) AS search_share
FROM `{project_id}.{searchconsole_dataset}.seo_page_daily`
WHERE report_date BETWEEN DATE(@start_date) AND DATE(@end_date)
GROUP BY report_date
ORDER BY report_date

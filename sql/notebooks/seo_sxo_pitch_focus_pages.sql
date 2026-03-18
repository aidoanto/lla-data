WITH base AS (
  SELECT
    page_path,
    gsc_clicks,
    gsc_impressions,
    gsc_avg_position,
    organic_sessions,
    engaged_sessions
  FROM `{project_id}.{searchconsole_dataset}.seo_page_daily`
  WHERE report_date BETWEEN DATE(@start_date) AND DATE(@end_date)
    AND page_path IN UNNEST(@pages)
)
SELECT
  page_path,
  SUM(gsc_impressions) AS impressions,
  SUM(gsc_clicks) AS clicks,
  SAFE_DIVIDE(SUM(gsc_clicks), NULLIF(SUM(gsc_impressions), 0)) AS ctr,
  SAFE_DIVIDE(
    SUM(gsc_avg_position * gsc_impressions),
    NULLIF(SUM(gsc_impressions), 0)
  ) AS avg_position,
  SUM(organic_sessions) AS organic_sessions,
  SUM(engaged_sessions) AS engaged_sessions,
  SAFE_DIVIDE(SUM(engaged_sessions), NULLIF(SUM(organic_sessions), 0)) AS engagement_ratio
FROM base
GROUP BY page_path
ORDER BY impressions DESC

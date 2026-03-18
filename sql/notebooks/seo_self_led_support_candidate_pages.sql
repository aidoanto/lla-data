WITH base AS (
  SELECT
    report_date,
    page_path,
    gsc_clicks,
    gsc_impressions,
    gsc_avg_position,
    organic_sessions,
    engaged_sessions
  FROM `{project_id}.{searchconsole_dataset}.seo_page_daily`
  WHERE report_date BETWEEN DATE(@start_date) AND DATE(@end_date)
    AND EXISTS (
      SELECT 1
      FROM UNNEST(@page_prefixes) AS prefix
      WHERE STARTS_WITH(page_path, prefix)
    )
),
page_window AS (
  SELECT
    page_path,
    SUM(gsc_clicks) AS clicks,
    SUM(gsc_impressions) AS impressions,
    SAFE_DIVIDE(SUM(gsc_clicks), NULLIF(SUM(gsc_impressions), 0)) AS ctr,
    SAFE_DIVIDE(
      SUM(gsc_avg_position * gsc_impressions),
      NULLIF(SUM(gsc_impressions), 0)
    ) AS avg_position,
    SUM(organic_sessions) AS organic_sessions,
    SUM(engaged_sessions) AS engaged_sessions,
    SAFE_DIVIDE(SUM(engaged_sessions), NULLIF(SUM(organic_sessions), 0)) AS engagement_ratio,
    SAFE_DIVIDE(SUM(gsc_clicks), NULLIF(SUM(organic_sessions), 0)) AS click_to_session_ratio
  FROM base
  GROUP BY page_path
),
recent AS (
  SELECT
    page_path,
    SUM(gsc_clicks) AS recent_clicks,
    SUM(gsc_impressions) AS recent_impressions,
    SAFE_DIVIDE(SUM(gsc_clicks), NULLIF(SUM(gsc_impressions), 0)) AS recent_ctr,
    SAFE_DIVIDE(
      SUM(gsc_avg_position * gsc_impressions),
      NULLIF(SUM(gsc_impressions), 0)
    ) AS recent_avg_position
  FROM base
  WHERE report_date BETWEEN DATE_SUB(DATE(@end_date), INTERVAL 27 DAY) AND DATE(@end_date)
  GROUP BY page_path
),
prior AS (
  SELECT
    page_path,
    SUM(gsc_clicks) AS prior_clicks,
    SUM(gsc_impressions) AS prior_impressions,
    SAFE_DIVIDE(SUM(gsc_clicks), NULLIF(SUM(gsc_impressions), 0)) AS prior_ctr,
    SAFE_DIVIDE(
      SUM(gsc_avg_position * gsc_impressions),
      NULLIF(SUM(gsc_impressions), 0)
    ) AS prior_avg_position
  FROM base
  WHERE report_date BETWEEN DATE_SUB(DATE(@end_date), INTERVAL 55 DAY)
    AND DATE_SUB(DATE(@end_date), INTERVAL 28 DAY)
  GROUP BY page_path
)
SELECT
  p.page_path,
  p.clicks,
  p.impressions,
  p.ctr,
  p.avg_position,
  p.organic_sessions,
  p.engaged_sessions,
  p.engagement_ratio,
  p.click_to_session_ratio,
  r.recent_clicks,
  r.recent_impressions,
  r.recent_ctr,
  r.recent_avg_position,
  q.prior_clicks,
  q.prior_impressions,
  q.prior_ctr,
  q.prior_avg_position,
  COALESCE(r.recent_clicks, 0) - COALESCE(q.prior_clicks, 0) AS click_delta_28d,
  COALESCE(r.recent_impressions, 0) - COALESCE(q.prior_impressions, 0) AS impression_delta_28d,
  COALESCE(r.recent_ctr, 0) - COALESCE(q.prior_ctr, 0) AS ctr_delta_28d,
  COALESCE(r.recent_avg_position, 0) - COALESCE(q.prior_avg_position, 0) AS avg_position_delta_28d
FROM page_window AS p
LEFT JOIN recent AS r
  USING (page_path)
LEFT JOIN prior AS q
  USING (page_path)
WHERE p.impressions >= @min_impressions
ORDER BY p.impressions DESC, p.clicks DESC
LIMIT @top_n

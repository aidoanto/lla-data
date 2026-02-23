-- Joined SEO page-level daily model (Search Console + GA4).
-- Sources:
--   lifeline-website-480522.searchconsole.curated_search_url_daily
--   lifeline-website-480522.analytics_315584957.curated_ga4_page_daily
-- Destination:
--   lifeline-website-480522.searchconsole.seo_page_daily

CREATE OR REPLACE TABLE `lifeline-website-480522.searchconsole.seo_page_daily`
PARTITION BY report_date
AS
WITH gsc AS (
  SELECT
    report_date,
    page_path,
    SUM(clicks) AS gsc_clicks,
    SUM(impressions) AS gsc_impressions,
    SAFE_DIVIDE(SUM(clicks), SUM(impressions)) AS gsc_ctr,
    SAFE_DIVIDE(SUM(avg_position * impressions), NULLIF(SUM(impressions), 0)) AS gsc_avg_position
  FROM `lifeline-website-480522.searchconsole.curated_search_url_daily`
  WHERE search_type = 'WEB'
  GROUP BY report_date, page_path
),
ga4 AS (
  SELECT
    event_day AS report_date,
    page_path,
    SUM(total_sessions) AS total_sessions,
    SUM(organic_sessions) AS organic_sessions,
    SUM(users) AS users,
    SUM(page_views) AS page_views,
    SUM(engaged_sessions) AS engaged_sessions
  FROM `lifeline-website-480522.analytics_315584957.curated_ga4_page_daily`
  GROUP BY report_date, page_path
),
joined AS (
  SELECT
    COALESCE(gsc.report_date, ga4.report_date) AS report_date,
    COALESCE(gsc.page_path, ga4.page_path) AS page_path,
    gsc.gsc_clicks,
    gsc.gsc_impressions,
    gsc.gsc_ctr,
    gsc.gsc_avg_position,
    ga4.total_sessions,
    ga4.organic_sessions,
    ga4.users,
    ga4.page_views,
    ga4.engaged_sessions
  FROM gsc
  FULL OUTER JOIN ga4
    ON gsc.report_date = ga4.report_date
   AND gsc.page_path = ga4.page_path
)
SELECT
  report_date,
  page_path,
  COALESCE(gsc_clicks, 0) AS gsc_clicks,
  COALESCE(gsc_impressions, 0) AS gsc_impressions,
  gsc_ctr,
  gsc_avg_position,
  COALESCE(total_sessions, 0) AS total_sessions,
  COALESCE(organic_sessions, 0) AS organic_sessions,
  COALESCE(users, 0) AS users,
  COALESCE(page_views, 0) AS page_views,
  COALESCE(engaged_sessions, 0) AS engaged_sessions,
  SAFE_DIVIDE(COALESCE(organic_sessions, 0), NULLIF(COALESCE(total_sessions, 0), 0)) AS search_share,
  SAFE_DIVIDE(COALESCE(gsc_clicks, 0), NULLIF(COALESCE(organic_sessions, 0), 0)) AS click_to_session_ratio,
  CASE
    WHEN COALESCE(gsc_impressions, 0) < 20 THEN 'low-data'
    WHEN SAFE_DIVIDE(COALESCE(gsc_clicks, 0), NULLIF(COALESCE(gsc_impressions, 0), 0)) < 0.02 THEN 'very-low-ctr'
    WHEN SAFE_DIVIDE(COALESCE(gsc_clicks, 0), NULLIF(COALESCE(gsc_impressions, 0), 0)) < 0.05 THEN 'low-ctr'
    WHEN SAFE_DIVIDE(COALESCE(gsc_clicks, 0), NULLIF(COALESCE(gsc_impressions, 0), 0)) < 0.10 THEN 'mid-ctr'
    ELSE 'high-ctr'
  END AS impression_to_click_band
FROM joined;


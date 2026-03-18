WITH selected_pages AS (
  SELECT
    page_path,
    page_order
  FROM UNNEST(@selected_page_paths) AS page_path WITH OFFSET AS page_order
  WHERE TRIM(page_path) != ''
),
weekly_spine AS (
  SELECT week_start
  FROM UNNEST(
    GENERATE_DATE_ARRAY(
      DATE_TRUNC(DATE(@start_date), WEEK(MONDAY)),
      DATE_TRUNC(DATE(@end_date), WEEK(MONDAY)),
      INTERVAL 7 DAY
    )
  ) AS week_start
),
weekly_metrics AS (
  SELECT
    DATE_TRUNC(report_date, WEEK(MONDAY)) AS week_start,
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
    SUM(page_views) AS page_views
  FROM `{project_id}.{searchconsole_dataset}.seo_page_daily`
  WHERE report_date BETWEEN DATE(@start_date) AND DATE(@end_date)
    AND page_path IN (SELECT page_path FROM selected_pages)
  GROUP BY week_start, page_path
)
SELECT
  w.week_start,
  p.page_path,
  p.page_order,
  COALESCE(m.clicks, 0) AS clicks,
  COALESCE(m.impressions, 0) AS impressions,
  COALESCE(m.ctr, 0.0) AS ctr,
  m.avg_position AS avg_position,
  COALESCE(m.organic_sessions, 0) AS organic_sessions,
  COALESCE(m.engaged_sessions, 0) AS engaged_sessions,
  COALESCE(m.page_views, 0) AS page_views
FROM selected_pages AS p
CROSS JOIN weekly_spine AS w
LEFT JOIN weekly_metrics AS m
  ON m.page_path = p.page_path
  AND m.week_start = w.week_start
ORDER BY p.page_order, w.week_start

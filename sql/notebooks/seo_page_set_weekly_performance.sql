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
    SUM(engaged_sessions) AS engaged_sessions
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
  COALESCE(m.engaged_sessions, 0) AS engaged_sessions
FROM selected_pages AS p
CROSS JOIN weekly_spine AS w
LEFT JOIN weekly_metrics AS m
  ON m.page_path = p.page_path
  AND m.week_start = w.week_start
ORDER BY p.page_order, w.week_start

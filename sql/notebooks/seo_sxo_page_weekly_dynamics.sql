WITH base AS (
  SELECT
    report_date,
    page_path,
    gsc_clicks,
    gsc_impressions,
    gsc_avg_position
  FROM `{project_id}.{searchconsole_dataset}.seo_page_daily`
  WHERE report_date BETWEEN DATE(@start_date) AND DATE(@end_date)
    AND (@include_homepage OR page_path != "/")
),
top_pages AS (
  SELECT
    page_path,
    SUM(gsc_clicks) AS window_clicks,
    SUM(gsc_impressions) AS window_impressions
  FROM base
  GROUP BY page_path
  HAVING window_impressions >= @min_impressions_weekly
  ORDER BY window_clicks DESC
  LIMIT @top_n_pages
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
    b.page_path,
    SUM(gsc_clicks) AS clicks,
    SUM(gsc_impressions) AS impressions,
    SAFE_DIVIDE(SUM(gsc_clicks), NULLIF(SUM(gsc_impressions), 0)) AS ctr,
    SAFE_DIVIDE(
      SUM(gsc_avg_position * gsc_impressions),
      NULLIF(SUM(gsc_impressions), 0)
    ) AS avg_position
  FROM base AS b
  JOIN top_pages AS p
    ON b.page_path = p.page_path
  GROUP BY week_start, b.page_path
)
SELECT
  w.week_start,
  p.page_path,
  COALESCE(m.clicks, 0) AS clicks,
  COALESCE(m.impressions, 0) AS impressions,
  COALESCE(m.ctr, 0) AS ctr,
  m.avg_position AS avg_position
FROM top_pages AS p
CROSS JOIN weekly_spine AS w
LEFT JOIN weekly_metrics AS m
  ON m.page_path = p.page_path
  AND m.week_start = w.week_start
ORDER BY w.week_start, p.page_path

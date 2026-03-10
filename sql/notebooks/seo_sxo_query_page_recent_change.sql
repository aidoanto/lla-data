WITH bounds AS (
  SELECT
    DATE(@end_date) AS end_date,
    DATE_SUB(DATE(@end_date), INTERVAL (@recent_days - 1) DAY) AS recent_start,
    DATE_SUB(DATE(@end_date), INTERVAL @recent_days DAY) AS prior_end,
    DATE_SUB(DATE(@end_date), INTERVAL ((2 * @recent_days) - 1) DAY) AS prior_start
),
base AS (
  SELECT
    q.report_date,
    q.page_path,
    q.query,
    q.clicks,
    q.impressions,
    q.avg_position
  FROM `{project_id}.{searchconsole_dataset}.curated_search_query_page_daily` AS q
  CROSS JOIN bounds AS b
  WHERE q.report_date BETWEEN DATE(@start_date) AND b.end_date
    AND q.query IS NOT NULL
    AND TRIM(q.query) != ""
    AND (
      ARRAY_LENGTH(@excluded_page_paths) = 0
      OR q.page_path NOT IN UNNEST(@excluded_page_paths)
    )
),
top_pages AS (
  SELECT
    page_path,
    SUM(clicks) AS window_clicks
  FROM base
  GROUP BY page_path
  ORDER BY window_clicks DESC
  LIMIT @top_n_pages
),
base_top AS (
  SELECT
    b.*
  FROM base AS b
  JOIN top_pages AS p
    ON b.page_path = p.page_path
),
recent AS (
  SELECT
    b.page_path,
    b.query,
    SUM(b.clicks) AS recent_clicks,
    SUM(b.impressions) AS recent_impressions,
    SAFE_DIVIDE(
      SUM(b.avg_position * b.impressions),
      NULLIF(SUM(b.impressions), 0)
    ) AS recent_avg_position
  FROM base_top AS b
  CROSS JOIN bounds AS d
  WHERE b.report_date BETWEEN d.recent_start AND d.end_date
  GROUP BY b.page_path, b.query
),
prior AS (
  SELECT
    b.page_path,
    b.query,
    SUM(b.clicks) AS prior_clicks,
    SUM(b.impressions) AS prior_impressions,
    SAFE_DIVIDE(
      SUM(b.avg_position * b.impressions),
      NULLIF(SUM(b.impressions), 0)
    ) AS prior_avg_position
  FROM base_top AS b
  CROSS JOIN bounds AS d
  WHERE b.report_date BETWEEN d.prior_start AND d.prior_end
  GROUP BY b.page_path, b.query
)
SELECT
  COALESCE(r.page_path, p.page_path) AS page_path,
  COALESCE(r.query, p.query) AS query,
  COALESCE(r.recent_clicks, 0) AS recent_clicks,
  COALESCE(r.recent_impressions, 0) AS recent_impressions,
  r.recent_avg_position AS recent_avg_position,
  COALESCE(p.prior_clicks, 0) AS prior_clicks,
  COALESCE(p.prior_impressions, 0) AS prior_impressions,
  p.prior_avg_position AS prior_avg_position,
  COALESCE(r.recent_clicks, 0) - COALESCE(p.prior_clicks, 0) AS click_delta,
  COALESCE(r.recent_impressions, 0) - COALESCE(p.prior_impressions, 0) AS impression_delta,
  (COALESCE(r.recent_avg_position, 0) - COALESCE(p.prior_avg_position, 0)) AS avg_position_delta,
  CASE
    WHEN p.query IS NULL THEN "new_query"
    WHEN r.query IS NULL THEN "lost_query"
    ELSE "continuing_query"
  END AS query_state
FROM recent AS r
FULL OUTER JOIN prior AS p
  ON r.page_path = p.page_path
  AND r.query = p.query
WHERE COALESCE(r.recent_impressions, 0) + COALESCE(p.prior_impressions, 0) >= @min_query_impressions
ORDER BY page_path, recent_clicks DESC, click_delta DESC

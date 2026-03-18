WITH base AS (
  SELECT
    report_date,
    page_path,
    query,
    clicks,
    impressions,
    avg_position
  FROM `{project_id}.{searchconsole_dataset}.curated_search_query_page_daily`
  WHERE report_date BETWEEN DATE(@start_date) AND DATE(@end_date)
    AND page_path IN UNNEST(@pages)
    AND query IS NOT NULL
    AND TRIM(query) != ""
),
recent AS (
  SELECT
    page_path,
    query,
    SUM(clicks) AS recent_clicks,
    SUM(impressions) AS recent_impressions,
    SAFE_DIVIDE(SUM(clicks), NULLIF(SUM(impressions), 0)) AS recent_ctr,
    SAFE_DIVIDE(SUM(avg_position * impressions), NULLIF(SUM(impressions), 0)) AS recent_avg_position
  FROM base
  WHERE report_date BETWEEN DATE_SUB(DATE(@end_date), INTERVAL 27 DAY) AND DATE(@end_date)
  GROUP BY page_path, query
),
prior AS (
  SELECT
    page_path,
    query,
    SUM(clicks) AS prior_clicks,
    SUM(impressions) AS prior_impressions,
    SAFE_DIVIDE(SUM(clicks), NULLIF(SUM(impressions), 0)) AS prior_ctr,
    SAFE_DIVIDE(SUM(avg_position * impressions), NULLIF(SUM(impressions), 0)) AS prior_avg_position
  FROM base
  WHERE report_date BETWEEN DATE_SUB(DATE(@end_date), INTERVAL 55 DAY)
    AND DATE_SUB(DATE(@end_date), INTERVAL 28 DAY)
  GROUP BY page_path, query
),
combined AS (
  SELECT
    COALESCE(r.page_path, p.page_path) AS page_path,
    COALESCE(r.query, p.query) AS query,
    COALESCE(r.recent_clicks, 0) AS recent_clicks,
    COALESCE(r.recent_impressions, 0) AS recent_impressions,
    r.recent_ctr,
    r.recent_avg_position,
    COALESCE(p.prior_clicks, 0) AS prior_clicks,
    COALESCE(p.prior_impressions, 0) AS prior_impressions,
    p.prior_ctr,
    p.prior_avg_position,
    COALESCE(r.recent_clicks, 0) + COALESCE(p.prior_clicks, 0) AS clicks_56d,
    COALESCE(r.recent_impressions, 0) + COALESCE(p.prior_impressions, 0) AS impressions_56d,
    COALESCE(r.recent_clicks, 0) - COALESCE(p.prior_clicks, 0) AS click_delta_28d,
    COALESCE(r.recent_impressions, 0) - COALESCE(p.prior_impressions, 0) AS impression_delta_28d,
    COALESCE(r.recent_avg_position, 0) - COALESCE(p.prior_avg_position, 0) AS avg_position_delta_28d
  FROM recent AS r
  FULL OUTER JOIN prior AS p
    USING (page_path, query)
)
SELECT
  page_path,
  query,
  recent_clicks,
  recent_impressions,
  recent_ctr,
  recent_avg_position,
  prior_clicks,
  prior_impressions,
  prior_ctr,
  prior_avg_position,
  clicks_56d,
  impressions_56d,
  click_delta_28d,
  impression_delta_28d,
  avg_position_delta_28d
FROM combined
WHERE impressions_56d >= @min_query_impressions
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY page_path
  ORDER BY impressions_56d DESC, clicks_56d DESC
) <= @top_n_queries
ORDER BY page_path, impressions_56d DESC, clicks_56d DESC

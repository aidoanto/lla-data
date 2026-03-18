WITH focus_queries AS (
  SELECT
    '/get-help/support-toolkit/techniques-and-guides/self-care-for-mental-health-and-wellbeing/' AS page_path,
    'Self-care ideas cluster' AS query_cluster,
    r'(^|\\W)self[ -]?care( ideas?)?(\\W|$)' AS query_pattern
  UNION ALL
  SELECT
    '/get-help/support-toolkit/techniques-and-guides/finding-the-right-therapist/' AS page_path,
    'Therapist choice cluster' AS query_cluster,
    r'(^|\\W)(how to choose a therapist|choose a therapist|find(ing)? the right therapist|find a therapist)(\\W|$)' AS query_pattern
  UNION ALL
  SELECT
    '/get-help/support-toolkit/techniques-and-guides/finding-relief-through-grounding-techniques/' AS page_path,
    'Grounding techniques cluster' AS query_cluster,
    r'(^|\\W)grounding( techniques| exercises)?(\\W|$)' AS query_pattern
),
base AS (
  SELECT
    q.page_path,
    q.query_cluster,
    c.query,
    c.clicks,
    c.impressions,
    c.avg_position
  FROM `{project_id}.{searchconsole_dataset}.curated_search_query_page_daily` AS c
  JOIN focus_queries AS q
    ON c.page_path = q.page_path
  WHERE c.report_date BETWEEN DATE(@start_date) AND DATE(@end_date)
    AND c.query IS NOT NULL
    AND TRIM(c.query) != ''
    AND REGEXP_CONTAINS(LOWER(c.query), q.query_pattern)
)
SELECT
  page_path,
  query_cluster,
  SUM(impressions) AS impressions,
  SUM(clicks) AS clicks,
  SAFE_DIVIDE(SUM(clicks), NULLIF(SUM(impressions), 0)) AS ctr,
  SAFE_DIVIDE(SUM(avg_position * impressions), NULLIF(SUM(impressions), 0)) AS avg_position
FROM base
GROUP BY page_path, query_cluster
ORDER BY impressions DESC

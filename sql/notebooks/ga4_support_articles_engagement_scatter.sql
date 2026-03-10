WITH base AS (
  SELECT
    PARSE_DATE('%Y%m%d', event_date) AS report_date,
    event_name,
    user_pseudo_id,
    CONCAT(
      user_pseudo_id,
      '.',
      COALESCE(
        CAST((
          SELECT ep.value.int_value
          FROM UNNEST(event_params) ep
          WHERE ep.key = 'ga_session_id'
        ) AS STRING),
        '0'
      )
    ) AS session_key,
    COALESCE((
      SELECT ep.value.string_value
      FROM UNNEST(event_params) ep
      WHERE ep.key = 'page_location'
    ), '(unknown)') AS page_location,
    COALESCE((
      SELECT ep.value.string_value
      FROM UNNEST(event_params) ep
      WHERE ep.key = 'medium'
    ), '(none)') AS medium,
    COALESCE((
      SELECT ep.value.string_value
      FROM UNNEST(event_params) ep
      WHERE ep.key = 'session_engaged'
    ), '0') AS session_engaged,
    COALESCE((
      SELECT ep.value.int_value
      FROM UNNEST(event_params) ep
      WHERE ep.key = 'engagement_time_msec'
    ), 0) AS engagement_time_msec,
    COALESCE(geo.country, '(unknown)') AS country
  FROM `{project_id}.{ga4_dataset}.events_*`
  WHERE _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE(@start_date))
    AND FORMAT_DATE('%Y%m%d', DATE(@end_date))
    AND (NOT @australia_only OR LOWER(COALESCE(geo.country, '')) = LOWER(@country_name))
),
normalized AS (
  SELECT
    report_date,
    event_name,
    user_pseudo_id,
    session_key,
    medium,
    session_engaged,
    engagement_time_msec,
    country,
    CASE
      WHEN page_location = '(unknown)' THEN '(unknown)'
      WHEN REGEXP_CONTAINS(page_location, r'^https?://') THEN
        COALESCE(NULLIF(REGEXP_EXTRACT(page_location, r'^https?://[^/]+(/.*)$'), ''), '/')
      WHEN STARTS_WITH(page_location, '/') THEN page_location
      ELSE CONCAT('/', page_location)
    END AS page_path_raw
  FROM base
),
cleaned AS (
  SELECT
    report_date,
    event_name,
    user_pseudo_id,
    session_key,
    medium,
    session_engaged,
    engagement_time_msec,
    country,
    CASE
      WHEN page_path_raw = '(unknown)' THEN '(unknown)'
      ELSE REGEXP_REPLACE(REGEXP_REPLACE(page_path_raw, r'#.*$', ''), r'\?.*$', '')
    END AS page_path_no_query
  FROM normalized
),
support_articles AS (
  SELECT
    report_date,
    event_name,
    user_pseudo_id,
    session_key,
    medium,
    session_engaged,
    engagement_time_msec,
    country,
    CASE
      WHEN page_path_no_query IN ('', '/') THEN '/'
      WHEN page_path_no_query = '(unknown)' THEN '(unknown)'
      ELSE REGEXP_REPLACE(page_path_no_query, r'/$', '')
    END AS page_path
  FROM cleaned
  WHERE
    STARTS_WITH(page_path_no_query, '/get-help/support-toolkit')
    OR STARTS_WITH(page_path_no_query, '/get-help/national-services')
    OR STARTS_WITH(page_path_no_query, '/get-help/hear-from-others')
),
page_metrics AS (
  SELECT
    page_path,
    COUNT(*) AS events,
    COUNTIF(event_name = 'page_view') AS page_views,
    COUNT(DISTINCT user_pseudo_id) AS users,
    COUNT(DISTINCT IF(event_name = 'session_start', session_key, NULL)) AS total_sessions,
    COUNT(DISTINCT IF(event_name = 'session_start' AND LOWER(medium) = 'organic', session_key, NULL)) AS organic_sessions,
    COUNT(DISTINCT IF(event_name = 'page_view' AND session_engaged = '1', session_key, NULL)) AS engaged_sessions,
    SAFE_DIVIDE(SUM(engagement_time_msec), 1000.0) AS total_engagement_time_seconds
  FROM support_articles
  GROUP BY page_path
)
SELECT
  page_path,
  events,
  page_views,
  users,
  total_sessions,
  organic_sessions,
  engaged_sessions,
  total_engagement_time_seconds,
  SAFE_DIVIDE(total_engagement_time_seconds, NULLIF(engaged_sessions, 0)) AS avg_engagement_time_seconds
FROM page_metrics
ORDER BY organic_sessions DESC, engaged_sessions DESC, page_path;

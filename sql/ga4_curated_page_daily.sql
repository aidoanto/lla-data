-- Curated GA4 page-level daily traffic metrics.
-- Source table: lifeline-website-480522.analytics_315584957.events_*
-- Destination table: lifeline-website-480522.analytics_315584957.curated_ga4_page_daily

CREATE OR REPLACE TABLE `lifeline-website-480522.analytics_315584957.curated_ga4_page_daily`
PARTITION BY event_day
AS
WITH base AS (
  SELECT
    PARSE_DATE('%Y%m%d', event_date) AS event_day,
    event_name,
    user_pseudo_id,
    CONCAT(
      user_pseudo_id,
      '.',
      COALESCE(
        CAST((SELECT ep.value.int_value FROM UNNEST(event_params) ep WHERE ep.key = 'ga_session_id') AS STRING),
        '0'
      )
    ) AS session_key,
    COALESCE((SELECT ep.value.string_value FROM UNNEST(event_params) ep WHERE ep.key = 'page_location'), '(unknown)') AS page_location,
    COALESCE((SELECT ep.value.string_value FROM UNNEST(event_params) ep WHERE ep.key = 'source'), '(direct)') AS source,
    COALESCE((SELECT ep.value.string_value FROM UNNEST(event_params) ep WHERE ep.key = 'medium'), '(none)') AS medium,
    COALESCE((SELECT ep.value.string_value FROM UNNEST(event_params) ep WHERE ep.key = 'session_engaged'), '0') AS session_engaged
  FROM `lifeline-website-480522.analytics_315584957.events_*`
  WHERE _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY))
    AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
),
normalized AS (
  SELECT
    event_day,
    event_name,
    user_pseudo_id,
    session_key,
    source,
    medium,
    session_engaged,
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
    event_day,
    event_name,
    user_pseudo_id,
    session_key,
    source,
    medium,
    session_engaged,
    CASE
      WHEN page_path_raw = '(unknown)' THEN '(unknown)'
      ELSE REGEXP_REPLACE(REGEXP_REPLACE(page_path_raw, r'#.*$', ''), r'\?.*$', '')
    END AS page_path_no_query
  FROM normalized
)
SELECT
  event_day,
  CASE
    WHEN page_path_no_query IN ('', '/') THEN '/'
    WHEN page_path_no_query = '(unknown)' THEN '(unknown)'
    ELSE REGEXP_REPLACE(page_path_no_query, r'/$', '')
  END AS page_path,
  COUNT(*) AS events,
  COUNTIF(event_name = 'page_view') AS page_views,
  COUNT(DISTINCT user_pseudo_id) AS users,
  COUNT(DISTINCT IF(event_name = 'session_start', session_key, NULL)) AS total_sessions,
  COUNT(DISTINCT IF(event_name = 'session_start' AND LOWER(medium) = 'organic', session_key, NULL)) AS organic_sessions,
  COUNT(DISTINCT IF(event_name = 'page_view' AND session_engaged = '1', session_key, NULL)) AS engaged_sessions
FROM cleaned
GROUP BY event_day, page_path;


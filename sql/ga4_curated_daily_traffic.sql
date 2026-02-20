-- Curated traffic table for reporting and notebook analysis.
-- Run this as a scheduled query once per day.
-- Destination table:
--   lifeline-website-480522.analytics_315584957.curated_daily_traffic

CREATE OR REPLACE TABLE `lifeline-website-480522.analytics_315584957.curated_daily_traffic`
PARTITION BY event_day
AS
WITH base AS (
  SELECT
    PARSE_DATE('%Y%m%d', event_date) AS event_day,
    TIMESTAMP_MICROS(event_timestamp) AS event_ts,
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
      WHERE ep.key = 'source'
    ), '(direct)') AS source,
    COALESCE((
      SELECT ep.value.string_value
      FROM UNNEST(event_params) ep
      WHERE ep.key = 'medium'
    ), '(none)') AS medium
  FROM `lifeline-website-480522.analytics_315584957.events_*`
  WHERE _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 35 DAY))
    AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
),
cleaned AS (
  SELECT
    event_day,
    event_ts,
    FORMAT_DATE('%A', event_day) AS day_of_week,
    EXTRACT(HOUR FROM event_ts) AS hour_of_day,
    event_name,
    user_pseudo_id,
    session_key,
    source,
    medium,
    CASE
      WHEN page_location = '(unknown)' THEN '(unknown)'
      ELSE REGEXP_REPLACE(REGEXP_REPLACE(page_location, r'#.*$', ''), r'\?.*$', '')
    END AS page_location_clean
  FROM base
),
standardized AS (
  SELECT
    event_day,
    day_of_week,
    hour_of_day,
    event_name,
    user_pseudo_id,
    session_key,
    source,
    medium,
    CASE
      WHEN page_location_clean = '(unknown)' THEN '(unknown)'
      WHEN REGEXP_CONTAINS(page_location_clean, r'^https?://') THEN
        COALESCE(NULLIF(REGEXP_EXTRACT(page_location_clean, r'^https?://[^/]+(/.*)$'), ''), '/')
      WHEN STARTS_WITH(page_location_clean, '/') THEN page_location_clean
      ELSE CONCAT('/', page_location_clean)
    END AS page_path_raw
  FROM cleaned
),
categorized AS (
  SELECT
    event_day,
    day_of_week,
    hour_of_day,
    event_name,
    user_pseudo_id,
    session_key,
    source,
    medium,
    CASE
      WHEN page_path_raw IN ('(unknown)', '/') THEN page_path_raw
      ELSE REGEXP_REPLACE(page_path_raw, r'/$', '')
    END AS page_path,
    CASE
      WHEN page_path_raw = '/' THEN 'homepage'
      WHEN page_path_raw = '(unknown)' THEN '(unknown)'
      WHEN REGEXP_CONTAINS(page_path_raw, r'^/(get-help|crisis-support|suicide|131114|chat|text)') THEN 'crisis-support'
      WHEN REGEXP_CONTAINS(page_path_raw, r'^/(mental-health|resources|toolkit|articles|podcast)') THEN 'resources'
      WHEN REGEXP_CONTAINS(page_path_raw, r'^/(donate|fundraise|appeal|bequest|workplace-giving)') THEN 'donate'
      WHEN REGEXP_CONTAINS(page_path_raw, r'^/(about|our-story|careers|media|contact|locations|privacy|terms)') THEN 'about'
      ELSE 'other'
    END AS page_category
  FROM standardized
)
SELECT
  event_day,
  day_of_week,
  hour_of_day,
  source,
  medium,
  page_category,
  COUNT(*) AS events,
  COUNTIF(event_name = 'page_view') AS page_views,
  COUNT(DISTINCT user_pseudo_id) AS users,
  COUNT(DISTINCT session_key) AS sessions,
  COUNT(DISTINCT IF(event_name = 'page_view', page_path, NULL)) AS unique_pages_viewed
FROM categorized
GROUP BY event_day, day_of_week, hour_of_day, source, medium, page_category
ORDER BY event_day DESC, events DESC;

-- Curated daily traffic table for Databricks and reporting.
-- Run this as a scheduled query once per day.
-- Destination table:
--   lifeline-website-480522.analytics_315584957.curated_daily_traffic

CREATE OR REPLACE TABLE `lifeline-website-480522.analytics_315584957.curated_daily_traffic`
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
      COALESCE(CAST((
        SELECT ep.value.int_value
        FROM UNNEST(event_params) ep
        WHERE ep.key = 'ga_session_id'
      ) AS STRING), '0')
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
)
SELECT
  event_day,
  source,
  medium,
  COUNT(*) AS events,
  COUNTIF(event_name = 'page_view') AS page_views,
  COUNT(DISTINCT user_pseudo_id) AS users,
  COUNT(DISTINCT session_key) AS sessions,
  COUNT(DISTINCT IF(event_name = 'page_view', page_location, NULL)) AS unique_pages_viewed
FROM base
GROUP BY event_day, source, medium
ORDER BY event_day DESC, events DESC;

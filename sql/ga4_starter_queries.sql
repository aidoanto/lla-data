-- GA4 starter queries for dataset analytics_315584957
-- Project: lifeline-website-480522
-- Notes:
-- 1) Start with short date ranges.
-- 2) Keep LIMIT during exploration.
-- 3) Replace date windows as needed.

-- Q1) Daily event volume (last 7 days)
SELECT
  PARSE_DATE('%Y%m%d', event_date) AS event_day,
  COUNT(*) AS event_count
FROM `lifeline-website-480522.analytics_315584957.events_*`
WHERE _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY))
  AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
GROUP BY event_day
ORDER BY event_day DESC;

-- Q2) Top event names (last 7 days)
SELECT
  event_name,
  COUNT(*) AS events
FROM `lifeline-website-480522.analytics_315584957.events_*`
WHERE _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY))
  AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
GROUP BY event_name
ORDER BY events DESC
LIMIT 25;

-- Q3) Top pages by page_view (last 7 days)
SELECT
  COALESCE((
    SELECT ep.value.string_value
    FROM UNNEST(event_params) ep
    WHERE ep.key = 'page_location'
  ), '(unknown)') AS page_location,
  COUNT(*) AS page_views
FROM `lifeline-website-480522.analytics_315584957.events_*`
WHERE event_name = 'page_view'
  AND _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY))
  AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
GROUP BY page_location
ORDER BY page_views DESC
LIMIT 50;

-- Q4) Sessions by source / medium (last 7 days)
-- Uses GA4 session_start events and session params.
SELECT
  COALESCE((
    SELECT ep.value.string_value
    FROM UNNEST(event_params) ep
    WHERE ep.key = 'source'
  ), '(direct)') AS source,
  COALESCE((
    SELECT ep.value.string_value
    FROM UNNEST(event_params) ep
    WHERE ep.key = 'medium'
  ), '(none)') AS medium,
  COUNT(*) AS session_starts
FROM `lifeline-website-480522.analytics_315584957.events_*`
WHERE event_name = 'session_start'
  AND _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY))
  AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
GROUP BY source, medium
ORDER BY session_starts DESC
LIMIT 50;

-- Q5) Daily active users (approximation from user_pseudo_id)
SELECT
  PARSE_DATE('%Y%m%d', event_date) AS event_day,
  COUNT(DISTINCT user_pseudo_id) AS active_users
FROM `lifeline-website-480522.analytics_315584957.events_*`
WHERE _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY))
  AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
GROUP BY event_day
ORDER BY event_day DESC;

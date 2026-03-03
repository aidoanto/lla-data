WITH page_views AS (
  SELECT
    PARSE_DATE('%Y%m%d', event_date) AS event_day,
    EXTRACT(HOUR FROM TIMESTAMP_MICROS(event_timestamp)) AS hour_of_day,
    EXTRACT(DAYOFWEEK FROM PARSE_DATE('%Y%m%d', event_date)) AS day_of_week_num,
    FORMAT_DATE('%A', PARSE_DATE('%Y%m%d', event_date)) AS day_of_week,
    CASE
      WHEN page_location = '(unknown)' THEN '(unknown)'
      WHEN REGEXP_CONTAINS(page_location, r'^https?://') THEN COALESCE(NULLIF(REGEXP_EXTRACT(page_location, r'^https?://[^/]+(/.*)$'), ''), '/')
      WHEN STARTS_WITH(page_location, '/') THEN page_location
      ELSE CONCAT('/', page_location)
    END AS page_path
  FROM (
    SELECT
      event_date,
      event_timestamp,
      COALESCE((
        SELECT ep.value.string_value
        FROM UNNEST(event_params) ep
        WHERE ep.key = 'page_location'
      ), '(unknown)') AS page_location
    FROM `{project_id}.{ga4_dataset}.events_*`
    WHERE event_name = 'page_view'
      AND _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL {days_back} DAY))
      AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
  )
), cleaned AS (
  SELECT
    event_day,
    hour_of_day,
    day_of_week_num,
    day_of_week,
    CASE
      WHEN page_path IN ('(unknown)', '/') THEN page_path
      ELSE REGEXP_REPLACE(REGEXP_REPLACE(page_path, r'#.*$', ''), r'\?.*$', '')
    END AS page_path_clean
  FROM page_views
), crisis AS (
  SELECT *
  FROM cleaned
  WHERE REGEXP_CONTAINS(page_path_clean, r'{crisis_path_regex}')
)
SELECT
  day_of_week_num,
  day_of_week,
  hour_of_day,
  COUNT(*) AS crisis_page_views
FROM crisis
GROUP BY day_of_week_num, day_of_week, hour_of_day
ORDER BY day_of_week_num, hour_of_day

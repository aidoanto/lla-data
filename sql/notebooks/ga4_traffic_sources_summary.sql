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
      WHERE ep.key = 'source'
    ), '(direct)') AS source,
    COALESCE((
      SELECT ep.value.string_value
      FROM UNNEST(event_params) ep
      WHERE ep.key = 'medium'
    ), '(none)') AS medium,
    COALESCE((
      SELECT ep.value.string_value
      FROM UNNEST(event_params) ep
      WHERE ep.key = 'session_engaged'
    ), '0') AS session_engaged
  FROM `{project_id}.{ga4_dataset}.events_*`
  WHERE _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE(@start_date))
    AND FORMAT_DATE('%Y%m%d', DATE(@end_date))
), session_level AS (
  SELECT
    source,
    medium,
    session_key,
    MAX(CAST(session_engaged AS INT64)) AS engaged_flag,
    COUNTIF(event_name = 'page_view') AS page_views_in_session
  FROM base
  GROUP BY source, medium, session_key
)
SELECT
  source,
  medium,
  COUNT(*) AS sessions,
  SUM(engaged_flag) AS engaged_sessions,
  SAFE_DIVIDE(SUM(engaged_flag), COUNT(*)) AS engagement_rate,
  AVG(page_views_in_session) AS avg_pages_per_session
FROM session_level
GROUP BY source, medium
HAVING sessions >= @minimum_sessions
ORDER BY sessions DESC

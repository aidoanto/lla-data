WITH base AS (
  SELECT
    PARSE_DATE('%Y%m%d', event_date) AS report_date,
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
    LOWER(COALESCE((
      SELECT ep.value.string_value
      FROM UNNEST(event_params) ep
      WHERE ep.key = 'source'
    ), '(direct)')) AS source,
    LOWER(COALESCE((
      SELECT ep.value.string_value
      FROM UNNEST(event_params) ep
      WHERE ep.key = 'medium'
    ), '(none)')) AS medium,
    event_name
  FROM `{project_id}.{ga4_dataset}.events_*`
  WHERE _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE(@start_date))
    AND FORMAT_DATE('%Y%m%d', DATE(@end_date))
),
session_level AS (
  SELECT
    report_date,
    source,
    medium,
    COUNT(DISTINCT IF(event_name = 'session_start', session_key, NULL)) AS sessions
  FROM base
  GROUP BY report_date, source, medium
),
filtered AS (
  SELECT
    report_date,
    source,
    medium,
    sessions
  FROM session_level
  WHERE medium != 'organic'
    AND sessions > 0
),
bucketed AS (
  SELECT
    report_date,
    source,
    medium,
    sessions,
    CASE
      WHEN source = '(direct)' OR medium = '(none)' THEN 'Direct (no identifiable referrer/campaign)'
      WHEN REGEXP_CONTAINS(medium, r'(cpc|ppc|paid|display|programmatic|cpm|affiliate|retargeting|paid_social|social_ad)') THEN 'Paid Media (CPC/PPC/Display/Paid Social)'
      WHEN REGEXP_CONTAINS(medium, r'(social|social-network|social-media|social network|social media)')
        OR REGEXP_CONTAINS(source, r'(facebook|instagram|linkedin|tiktok|meta|youtube|x\.com|twitter)') THEN 'Organic Social'
      WHEN REGEXP_CONTAINS(medium, r'email') THEN 'Email'
      WHEN medium = 'referral' THEN 'Referral (links from other websites)'
      ELSE 'Other / Unclassified'
    END AS channel_bucket
  FROM filtered
)
SELECT
  report_date,
  source,
  medium,
  channel_bucket,
  sessions
FROM bucketed
ORDER BY report_date, sessions DESC

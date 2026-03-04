WITH base AS (
  SELECT
    event_day AS report_date,
    LOWER(COALESCE(source, '(direct)')) AS source,
    LOWER(COALESCE(medium, '(none)')) AS medium,
    SUM(sessions) AS sessions
  FROM `{project_id}.{ga4_dataset}.curated_daily_traffic`
  WHERE event_day BETWEEN DATE(@start_date) AND DATE(@end_date)
    AND LOWER(COALESCE(medium, '(none)')) != 'organic'
  GROUP BY report_date, source, medium
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
  FROM base
)
SELECT
  report_date,
  source,
  medium,
  channel_bucket,
  sessions
FROM bucketed
ORDER BY report_date, sessions DESC

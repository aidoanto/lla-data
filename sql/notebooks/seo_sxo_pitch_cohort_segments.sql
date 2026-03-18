WITH base AS (
  SELECT
    page_path,
    gsc_clicks,
    gsc_impressions,
    gsc_avg_position,
    organic_sessions,
    engaged_sessions
  FROM `{project_id}.{searchconsole_dataset}.seo_page_daily`
  WHERE report_date BETWEEN DATE(@start_date) AND DATE(@end_date)
    AND EXISTS (
      SELECT 1
      FROM UNNEST(@page_prefixes) AS prefix
      WHERE STARTS_WITH(page_path, prefix)
    )
),
segmented AS (
  SELECT
    CASE
      WHEN STARTS_WITH(page_path, '/get-help/support-toolkit/techniques-and-guides/')
        THEN 'Techniques and guides'
      WHEN STARTS_WITH(page_path, '/get-help/support-toolkit/topics/')
        THEN 'Topics'
      WHEN STARTS_WITH(page_path, '/get-help/support-toolkit/tools-and-apps/')
        THEN 'Tools and apps'
      WHEN STARTS_WITH(page_path, '/get-help/support-toolkit/safety-planning/')
        THEN 'Safety planning'
      WHEN STARTS_WITH(page_path, '/get-help/support-toolkit/community-perspectives/')
        THEN 'Community perspectives'
      WHEN STARTS_WITH(page_path, '/get-help/support-toolkit/fact-sheets/')
        THEN 'Fact sheets'
      WHEN STARTS_WITH(page_path, '/get-help/national-services/')
        THEN 'National services'
      WHEN STARTS_WITH(page_path, '/get-help/hear-from-others/')
        THEN 'Hear from others'
      ELSE 'Other self-led support'
    END AS content_segment,
    gsc_clicks,
    gsc_impressions,
    gsc_avg_position,
    organic_sessions,
    engaged_sessions
  FROM base
)
SELECT
  content_segment,
  SUM(gsc_impressions) AS impressions,
  SUM(gsc_clicks) AS clicks,
  SAFE_DIVIDE(SUM(gsc_clicks), NULLIF(SUM(gsc_impressions), 0)) AS ctr,
  SAFE_DIVIDE(
    SUM(gsc_avg_position * gsc_impressions),
    NULLIF(SUM(gsc_impressions), 0)
  ) AS avg_position,
  SUM(organic_sessions) AS organic_sessions,
  SUM(engaged_sessions) AS engaged_sessions
FROM segmented
GROUP BY content_segment
HAVING impressions > 0
ORDER BY impressions DESC

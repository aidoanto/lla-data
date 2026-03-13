WITH keyword_list AS (
  SELECT DISTINCT
    LOWER(TRIM(keyword)) AS keyword_normalized
  FROM UNNEST(@keywords) AS keyword
  WHERE keyword IS NOT NULL
    AND TRIM(keyword) != ""
),
site_matches AS (
  SELECT
    LOWER(TRIM(query)) AS keyword_normalized,
    page_path,
    SUM(clicks) AS clicks,
    SUM(impressions) AS impressions,
    SAFE_DIVIDE(SUM(avg_position * impressions), NULLIF(SUM(impressions), 0)) AS avg_position
  FROM `{project_id}.{searchconsole_dataset}.curated_search_query_page_daily`
  WHERE report_date BETWEEN DATE(@start_date) AND DATE(@end_date)
    AND query IS NOT NULL
    AND TRIM(query) != ""
  GROUP BY keyword_normalized, page_path
)
SELECT
  k.keyword_normalized,
  COALESCE(SUM(m.clicks), 0) AS site_clicks,
  COALESCE(SUM(m.impressions), 0) AS site_impressions,
  SAFE_DIVIDE(SUM(m.clicks), NULLIF(SUM(m.impressions), 0)) AS site_ctr,
  SAFE_DIVIDE(SUM(m.avg_position * m.impressions), NULLIF(SUM(m.impressions), 0)) AS site_avg_position,
  ARRAY_AGG(
    STRUCT(
      m.page_path AS page_path,
      m.clicks AS clicks,
      m.impressions AS impressions,
      m.avg_position AS avg_position
    )
    ORDER BY m.impressions DESC
    LIMIT 3
  ) AS top_pages
FROM keyword_list AS k
LEFT JOIN site_matches AS m
  ON k.keyword_normalized = m.keyword_normalized
GROUP BY k.keyword_normalized
ORDER BY site_impressions DESC, site_clicks DESC

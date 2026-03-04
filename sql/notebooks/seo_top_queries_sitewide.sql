SELECT
  query,
  SUM(clicks) AS clicks,
  SUM(impressions) AS impressions,
  SAFE_DIVIDE(SUM(clicks), NULLIF(SUM(impressions), 0)) AS ctr,
  SAFE_DIVIDE(SUM(avg_position * impressions), NULLIF(SUM(impressions), 0)) AS avg_position
FROM `{project_id}.{searchconsole_dataset}.curated_search_query_page_daily`
WHERE report_date BETWEEN DATE(@start_date) AND DATE(@end_date)
  AND query IS NOT NULL
  AND TRIM(query) != ""
GROUP BY query
HAVING impressions > 0
ORDER BY clicks DESC
LIMIT @top_n

-- Curated Search Console site-level daily metrics.
-- Source table: lifeline-website-480522.searchconsole.searchdata_site_impression
-- Destination table: lifeline-website-480522.searchconsole.curated_search_site_daily

CREATE OR REPLACE TABLE `lifeline-website-480522.searchconsole.curated_search_site_daily`
PARTITION BY report_date
AS
SELECT
  data_date AS report_date,
  site_url,
  search_type,
  country,
  device,
  SUM(clicks) AS clicks,
  SUM(impressions) AS impressions,
  SAFE_DIVIDE(SUM(clicks), SUM(impressions)) AS ctr,
  SAFE_DIVIDE(SUM(sum_top_position), SUM(impressions)) + 1 AS avg_position
FROM `lifeline-website-480522.searchconsole.searchdata_site_impression`
GROUP BY report_date, site_url, search_type, country, device;


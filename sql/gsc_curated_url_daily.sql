-- Curated Search Console URL-level daily metrics.
-- Source table: lifeline-website-480522.searchconsole.searchdata_url_impression
-- Destination table: lifeline-website-480522.searchconsole.curated_search_url_daily

CREATE OR REPLACE TABLE `lifeline-website-480522.searchconsole.curated_search_url_daily`
PARTITION BY report_date
AS
WITH normalized AS (
  SELECT
    data_date AS report_date,
    site_url,
    url,
    search_type,
    country,
    device,
    clicks,
    impressions,
    sum_position,
    CASE
      WHEN REGEXP_CONTAINS(url, r'^https?://') THEN
        COALESCE(NULLIF(REGEXP_EXTRACT(url, r'^https?://[^/]+(/.*)$'), ''), '/')
      WHEN STARTS_WITH(url, '/') THEN url
      ELSE CONCAT('/', url)
    END AS page_path_raw
  FROM `lifeline-website-480522.searchconsole.searchdata_url_impression`
),
cleaned AS (
  SELECT
    report_date,
    site_url,
    url,
    search_type,
    country,
    device,
    clicks,
    impressions,
    sum_position,
    REGEXP_REPLACE(REGEXP_REPLACE(page_path_raw, r'#.*$', ''), r'\?.*$', '') AS page_path_no_query
  FROM normalized
)
SELECT
  report_date,
  site_url,
  url,
  search_type,
  country,
  device,
  CASE
    WHEN page_path_no_query = '' THEN '/'
    WHEN page_path_no_query = '/' THEN '/'
    ELSE REGEXP_REPLACE(page_path_no_query, r'/$', '')
  END AS page_path,
  SUM(clicks) AS clicks,
  SUM(impressions) AS impressions,
  SAFE_DIVIDE(SUM(clicks), SUM(impressions)) AS ctr,
  SAFE_DIVIDE(SUM(sum_position), SUM(impressions)) + 1 AS avg_position
FROM cleaned
GROUP BY report_date, site_url, url, search_type, country, device, page_path;


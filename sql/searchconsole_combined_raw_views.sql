-- Combined Search Console sources for curated models.
-- These views add historical API backfill rows and keep live bulk export rows.
-- Overlap rule: live export wins for overlapping dates.

CREATE OR REPLACE VIEW `lifeline-website-480522.searchconsole.searchdata_site_impression_all` AS
WITH live_export AS (
  SELECT
    data_date,
    site_url,
    search_type,
    country,
    device,
    clicks,
    impressions,
    sum_top_position
  FROM `lifeline-website-480522.searchconsole.searchdata_site_impression`
),
backfill AS (
  SELECT
    data_date,
    site_url,
    search_type,
    country,
    device,
    clicks,
    impressions,
    sum_top_position
  FROM `lifeline-website-480522.searchconsole.searchdata_site_impression_backfill`
),
live_start AS (
  SELECT COALESCE(MIN(data_date), DATE '9999-12-31') AS min_live_date FROM live_export
)
SELECT * FROM backfill WHERE data_date < (SELECT min_live_date FROM live_start)
UNION ALL
SELECT * FROM live_export;


CREATE OR REPLACE VIEW `lifeline-website-480522.searchconsole.searchdata_url_impression_all` AS
WITH live_export AS (
  SELECT
    data_date,
    site_url,
    url,
    query,
    is_anonymized_query,
    search_type,
    country,
    device,
    clicks,
    impressions,
    sum_position
  FROM `lifeline-website-480522.searchconsole.searchdata_url_impression`
),
backfill AS (
  SELECT
    data_date,
    site_url,
    url,
    query,
    is_anonymized_query,
    search_type,
    country,
    device,
    clicks,
    impressions,
    sum_position
  FROM `lifeline-website-480522.searchconsole.searchdata_url_impression_backfill`
),
live_start AS (
  SELECT COALESCE(MIN(data_date), DATE '9999-12-31') AS min_live_date FROM live_export
)
SELECT * FROM backfill WHERE data_date < (SELECT min_live_date FROM live_start)
UNION ALL
SELECT * FROM live_export;

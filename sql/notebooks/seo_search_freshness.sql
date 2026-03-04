SELECT
  (SELECT MAX(report_date) FROM `{project_id}.{searchconsole_dataset}.curated_search_url_daily`) AS gsc_max_date,
  (SELECT MAX(event_day) FROM `{project_id}.{ga4_dataset}.curated_ga4_page_daily`) AS ga4_max_date,
  (SELECT MAX(report_date) FROM `{project_id}.{searchconsole_dataset}.seo_page_daily`) AS seo_max_date

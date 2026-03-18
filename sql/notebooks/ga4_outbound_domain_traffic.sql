WITH target AS (
  SELECT
    DATE(@start_date) AS start_date,
    DATE(@end_date) AS end_date,
    TRIM(LOWER(@page_path_filter)) AS page_path_filter,
    @include_lifeline_subdomains AS include_lifeline_subdomains
),
target_with_pattern AS (
  SELECT
    start_date,
    end_date,
    page_path_filter,
    include_lifeline_subdomains,
    page_path_filter = '' AS is_sitewide,
    STRPOS(page_path_filter, '*') > 0 AS is_wildcard,
    CONCAT(
      '^',
      REPLACE(
        REGEXP_REPLACE(page_path_filter, r'([.^$+?()\\[\\]{{}}|])', r'\\\\\\1'),
        '*',
        '.*'
      ),
      '$'
    ) AS page_path_regex
  FROM target
),
base AS (
  SELECT
    PARSE_DATE('%Y%m%d', event_date) AS report_date,
    CASE
      WHEN page_location_raw = '' THEN ''
      WHEN REGEXP_CONTAINS(page_location_raw, r'^https?://') THEN
        CASE
          WHEN COALESCE(REGEXP_EXTRACT(page_location_raw, r'^https?://[^/]+(/[^?#]*)'), '') = '' THEN '/'
          ELSE COALESCE(REGEXP_EXTRACT(page_location_raw, r'^https?://[^/]+(/[^?#]*)'), '')
        END
      WHEN STARTS_WITH(page_location_raw, '/') THEN
        COALESCE(REGEXP_EXTRACT(page_location_raw, r'^([^?#]*)'), '/')
      ELSE
        COALESCE(REGEXP_EXTRACT(CONCAT('/', page_location_raw), r'^([^?#]*)'), '/')
    END AS page_path_raw,
    LOWER(
      COALESCE(
        (
          SELECT ep.value.string_value
          FROM UNNEST(event_params) ep
          WHERE ep.key = 'link_domain'
        ),
        REGEXP_EXTRACT(
          COALESCE((
            SELECT ep.value.string_value
            FROM UNNEST(event_params) ep
            WHERE ep.key = 'link_url'
          ), ''),
          r'^https?://([^/?#]+)'
        )
      )
    ) AS destination_domain
  FROM (
    SELECT
      event_date,
      event_params,
      COALESCE((
        SELECT ep.value.string_value
        FROM UNNEST(event_params) ep
        WHERE ep.key = 'page_location'
      ), '') AS page_location_raw
    FROM `{project_id}.{ga4_dataset}.events_*`
    WHERE _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE(@start_date))
      AND FORMAT_DATE('%Y%m%d', DATE(@end_date))
      AND event_name = 'click'
  )
),
filtered AS (
  SELECT
    base.report_date,
    CASE
      WHEN page_path_raw IN ('', '/') THEN '/'
      ELSE REGEXP_REPLACE(LOWER(page_path_raw), r'/$', '')
    END AS page_path,
    destination_domain
  FROM base
  CROSS JOIN target_with_pattern AS target
  WHERE destination_domain IS NOT NULL
    AND destination_domain != ''
    AND destination_domain != 'www.lifeline.org.au'
    AND (
      target.include_lifeline_subdomains
      OR (
        destination_domain != 'lifeline.org.au'
        AND NOT ENDS_WITH(destination_domain, '.lifeline.org.au')
      )
    )
    AND (
      target.is_sitewide
      OR (
        NOT target.is_wildcard
        AND (
          CASE
            WHEN page_path_raw IN ('', '/') THEN '/'
            ELSE REGEXP_REPLACE(LOWER(page_path_raw), r'/$', '')
          END
        ) = target.page_path_filter
      )
      OR (
        target.is_wildcard
        AND REGEXP_CONTAINS(
          CASE
            WHEN page_path_raw IN ('', '/') THEN '/'
            ELSE REGEXP_REPLACE(LOWER(page_path_raw), r'/$', '')
          END,
          target.page_path_regex
        )
      )
    )
),
domain_totals AS (
  SELECT
    destination_domain,
    COUNT(*) AS total_clicks
  FROM filtered
  GROUP BY destination_domain
),
daily_domain_clicks AS (
  SELECT
    report_date,
    destination_domain,
    COUNT(*) AS daily_clicks
  FROM filtered
  GROUP BY report_date, destination_domain
)
SELECT
  daily_domain_clicks.report_date,
  daily_domain_clicks.destination_domain,
  daily_domain_clicks.daily_clicks,
  domain_totals.total_clicks
FROM daily_domain_clicks
JOIN domain_totals
  USING (destination_domain)
ORDER BY domain_totals.total_clicks DESC, daily_domain_clicks.report_date, daily_domain_clicks.destination_domain

WITH target AS (
  SELECT
    LOWER(REGEXP_REPLACE(REGEXP_REPLACE(@source_page, r'[?#].*$', ''), r'/$', '')) AS source_page_normalized,
    LOWER(@outbound_domain) AS outbound_domain
),
date_spine AS (
  SELECT report_date
  FROM UNNEST(GENERATE_DATE_ARRAY(DATE(@start_date), DATE(@end_date))) AS report_date
),
base AS (
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
    LOWER(
      REGEXP_REPLACE(
        REGEXP_REPLACE(
          COALESCE((
            SELECT ep.value.string_value
            FROM UNNEST(event_params) ep
            WHERE ep.key = 'page_location'
          ), ''),
          r'[?#].*$',
          ''
        ),
        r'/$',
        ''
      )
    ) AS page_location_normalized,
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
    ) AS link_domain,
    event_name
  FROM `{project_id}.{ga4_dataset}.events_*`
  WHERE _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE(@start_date))
    AND FORMAT_DATE('%Y%m%d', DATE(@end_date))
    AND event_name IN ('page_view', 'click')
),
page_views AS (
  SELECT
    base.report_date,
    COUNT(*) AS page_view_events,
    COUNT(DISTINCT session_key) AS page_view_sessions
  FROM base
  CROSS JOIN target
  WHERE event_name = 'page_view'
    AND page_location_normalized = target.source_page_normalized
  GROUP BY base.report_date
),
outbound_clicks AS (
  SELECT
    base.report_date,
    COUNT(*) AS outbound_click_events,
    COUNT(DISTINCT session_key) AS outbound_click_sessions
  FROM base
  CROSS JOIN target
  WHERE event_name = 'click'
    AND page_location_normalized = target.source_page_normalized
    AND link_domain = target.outbound_domain
  GROUP BY base.report_date
)
SELECT
  date_spine.report_date,
  COALESCE(page_views.page_view_events, 0) AS page_view_events,
  COALESCE(page_views.page_view_sessions, 0) AS page_view_sessions,
  COALESCE(outbound_clicks.outbound_click_events, 0) AS outbound_click_events,
  COALESCE(outbound_clicks.outbound_click_sessions, 0) AS outbound_click_sessions,
  SAFE_DIVIDE(
    COALESCE(outbound_clicks.outbound_click_events, 0),
    NULLIF(COALESCE(page_views.page_view_events, 0), 0)
  ) AS event_click_through_rate,
  SAFE_DIVIDE(
    COALESCE(outbound_clicks.outbound_click_sessions, 0),
    NULLIF(COALESCE(page_views.page_view_sessions, 0), 0)
  ) AS session_click_through_rate
FROM date_spine
LEFT JOIN page_views
  ON date_spine.report_date = page_views.report_date
LEFT JOIN outbound_clicks
  ON date_spine.report_date = outbound_clicks.report_date
ORDER BY date_spine.report_date

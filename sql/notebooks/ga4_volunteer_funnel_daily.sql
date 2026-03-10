WITH target AS (
  SELECT
    LOWER(REGEXP_REPLACE(REGEXP_REPLACE(@volunteer_page, r'[?#].*$', ''), r'/$', '')) AS volunteer_page,
    LOWER(REGEXP_REPLACE(REGEXP_REPLACE(@crisis_supporter_page, r'[?#].*$', ''), r'/$', '')) AS crisis_supporter_page,
    LOWER(REGEXP_REPLACE(REGEXP_REPLACE(@phone_support_page, r'[?#].*$', ''), r'/$', '')) AS phone_support_page,
    LOWER(REGEXP_REPLACE(REGEXP_REPLACE(@digital_support_page, r'[?#].*$', ''), r'/$', '')) AS digital_support_page,
    LOWER(REGEXP_REPLACE(REGEXP_REPLACE(@phone_form_page, r'[?#].*$', ''), r'/$', '')) AS phone_form_page,
    LOWER(@digital_outbound_domain) AS digital_outbound_domain,
    @phone_form_id AS phone_form_id
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
    (
      SELECT ep.value.string_value
      FROM UNNEST(event_params) ep
      WHERE ep.key = 'form_id'
    ) AS form_id,
    event_name
  FROM `{project_id}.{ga4_dataset}.events_*`
  WHERE _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE(@start_date))
    AND FORMAT_DATE('%Y%m%d', DATE(@end_date))
    AND event_name IN ('page_view', 'click', 'form_submit')
),
session_flags AS (
  SELECT
    base.report_date,
    session_key,
    MAX(IF(event_name = 'page_view' AND page_location_normalized = target.volunteer_page, 1, 0)) AS volunteer_page_session,
    MAX(IF(event_name = 'page_view' AND page_location_normalized = target.crisis_supporter_page, 1, 0)) AS crisis_supporter_page_session,
    MAX(IF(event_name = 'page_view' AND page_location_normalized = target.phone_support_page, 1, 0)) AS phone_support_page_session,
    MAX(IF(event_name = 'page_view' AND page_location_normalized = target.digital_support_page, 1, 0)) AS digital_support_page_session,
    MAX(IF(event_name = 'page_view' AND page_location_normalized = target.phone_form_page, 1, 0)) AS phone_form_page_session,
    MAX(
      IF(
        event_name = 'click'
        AND page_location_normalized = target.digital_support_page
        AND link_domain = target.digital_outbound_domain,
        1,
        0
      )
    ) AS digital_signup_session,
    MAX(
      IF(
        event_name = 'form_submit'
        AND page_location_normalized = target.phone_form_page
        AND form_id = target.phone_form_id,
        1,
        0
      )
    ) AS phone_form_submit_session
  FROM base
  CROSS JOIN target
  GROUP BY base.report_date, session_key
),
session_daily AS (
  SELECT
    report_date,
    SUM(volunteer_page_session) AS volunteer_page_sessions,
    SUM(crisis_supporter_page_session) AS crisis_supporter_page_sessions,
    SUM(phone_support_page_session) AS phone_support_page_sessions,
    SUM(digital_support_page_session) AS digital_support_page_sessions,
    SUM(phone_form_page_session) AS phone_form_page_sessions,
    SUM(digital_signup_session) AS digital_signup_sessions,
    SUM(phone_form_submit_session) AS phone_form_submit_sessions,
    SUM(IF(digital_signup_session = 1 OR phone_form_submit_session = 1, 1, 0)) AS any_conversion_sessions
  FROM session_flags
  GROUP BY report_date
),
event_daily AS (
  SELECT
    base.report_date,
    COUNTIF(
      event_name = 'click'
      AND page_location_normalized = target.digital_support_page
      AND link_domain = target.digital_outbound_domain
    ) AS digital_signup_events,
    COUNTIF(
      event_name = 'form_submit'
      AND page_location_normalized = target.phone_form_page
      AND form_id = target.phone_form_id
    ) AS phone_form_submit_events
  FROM base
  CROSS JOIN target
  GROUP BY base.report_date
)
SELECT
  date_spine.report_date,
  COALESCE(session_daily.volunteer_page_sessions, 0) AS volunteer_page_sessions,
  COALESCE(session_daily.crisis_supporter_page_sessions, 0) AS crisis_supporter_page_sessions,
  COALESCE(session_daily.phone_support_page_sessions, 0) AS phone_support_page_sessions,
  COALESCE(session_daily.digital_support_page_sessions, 0) AS digital_support_page_sessions,
  COALESCE(session_daily.phone_form_page_sessions, 0) AS phone_form_page_sessions,
  COALESCE(session_daily.digital_signup_sessions, 0) AS digital_signup_sessions,
  COALESCE(session_daily.phone_form_submit_sessions, 0) AS phone_form_submit_sessions,
  COALESCE(session_daily.any_conversion_sessions, 0) AS any_conversion_sessions,
  COALESCE(event_daily.digital_signup_events, 0) AS digital_signup_events,
  COALESCE(event_daily.phone_form_submit_events, 0) AS phone_form_submit_events
FROM date_spine
LEFT JOIN session_daily
  ON date_spine.report_date = session_daily.report_date
LEFT JOIN event_daily
  ON date_spine.report_date = event_daily.report_date
ORDER BY date_spine.report_date

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
base AS (
  SELECT
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
    event_date,
    event_timestamp,
    event_name,
    event_params,
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
    ) AS form_id
  FROM `{project_id}.{ga4_dataset}.events_*`
  WHERE _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE(@start_date))
    AND FORMAT_DATE('%Y%m%d', DATE(@end_date))
    AND event_name IN ('page_view', 'click', 'form_submit', 'user_engagement', 'session_start')
),
session_paths AS (
  SELECT
    session_key,
    MIN(IF(event_name = 'page_view' AND page_location_normalized = target.volunteer_page, event_timestamp, NULL)) AS volunteer_ts,
    MIN(IF(event_name = 'page_view' AND page_location_normalized = target.crisis_supporter_page, event_timestamp, NULL)) AS crisis_ts,
    MIN(IF(event_name = 'page_view' AND page_location_normalized = target.digital_support_page, event_timestamp, NULL)) AS digital_support_ts,
    MIN(IF(event_name = 'page_view' AND page_location_normalized = target.phone_support_page, event_timestamp, NULL)) AS phone_support_ts,
    MIN(IF(event_name = 'page_view' AND page_location_normalized = target.phone_form_page, event_timestamp, NULL)) AS phone_form_ts,
    MIN(
      IF(
        event_name = 'click'
        AND page_location_normalized = target.digital_support_page
        AND link_domain = target.digital_outbound_domain,
        event_timestamp,
        NULL
      )
    ) AS digital_signup_ts,
    MIN(
      IF(
        event_name = 'form_submit'
        AND page_location_normalized = target.phone_form_page
        AND form_id = target.phone_form_id,
        event_timestamp,
        NULL
      )
    ) AS phone_submit_ts,
    MIN(IF(event_name = 'page_view' AND page_location_normalized = target.crisis_supporter_page, event_date, NULL)) AS crisis_event_date
  FROM base
  CROSS JOIN target
  GROUP BY session_key
),
post_crisis_activity AS (
  SELECT
    sp.session_key,
    MAX(
      IF(
        COALESCE((
          SELECT ep.value.string_value
          FROM UNNEST(base.event_params) ep
          WHERE ep.key = 'session_engaged'
        ), CAST((
          SELECT ep.value.int_value
          FROM UNNEST(base.event_params) ep
          WHERE ep.key = 'session_engaged'
        ) AS STRING)) = '1',
        1,
        0
      )
    ) AS engaged_session,
    MIN(
      IF(
        base.event_timestamp > sp.crisis_ts
        AND NOT (
          base.event_name = 'page_view'
          AND base.page_location_normalized = target.crisis_supporter_page
        ),
        base.event_timestamp,
        NULL
      )
    ) AS first_post_crisis_event_ts,
    MIN(
      IF(
        base.event_name = 'page_view'
        AND base.event_timestamp > sp.crisis_ts
        AND base.page_location_normalized NOT IN (
          target.crisis_supporter_page,
          target.digital_support_page,
          target.phone_support_page,
          target.phone_form_page
        ),
        base.event_timestamp,
        NULL
      )
    ) AS first_other_page_ts
  FROM session_paths sp
  JOIN base
    ON base.session_key = sp.session_key
  CROSS JOIN target
  WHERE sp.crisis_ts IS NOT NULL
  GROUP BY sp.session_key
),
crisis_cohort AS (
  SELECT
    PARSE_DATE('%Y%m%d', session_paths.crisis_event_date) AS report_date,
    session_paths.session_key,
    session_paths.volunteer_ts,
    session_paths.crisis_ts,
    session_paths.digital_support_ts,
    session_paths.phone_support_ts,
    session_paths.phone_form_ts,
    session_paths.digital_signup_ts,
    session_paths.phone_submit_ts,
    COALESCE(post_crisis_activity.engaged_session, 0) AS engaged_session,
    IF(post_crisis_activity.first_post_crisis_event_ts IS NOT NULL, 1, 0) AS has_post_crisis_activity,
    IF(post_crisis_activity.first_other_page_ts IS NOT NULL, 1, 0) AS has_other_page_after_crisis,
    (SELECT stage
      FROM UNNEST([
        STRUCT(volunteer_ts AS ts, 'Volunteer page' AS stage),
        STRUCT(crisis_ts AS ts, 'Crisis supporter page' AS stage),
        STRUCT(digital_support_ts AS ts, 'Digital support page' AS stage),
        STRUCT(phone_support_ts AS ts, 'Phone support page' AS stage),
        STRUCT(phone_form_ts AS ts, 'Phone form page' AS stage)
      ])
      WHERE ts IS NOT NULL
      ORDER BY ts
      LIMIT 1
    ) AS entry_stage,
    IF(volunteer_ts IS NOT NULL AND volunteer_ts < crisis_ts, 1, 0) AS reached_volunteer_before_crisis,
    IF(digital_support_ts IS NOT NULL AND digital_support_ts > crisis_ts, 1, 0) AS reached_digital_after_crisis,
    IF(
      digital_support_ts IS NOT NULL
      AND digital_signup_ts IS NOT NULL
      AND digital_support_ts > crisis_ts
      AND digital_signup_ts > digital_support_ts,
      1,
      0
    ) AS reached_digital_signup_after_digital,
    IF(phone_support_ts IS NOT NULL AND phone_support_ts > crisis_ts, 1, 0) AS reached_phone_support_after_crisis,
    IF(
      phone_support_ts IS NOT NULL
      AND phone_form_ts IS NOT NULL
      AND phone_support_ts > crisis_ts
      AND phone_form_ts > phone_support_ts,
      1,
      0
    ) AS reached_phone_form_after_support,
    IF(
      phone_support_ts IS NOT NULL
      AND phone_form_ts IS NOT NULL
      AND phone_submit_ts IS NOT NULL
      AND phone_support_ts > crisis_ts
      AND phone_form_ts > phone_support_ts
      AND phone_submit_ts > phone_form_ts,
      1,
      0
    ) AS reached_phone_submit_after_form,
    CASE
      WHEN digital_support_ts IS NOT NULL
        AND digital_support_ts > crisis_ts
        AND (
          phone_support_ts IS NULL
          OR phone_support_ts <= crisis_ts
          OR digital_support_ts < phone_support_ts
        )
      THEN 'Digital first'
      WHEN phone_support_ts IS NOT NULL
        AND phone_support_ts > crisis_ts
        AND (
          digital_support_ts IS NULL
          OR digital_support_ts <= crisis_ts
          OR phone_support_ts < digital_support_ts
        )
      THEN 'Phone first'
      WHEN digital_support_ts IS NOT NULL
        AND digital_support_ts > crisis_ts
        AND phone_support_ts IS NOT NULL
        AND phone_support_ts > crisis_ts
        AND digital_support_ts = phone_support_ts
      THEN 'Digital and phone same time'
      ELSE 'No tracked branch'
    END AS first_branch_after_crisis,
    CASE
      WHEN digital_support_ts IS NOT NULL
        AND digital_support_ts > crisis_ts
        AND phone_support_ts IS NOT NULL
        AND phone_support_ts > crisis_ts
      THEN 'Both branches'
      WHEN digital_support_ts IS NOT NULL
        AND digital_support_ts > crisis_ts
      THEN 'Digital only'
      WHEN phone_support_ts IS NOT NULL
        AND phone_support_ts > crisis_ts
      THEN 'Phone only'
      ELSE 'No tracked branch'
    END AS branch_mix,
    CASE
      WHEN digital_support_ts IS NOT NULL
        AND digital_support_ts > crisis_ts
        AND (
          post_crisis_activity.first_other_page_ts IS NULL
          OR digital_support_ts <= post_crisis_activity.first_other_page_ts
        )
        AND (
          phone_support_ts IS NULL
          OR phone_support_ts <= crisis_ts
          OR digital_support_ts <= phone_support_ts
        )
      THEN 'Digital page first'
      WHEN phone_support_ts IS NOT NULL
        AND phone_support_ts > crisis_ts
        AND (
          post_crisis_activity.first_other_page_ts IS NULL
          OR phone_support_ts <= post_crisis_activity.first_other_page_ts
        )
        AND (
          digital_support_ts IS NULL
          OR digital_support_ts <= crisis_ts
          OR phone_support_ts <= digital_support_ts
        )
      THEN 'Phone page first'
      WHEN post_crisis_activity.first_other_page_ts IS NOT NULL
      THEN 'Other page first'
      WHEN post_crisis_activity.first_post_crisis_event_ts IS NOT NULL
      THEN 'Other activity only'
      ELSE 'No onward activity'
    END AS first_post_crisis_action,
    CASE
      WHEN post_crisis_activity.first_post_crisis_event_ts IS NULL
      THEN 'No onward activity'
      WHEN digital_support_ts IS NULL
        AND phone_support_ts IS NULL
        AND post_crisis_activity.first_other_page_ts IS NOT NULL
      THEN 'Other page only'
      WHEN digital_support_ts IS NULL
        AND phone_support_ts IS NULL
      THEN 'Other activity only'
      ELSE 'Reached tracked branch'
    END AS onward_outcome
  FROM session_paths
  LEFT JOIN post_crisis_activity
    ON post_crisis_activity.session_key = session_paths.session_key
  WHERE crisis_ts IS NOT NULL
)
SELECT
  report_date,
  session_key,
  entry_stage,
  engaged_session,
  has_post_crisis_activity,
  has_other_page_after_crisis,
  reached_volunteer_before_crisis,
  reached_digital_after_crisis,
  reached_digital_signup_after_digital,
  reached_phone_support_after_crisis,
  reached_phone_form_after_support,
  reached_phone_submit_after_form,
  first_branch_after_crisis,
  branch_mix,
  first_post_crisis_action,
  onward_outcome
FROM crisis_cohort
ORDER BY report_date, session_key

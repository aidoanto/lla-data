# SEO Metrics Definitions

This document defines the key metrics used in Search Console + GA4 notebooks.

## Source Metrics

- `clicks`  
  Number of clicks from Google Search to a result.

- `impressions`  
  Number of times a result was shown in search results.

- `ctr`  
  `clicks / impressions` using `SAFE_DIVIDE`.

- `avg_position`  
  `sum_top_position / impressions + 1`.  
  Lower is better (position 1 is best).

- `total_sessions` (GA4)  
  Distinct sessions from `session_start` events.

- `organic_sessions` (GA4)  
  Distinct `session_start` sessions where medium is `organic`.

- `engaged_sessions` (GA4)  
  Distinct sessions that have page views marked with `session_engaged = '1'`.

## Derived Metrics

- `search_share`  
  `organic_sessions / total_sessions`  
  Indicates how much of traffic appears to come from search.

- `click_to_session_ratio`  
  `gsc_clicks / organic_sessions`  
  Helps compare Search Console clicks vs GA4 organic session capture.

- `impression_to_click_band`  
  A category for prioritization:
  - `low-data` if impressions < 20
  - `very-low-ctr` if CTR < 2%
  - `low-ctr` if CTR < 5%
  - `mid-ctr` if CTR < 10%
  - `high-ctr` otherwise

## Practical Interpretation Guide

- High impressions + low CTR + positions 6-20:
  - Usually the highest-value optimization zone.
- Rising impressions + flat clicks:
  - Visibility is improving but snippet/intent match may be weak.
- Falling position + falling CTR:
  - Competitiveness may be dropping; review content freshness and intent.
- High click_to_session_ratio mismatch:
  - Can indicate tracking gaps, cross-domain issues, or timing differences.

## Minimum Data Thresholds (Recommended)

Use thresholds before making decisions:
- Page-level: at least 100 impressions in period.
- Query-level: at least 20 impressions in period.
- Trend charts: at least 14 days when possible.

## Known Limitations

- GSC and GA4 are different systems and will not match perfectly.
- Time zones and attribution rules can produce small daily differences.
- Anonymized queries reduce long-tail visibility.


# Notebook Usage Guide

Use this guide to keep notebook analysis consistent, reliable, and cost-aware.

## Standard Workflow

1. Start from `notebooks/templates/analysis_template.ipynb`.
2. Set a short date range first (7-28 days).
3. Run a dry run to estimate bytes.
4. Validate row counts and key columns.
5. Build charts only after metric checks look correct.

## Import Pattern

Use this at the top of notebooks:

```python
import sys
sys.path.insert(0, "..")
sys.path.insert(0, "../..")

import lifeline_theme
from lla_data import config
from lla_data.bq import get_client, run_query, dry_run_bytes, default_query_window, build_date_params
```

Why:
- Avoid hardcoding project/dataset values.
- Reuse one query execution pattern.
- Keep dry-run behavior consistent.

## Query Guardrails

- Prefer curated tables over raw `events_*`.
- Always parameterize date filters (`@start_date`, `@end_date`).
- Add reasonable thresholds for decision dashboards (impressions/session minimums).
- Use `SAFE_DIVIDE` in SQL metrics to avoid divide-by-zero errors.

## Chart Guardrails

- Use `template=\"lifeline\"` for brand consistency.
- Add logo with `lifeline_theme.add_lifeline_logo(fig)`.
- Sort bars intentionally and label axes clearly.
- Keep one business question per chart.

## Data Freshness Rules

- Check most recent date in source and curated tables before analysis.
- For new Search Console imports, expect low coverage early on.
- Highlight sparse-history limits in notebook markdown cells.

## Weekly Reliability Workflow

Use one (or both) of these weekly checks:

1. Python validation script:
   ```bash
   uv run python scripts/validate_seo_models.py
   ```
2. BigQuery scheduled query:
   - `sql/weekly_seo_health_check.sql`
   - Recommended cadence: weekly on Monday (Sydney time)

## Notebook Quality Checklist

Before sharing notebook output:
- Query uses curated model
- Date parameters are explicit
- Costs were estimated with dry run
- Definitions match `docs/seo-metrics-definitions.md`
- Caveats are written in markdown

## Common Pitfalls

- Joining GA4 and GSC on raw URL without normalization.
- Mixing page-level and query-level metrics in one chart.
- Comparing same-day values when export lag is present.
- Treating low-impression rows as reliable trends.


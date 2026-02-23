"""Central configuration for BigQuery projects and datasets."""

from __future__ import annotations

import os


PROJECT_ID = os.getenv("LLA_PROJECT_ID", "lifeline-website-480522")
GA4_DATASET = os.getenv("LLA_GA4_DATASET", "analytics_315584957")
SEARCHCONSOLE_DATASET = os.getenv("LLA_SEARCHCONSOLE_DATASET", "searchconsole")

# BigQuery location name for Sydney.
BIGQUERY_LOCATION = os.getenv("LLA_BIGQUERY_LOCATION", "australia-southeast1")

# Notebook defaults.
DEFAULT_DAYS_BACK = int(os.getenv("LLA_DEFAULT_DAYS_BACK", "28"))
DEFAULT_TOP_N = int(os.getenv("LLA_DEFAULT_TOP_N", "25"))


"""Central configuration for BigQuery projects and datasets."""

from __future__ import annotations

import os


SEARCHCONSOLE_PROJECT_ID = os.getenv(
    "LLA_SEARCHCONSOLE_PROJECT_ID",
    os.getenv("LLA_PROJECT_ID", "lifeline-website-480522"),
)
GA4_PROJECT_ID = os.getenv("LLA_GA4_PROJECT_ID", "lifeline-web-analytics")

# Backward-compatible default project for query jobs and legacy code paths.
PROJECT_ID = SEARCHCONSOLE_PROJECT_ID
GA4_DATASET = os.getenv("LLA_GA4_DATASET", "analytics_315584957")
SEARCHCONSOLE_DATASET = os.getenv("LLA_SEARCHCONSOLE_DATASET", "searchconsole")

# BigQuery location name for Sydney.
BIGQUERY_LOCATION = os.getenv("LLA_BIGQUERY_LOCATION", "australia-southeast1")

# Notebook defaults.
DEFAULT_DAYS_BACK = int(os.getenv("LLA_DEFAULT_DAYS_BACK", "28"))
DEFAULT_TOP_N = int(os.getenv("LLA_DEFAULT_TOP_N", "25"))

# Site and external keyword research defaults.
SITE_BASE_URL = os.getenv("LLA_SITE_BASE_URL", "https://www.lifeline.org.au")
DEFAULT_KEYWORD_LOCATION = os.getenv("LLA_DEFAULT_KEYWORD_LOCATION", "Australia")
DEFAULT_KEYWORD_LANGUAGE = os.getenv("LLA_DEFAULT_KEYWORD_LANGUAGE", "English")

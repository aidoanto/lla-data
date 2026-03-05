# LLA Data

## Start Here

This project is a set of ready-to-run notebooks for understanding website performance (traffic, search visibility, and user behavior).

Before getting started, you'll need access to the Google Cloud Platform. If you don't have access, let me know and I'll get you set up.

If you are new to coding, the easiest way to use this project is **Google Colab**. Here's how:

Visit Google Colab and click on the `File` menu. Then click on `Open Notebook`. Then click on the `GitHub` tab. Then where it say "Enter a GitHub URL or search by organisation or user". Type in `https://github.com/aidanm-lla/lla-data`. Make sure the 'include private repos' checkbox is checked and hit enter. You can then browse from the list of available notebooks.

Each notebook will have instructions on how to run it, but the basic process is to first press the 'Connect' button which will connect you to a 'runtime' which is a virtual machine that will run the notebook in the cloud. You can then run the notebook cells from top to bottom by pressing the 'Run all' button.

### Open In Colab

- **Search contribution over time**: `01_search_contribution_overview.ipynb`
- **Top pages from search**: `02_top_pages_search_performance.ipynb`
- **Queries that drive a specific page**: `03_query_drivers_by_page.ipynb`
- **SEO opportunity watchlist**: `04_opportunity_watchlist.ipynb`
- **Traffic source quality**: `05_traffic_sources.ipynb`
- **Time patterns for crisis-related pages**: `06_time_patterns.ipynb`
- **Top search queries (sitewide)**: `07_top_search_queries_sitewide.ipynb`
- **SXO page and query dynamics**: `08_sxo_page_query_dynamics.ipynb`

For technical details, see `INFO.md`.

## Canonical Table Map

Use these as your default notebook sources:

- `searchconsole.seo_page_daily` - primary page-level SEO analysis table (GSC + GA4 joined)
- `searchconsole.curated_search_query_page_daily` - query-level table for page/query dynamics

These are pipeline plumbing tables and are usually not queried directly in notebooks:

- `searchconsole.searchdata_site_impression` and `searchconsole.searchdata_url_impression` (live raw export)
- `searchconsole.searchdata_site_impression_backfill` and `searchconsole.searchdata_url_impression_backfill` (API backfill)
- `searchconsole.searchdata_site_impression_all` and `searchconsole.searchdata_url_impression_all` (combined raw + backfill views feeding curated models)

Simple rule of thumb:

- Page-level trend question -> `seo_page_daily`
- Query-term question -> `curated_search_query_page_daily`
- Data ingestion/debug question -> `searchdata_*`
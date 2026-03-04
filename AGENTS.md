I am Aidan, a digital producer at Lifeline Australia. This repo is a space for me to explore and analyse our web data from GA and GSC in Python, using APIs from Google Cloud and GSC. The relevant Google Cloud project is 'lifeline-website-480522'.

Conventions:

- Keep active analysis notebooks flat in `notebooks/` and numbered (`01_`, `02_`, ...).
- Put non-trivial notebook SQL in `sql/notebooks/`; keep notebook cells focused on params + analysis.
- Use `lla_data.bq.load_sql_template(...)` for SQL loading and `run_query(...)` for execution.
- Parameterize values (`@start_date`, `@end_date`, limits) instead of f-string interpolation.
- Use SQL-first for BigQuery-native logic (`UNNEST`, `_TABLE_SUFFIX`, complex CTEs); use BigFrames only for selective pandas-style exploration.

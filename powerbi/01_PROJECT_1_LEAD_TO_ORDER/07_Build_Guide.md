# Project 1 — Build Guide

1. Connect SQL Server → database `SEPRO_Master_Prod`.
2. Import the Gold tables listed in `00_Data_Model.md`.
3. Create `pbi_p1_lead_diagnostic` using the native SQL in `01_Source_Queries.sql`.
4. Build relationships exactly as documented; keep single-direction filtering.
5. Mark `dim_date` as Date Table.
6. Paste calculated tables from `02_Measures.dax`, then measures.
7. Sort `p1_funnel_stage[Stage]` by `[Sort]`; sort transition likewise.
8. Import `Theme.json` via View → Themes → Browse for themes.
9. Build Page 1, then Page 2, then Page 3 using exact field mappings.
10. Configure Edit Interactions after all visuals are on canvas.
11. Validate current unfiltered Project 1 numbers before formatting polish.
12. Hide technical keys from report view: `*_key`, surrogate keys, helper columns.
13. Create display folders for measures: `01 Funnel`, `02 Response`, `03 Channel`, `04 Diagnostic`.

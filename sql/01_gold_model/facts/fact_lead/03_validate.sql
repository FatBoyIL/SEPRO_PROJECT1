--/* Check duplicate lead_id in Silver */

--SELECT
--    lead_id,
--    COUNT(*) AS row_count
--FROM silver.leads
--GROUP BY lead_id
--HAVING COUNT(*) > 1;

/* Check duplicate lead_id in Gold */

--SELECT
--    lead_id,
--    COUNT(*) AS row_count
--FROM gold.fact_lead
--GROUP BY lead_id
--HAVING COUNT(*) > 1;

/* Records that exist in Silver but are missing in Gold */

--SELECT lead_id
--FROM silver.leads

--EXCEPT

--SELECT lead_id
--FROM gold.fact_lead;

--/* Records that exist in Gold but not in Silver */

--SELECT lead_id
--FROM gold.fact_lead

--EXCEPT

--SELECT lead_id
--FROM silver.leads;

/* Row count reconciliation */

--SELECT
--    (SELECT COUNT(*) FROM silver.leads) AS silver_rows,
--    (SELECT COUNT(DISTINCT lead_id)
--     FROM silver.leads) AS silver_unique_leads,

--    (SELECT COUNT(*) FROM gold.fact_lead) AS gold_rows,
--    (SELECT COUNT(DISTINCT lead_id)
--     FROM gold.fact_lead) AS gold_unique_leads;

--/* Check customer mapping */

--SELECT
--    s.lead_id,
--    s.customer_id,
--    dc.customer_key

--FROM silver.leads s

--LEFT JOIN gold.dim_customer dc
--    ON s.customer_id = dc.customer_id

--WHERE s.customer_id IS NOT NULL
--  AND dc.customer_key IS NULL;

--  /* Check campaign mapping */

--SELECT
--    s.lead_id,
--    s.campaign_id

--FROM silver.leads s

--LEFT JOIN gold.dim_campaign dc
--    ON s.campaign_id = dc.campaign_id

--WHERE s.campaign_id IS NOT NULL
--  AND dc.campaign_key IS NULL;

--  /* Check employee mapping */

--SELECT
--    s.lead_id,
--    s.assigned_sales_id

--FROM silver.leads s

--LEFT JOIN gold.dim_employee de
--    ON s.assigned_sales_id = de.employee_id

--WHERE s.assigned_sales_id IS NOT NULL
--  AND de.employee_key IS NULL;
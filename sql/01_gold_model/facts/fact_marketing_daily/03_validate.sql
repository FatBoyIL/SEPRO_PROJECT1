USE SEPRO_Master_Prod;
GO

/* =========================================================
   PROJECT 1 - VALIDATE FACT_MARKETING_DAILY
   ========================================================= */

SELECT 'Duplicate Silver business grain' AS validation_check, COUNT(*) AS issue_count
FROM
(
    SELECT [date], campaign_id, source_platform
    FROM silver.marketing_daily
    GROUP BY [date], campaign_id, source_platform
    HAVING COUNT(*) > 1
) x;

SELECT 'Duplicate Gold business grain' AS validation_check, COUNT(*) AS issue_count
FROM
(
    SELECT marketing_date, campaign_id, source_platform
    FROM gold.fact_marketing_daily
    GROUP BY marketing_date, campaign_id, source_platform
    HAVING COUNT(*) > 1
) x;

SELECT 'Silver records missing in Gold' AS validation_check, COUNT(*) AS issue_count
FROM
(
    SELECT [date], campaign_id, source_platform
    FROM silver.marketing_daily

    EXCEPT

    SELECT marketing_date, campaign_id, source_platform
    FROM gold.fact_marketing_daily
) x;

SELECT 'Extra Gold records' AS validation_check, COUNT(*) AS issue_count
FROM
(
    SELECT marketing_date, campaign_id, source_platform
    FROM gold.fact_marketing_daily

    EXCEPT

    SELECT [date], campaign_id, source_platform
    FROM silver.marketing_daily
) x;

SELECT 'Campaign mapping mismatch' AS validation_check, COUNT(*) AS issue_count
FROM gold.fact_marketing_daily f
LEFT JOIN gold.dim_campaign d
    ON f.campaign_key = d.campaign_key
WHERE ISNULL(d.campaign_id, '#MISSING#') <> f.campaign_id;

SELECT 'Date mapping mismatch' AS validation_check, COUNT(*) AS issue_count
FROM gold.fact_marketing_daily f
LEFT JOIN gold.dim_date d
    ON f.date_key = d.date_key
WHERE f.marketing_date <> ISNULL(d.[date], '19000101');

SELECT 'Measure mismatch' AS validation_check, COUNT(*) AS issue_count
FROM silver.marketing_daily s
JOIN gold.fact_marketing_daily f
    ON s.[date] = f.marketing_date
   AND s.campaign_id = f.campaign_id
   AND s.source_platform = f.source_platform
WHERE f.impressions <> s.impressions
   OR f.clicks <> s.clicks
   OR f.sessions <> s.sessions
   OR f.spend_vnd <> s.spend_vnd
   OR f.platform_leads <> s.leads_reported;
GO

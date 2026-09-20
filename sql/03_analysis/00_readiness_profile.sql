USE [SEPRO_Master_Prod];
GO
SET NOCOUNT ON;
GO

/* ============================================================
   PROJECT 1 - READINESS & DATA PROFILE

   Prerequisite:
   validate_project1_kpis.sql must PASS before business analysis.

   Core grain:
   gold.mart_lead_funnel = 1 row per lead
   ============================================================ */

-- 1. Population, grain and time coverage
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT lead_id) AS unique_leads,
    COUNT(*) - COUNT(DISTINCT lead_id) AS duplicate_leads,
    MIN(created_at) AS first_lead_created_at,
    MAX(created_at) AS last_lead_created_at
FROM gold.mart_lead_funnel;

-- 2. Critical null coverage
SELECT
    SUM(CASE WHEN campaign_key IS NULL THEN 1 ELSE 0 END) AS leads_without_campaign,
    SUM(CASE WHEN channel IS NULL THEN 1 ELSE 0 END) AS leads_without_channel,
    SUM(CASE WHEN customer_key IS NULL THEN 1 ELSE 0 END) AS leads_without_customer,
    SUM(CASE WHEN employee_key IS NULL THEN 1 ELSE 0 END) AS leads_without_assigned_employee,
    SUM(CASE WHEN first_response_hours IS NULL THEN 1 ELSE 0 END) AS leads_without_sales_activity
FROM gold.mart_lead_funnel;

-- 3. Lifecycle distribution
SELECT
    lifecycle_status,
    COUNT(*) AS lead_count,
    CAST(COUNT(*) * 1.0 / NULLIF(SUM(COUNT(*)) OVER (), 0) AS DECIMAL(12,6)) AS lead_share
FROM gold.mart_lead_funnel
GROUP BY lifecycle_status
ORDER BY lead_count DESC;

-- 4. Channel distribution
SELECT
    COALESCE(channel, 'Unattributed') AS channel,
    COUNT(*) AS lead_count,
    SUM(CAST(qualified_flag AS INT)) AS qualified_leads,
    SUM(CAST(quote_flag AS INT)) AS quoted_leads,
    SUM(CAST(order_flag AS INT)) AS ordered_leads
FROM gold.mart_lead_funnel
GROUP BY COALESCE(channel, 'Unattributed')
ORDER BY lead_count DESC;

-- 5. Response-bucket distribution
SELECT
    response_bucket,
    COUNT(*) AS lead_count,
    CAST(COUNT(*) * 1.0 / NULLIF(SUM(COUNT(*)) OVER (), 0) AS DECIMAL(12,6)) AS lead_share
FROM gold.mart_lead_funnel
GROUP BY response_bucket
ORDER BY
    CASE response_bucket
        WHEN '< 4h' THEN 1
        WHEN '4-12h' THEN 2
        WHEN '12-24h' THEN 3
        WHEN '> 24h' THEN 4
        WHEN 'No Sales Activity' THEN 5
        ELSE 6
    END;
GO

USE [SEPRO_Master_Prod];
GO
SET NOCOUNT ON;
GO

/* ============================================================
   PROJECT 1 - SALES / CHANNEL DIAGNOSTIC

   Goal:
   Avoid ranking salespeople without considering lead volume,
   channel mix and response-time distribution.

   First Successful Contact is NOT calculated automatically because
   the source documentation does not define which activity outcomes
   count as a successful contact.
   ============================================================ */

-- 1. Salesperson x Channel: volume, response and conversion context
;WITH Agg AS
(
    SELECT
        f.employee_key,
        COALESCE(f.channel, 'Unattributed') AS channel,
        COUNT(*) AS total_leads,
        SUM(CASE WHEN f.first_response_hours IS NULL THEN 1 ELSE 0 END)
            AS no_sales_activity_leads,
        SUM(CAST(f.quote_flag AS INT)) AS quoted_leads,
        SUM(CAST(f.order_flag AS INT)) AS ordered_leads
    FROM gold.mart_lead_funnel f
    GROUP BY f.employee_key, COALESCE(f.channel, 'Unattributed')
), ResponseStats AS
(
    SELECT DISTINCT
        employee_key,
        COALESCE(channel, 'Unattributed') AS channel,
        PERCENTILE_CONT(0.50)
            WITHIN GROUP (ORDER BY first_response_hours)
            OVER (PARTITION BY employee_key, COALESCE(channel, 'Unattributed'))
            AS median_first_response_hours,
        PERCENTILE_CONT(0.90)
            WITHIN GROUP (ORDER BY first_response_hours)
            OVER (PARTITION BY employee_key, COALESCE(channel, 'Unattributed'))
            AS p90_first_response_hours
    FROM gold.mart_lead_funnel
    WHERE first_response_hours IS NOT NULL
)
SELECT
    a.employee_key,
    e.employee_name,
    a.channel,
    a.total_leads,
    a.no_sales_activity_leads,
    CAST(r.median_first_response_hours AS DECIMAL(18,2)) AS median_first_response_hours,
    CAST(r.p90_first_response_hours AS DECIMAL(18,2)) AS p90_first_response_hours,
    CAST(a.quoted_leads * 1.0 / NULLIF(a.total_leads, 0) AS DECIMAL(12,6))
        AS lead_to_quote_rate,
    CAST(a.ordered_leads * 1.0 / NULLIF(a.total_leads, 0) AS DECIMAL(12,6))
        AS lead_to_order_rate
FROM Agg a
LEFT JOIN ResponseStats r
    ON (a.employee_key = r.employee_key OR (a.employee_key IS NULL AND r.employee_key IS NULL))
   AND a.channel = r.channel
LEFT JOIN gold.dim_employee e
    ON a.employee_key = e.employee_key
ORDER BY a.total_leads DESC, e.employee_name, a.channel;

-- 2. Activity outcome profile. Use this to agree a business rule
--    before defining "First Successful Contact".
SELECT
    COALESCE(outcome, 'Not recorded') AS activity_outcome,
    COUNT(*) AS activity_count,
    COUNT(DISTINCT lead_id) AS distinct_leads
FROM gold.fact_sales_activity
GROUP BY COALESCE(outcome, 'Not recorded')
ORDER BY activity_count DESC;

-- 3. Explicit limitation instead of inventing a success rule.
SELECT
    'First Successful Contact is not calculated until the business defines which sales activity outcomes count as successful.'
        AS analytical_limitation;
GO

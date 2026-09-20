USE [SEPRO_Master_Prod];
GO
SET NOCOUNT ON;
GO

/* ============================================================
   PROJECT 1 - FUNNEL ANALYSIS

   Funnel:
   Lead -> Qualified -> Quoted -> Ordered

   Important:
   mart_lead_funnel is already at 1 row per lead.
   ============================================================ */

;WITH Funnel AS
(
    SELECT
        COUNT(*) AS total_leads,
        SUM(CAST(qualified_flag AS INT)) AS qualified_leads,
        SUM(CAST(quote_flag AS INT)) AS quoted_leads,
        SUM(CAST(order_flag AS INT)) AS ordered_leads
    FROM gold.mart_lead_funnel
)
SELECT
    total_leads,
    qualified_leads,
    quoted_leads,
    ordered_leads,

    CAST(qualified_leads * 1.0 / NULLIF(total_leads, 0) AS DECIMAL(12,6))
        AS qualified_lead_rate,

    CAST(quoted_leads * 1.0 / NULLIF(total_leads, 0) AS DECIMAL(12,6))
        AS lead_to_quote_rate,

    CAST(ordered_leads * 1.0 / NULLIF(total_leads, 0) AS DECIMAL(12,6))
        AS lead_to_order_rate
FROM Funnel;

-- Stage-to-stage conversion and drop-off
;WITH Funnel AS
(
    SELECT
        COUNT(*) AS total_leads,
        SUM(CAST(qualified_flag AS INT)) AS qualified_leads,
        SUM(CAST(quote_flag AS INT)) AS quoted_leads,
        SUM(CAST(order_flag AS INT)) AS ordered_leads
    FROM gold.mart_lead_funnel
),
Stages AS
(
    SELECT *
    FROM Funnel
    CROSS APPLY
    (
        VALUES
            ('Lead -> Qualified', total_leads, qualified_leads),
            ('Qualified -> Quote', qualified_leads, quoted_leads),
            ('Quote -> Order', quoted_leads, ordered_leads)
    ) v(stage_name, previous_stage_count, next_stage_count)
)
SELECT
    stage_name,
    previous_stage_count,
    next_stage_count,
    previous_stage_count - next_stage_count AS dropoff_count,
    CAST(next_stage_count * 1.0 / NULLIF(previous_stage_count, 0) AS DECIMAL(12,6))
        AS stage_conversion_rate,
    CAST((previous_stage_count - next_stage_count) * 1.0
         / NULLIF(previous_stage_count, 0) AS DECIMAL(12,6))
        AS dropoff_rate
FROM Stages
ORDER BY dropoff_rate DESC;

-- Funnel logic check: these should be zero if stages are sequential
SELECT
    SUM(CASE WHEN quote_flag = 1 AND qualified_flag = 0 THEN 1 ELSE 0 END)
        AS quote_without_qualified,
    SUM(CASE WHEN order_flag = 1 AND quote_flag = 0 THEN 1 ELSE 0 END)
        AS order_without_quote
FROM gold.mart_lead_funnel;
GO

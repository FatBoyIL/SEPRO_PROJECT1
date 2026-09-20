USE [SEPRO_Master_Prod];
GO
SET NOCOUNT ON;
GO

/* ============================================================
   PROJECT 1 - FUNNEL LOSS REASON DIAGNOSTIC

   Principle:
   1) Identify WHERE the lead dropped in the funnel.
   2) Only then use lost_reason to investigate WHY.

   Gold mart is used for stage evidence.
   Cleaned Silver lead attributes are used only for explanatory
   lost_reason because this field is not retained in gold.fact_lead.
   ============================================================ */

DROP TABLE IF EXISTS #LossReason;

;WITH LeadStage AS
(
    SELECT
        f.lead_id,
        f.channel,
        f.employee_key,
        f.qualified_flag,
        f.quote_flag,
        f.order_flag,
        CASE
            WHEN f.qualified_flag = 0 THEN 'Lead -> Qualified'
            WHEN f.qualified_flag = 1 AND f.quote_flag = 0 THEN 'Qualified -> Quote'
            WHEN f.quote_flag = 1 AND f.order_flag = 0 THEN 'Quote -> Order'
            ELSE 'Converted'
        END AS funnel_outcome
    FROM gold.mart_lead_funnel f
)
SELECT
    s.lead_id,
    s.funnel_outcome,
    COALESCE(s.channel, 'Unattributed') AS channel,
    s.employee_key,
    COALESCE(NULLIF(LTRIM(RTRIM(l.lost_reason)), ''), 'Not recorded') AS lost_reason
INTO #LossReason
FROM LeadStage s
LEFT JOIN silver.leads l
    ON s.lead_id = l.lead_id
WHERE s.funnel_outcome <> 'Converted';

-- 1. WHY within each leakage stage
SELECT
    funnel_outcome,
    lost_reason,
    COUNT(*) AS lead_count,
    CAST(
        COUNT(*) * 1.0
        / NULLIF(SUM(COUNT(*)) OVER (PARTITION BY funnel_outcome), 0)
        AS DECIMAL(12,6)
    ) AS reason_share_within_stage
FROM #LossReason
GROUP BY funnel_outcome, lost_reason
ORDER BY
    CASE funnel_outcome
        WHEN 'Lead -> Qualified' THEN 1
        WHEN 'Qualified -> Quote' THEN 2
        WHEN 'Quote -> Order' THEN 3
        ELSE 4
    END,
    lead_count DESC;

-- 2. Channel context: the same reason can behave differently by source
SELECT
    funnel_outcome,
    channel,
    lost_reason,
    COUNT(*) AS lead_count
FROM #LossReason
GROUP BY funnel_outcome, channel, lost_reason
HAVING COUNT(*) >= 2
ORDER BY funnel_outcome, lead_count DESC;

-- 3. Salesperson context for investigation, not employee ranking
SELECT
    r.funnel_outcome,
    e.employee_name,
    r.lost_reason,
    COUNT(*) AS lead_count
FROM #LossReason r
LEFT JOIN gold.dim_employee e
    ON r.employee_key = e.employee_key
GROUP BY r.funnel_outcome, e.employee_name, r.lost_reason
ORDER BY r.funnel_outcome, lead_count DESC;

DROP TABLE IF EXISTS #LossReason;
GO

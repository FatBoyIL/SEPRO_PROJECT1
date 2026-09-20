USE [SEPRO_Master_Prod];
GO
SET NOCOUNT ON;
GO

/* ============================================================
   PROJECT 1 - DECISION-READY CONCLUSION

   Regenerates the evidence needed to explain:
   1) where the funnel leaks,
   2) why lost leads are recorded as lost,
   3) how response time is associated with conversion,
   4) channel quality trade-offs.
   ============================================================ */

-- A. Funnel stage leakage
;WITH Funnel AS
(
    SELECT
        COUNT(*) AS total_leads,
        SUM(CAST(qualified_flag AS INT)) AS qualified_leads,
        SUM(CAST(quote_flag AS INT)) AS quoted_leads,
        SUM(CAST(order_flag AS INT)) AS ordered_leads
    FROM gold.mart_lead_funnel
), Stages AS
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
    CAST((previous_stage_count - next_stage_count) * 1.0
         / NULLIF(previous_stage_count, 0) AS DECIMAL(12,6)) AS dropoff_rate
FROM Stages
ORDER BY dropoff_rate DESC;

-- B. WHERE -> WHY: lost reason by funnel leakage stage
;WITH LeadStage AS
(
    SELECT
        f.lead_id,
        CASE
            WHEN f.qualified_flag = 0 THEN 'Lead -> Qualified'
            WHEN f.qualified_flag = 1 AND f.quote_flag = 0 THEN 'Qualified -> Quote'
            WHEN f.quote_flag = 1 AND f.order_flag = 0 THEN 'Quote -> Order'
            ELSE 'Converted'
        END AS funnel_outcome
    FROM gold.mart_lead_funnel f
)
SELECT
    s.funnel_outcome,
    COALESCE(NULLIF(LTRIM(RTRIM(l.lost_reason)), ''), 'Not recorded') AS lost_reason,
    COUNT(*) AS lead_count
FROM LeadStage s
LEFT JOIN silver.leads l
    ON s.lead_id = l.lead_id
WHERE s.funnel_outcome <> 'Converted'
GROUP BY
    s.funnel_outcome,
    COALESCE(NULLIF(LTRIM(RTRIM(l.lost_reason)), ''), 'Not recorded')
ORDER BY s.funnel_outcome, lead_count DESC;

-- C. Response time association
SELECT
    response_bucket,
    total_leads,
    median_first_response_hours,
    lead_to_quote_rate,
    lead_to_order_rate
FROM gold.mart_sales_response
ORDER BY bucket_sort;

-- D. Channel quality trade-offs. No arbitrary composite winner.
;WITH ChannelAgg AS
(
    SELECT
        COALESCE(channel, 'Unattributed') AS channel,
        SUM(marketing_spend_vnd) AS marketing_spend_vnd,
        SUM(total_leads) AS total_leads,
        SUM(qualified_leads) AS qualified_leads,
        SUM(ordered_leads) AS ordered_leads,
        SUM(net_order_value_vnd) AS net_order_value_vnd
    FROM gold.mart_channel_quality
    GROUP BY COALESCE(channel, 'Unattributed')
)
SELECT
    channel,
    marketing_spend_vnd,
    total_leads,
    CAST(marketing_spend_vnd / NULLIF(CAST(total_leads AS DECIMAL(18,4)), 0)
         AS DECIMAL(18,2)) AS cpl_vnd,
    CAST(qualified_leads * 1.0 / NULLIF(total_leads, 0)
         AS DECIMAL(12,6)) AS qualified_lead_rate,
    CAST(ordered_leads * 1.0 / NULLIF(total_leads, 0)
         AS DECIMAL(12,6)) AS lead_to_order_rate,
    CAST(net_order_value_vnd / NULLIF(CAST(total_leads AS DECIMAL(18,4)), 0)
         AS DECIMAL(18,2)) AS order_value_per_lead_vnd
FROM ChannelAgg
ORDER BY total_leads DESC;

-- E. Interpretation limits
SELECT 'Response-time results are association, not causal proof.' AS limitation
UNION ALL
SELECT 'First Successful Contact requires a confirmed outcome business rule.'
UNION ALL
SELECT 'lost_reason explains WHY only after the leakage stage is established from event evidence.';
GO

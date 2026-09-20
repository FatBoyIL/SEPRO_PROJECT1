USE [SEPRO_Master_Prod];
GO
SET NOCOUNT ON;
GO

/* ============================================================
   PROJECT 1 - CHANNEL QUALITY

   Do not average daily rates.
   Recalculate rates from aggregated numerators/denominators.
   Evaluate CPL + qualification + conversion + value together.
   ============================================================ */

;WITH ChannelAgg AS
(
    SELECT
        COALESCE(channel, 'Unattributed') AS channel,
        SUM(marketing_spend_vnd) AS marketing_spend_vnd,
        SUM(total_leads) AS total_leads,
        SUM(qualified_leads) AS qualified_leads,
        SUM(quoted_leads) AS quoted_leads,
        SUM(ordered_leads) AS ordered_leads,
        SUM(net_order_value_vnd) AS net_order_value_vnd
    FROM gold.mart_channel_quality
    GROUP BY COALESCE(channel, 'Unattributed')
),
Metrics AS
(
    SELECT
        *,
        CAST(marketing_spend_vnd / NULLIF(CAST(total_leads AS DECIMAL(18,4)), 0)
             AS DECIMAL(18,2)) AS cpl_vnd,
        CAST(qualified_leads * 1.0 / NULLIF(total_leads, 0)
             AS DECIMAL(12,6)) AS qualified_lead_rate,
        CAST(quoted_leads * 1.0 / NULLIF(total_leads, 0)
             AS DECIMAL(12,6)) AS lead_to_quote_rate,
        CAST(ordered_leads * 1.0 / NULLIF(total_leads, 0)
             AS DECIMAL(12,6)) AS lead_to_order_rate,
        CAST(net_order_value_vnd / NULLIF(CAST(total_leads AS DECIMAL(18,4)), 0)
             AS DECIMAL(18,2)) AS order_value_per_lead_vnd
    FROM ChannelAgg
)
SELECT
    channel,
    marketing_spend_vnd,
    total_leads,
    qualified_leads,
    quoted_leads,
    ordered_leads,
    cpl_vnd,
    qualified_lead_rate,
    lead_to_quote_rate,
    lead_to_order_rate,
    order_value_per_lead_vnd,
    DENSE_RANK() OVER (ORDER BY cpl_vnd ASC) AS cpl_rank_low_is_better,
    DENSE_RANK() OVER (ORDER BY lead_to_order_rate DESC) AS order_conversion_rank,
    DENSE_RANK() OVER (ORDER BY order_value_per_lead_vnd DESC) AS value_per_lead_rank
FROM Metrics
ORDER BY total_leads DESC;

-- Campaign-level view
;WITH CampaignAgg AS
(
    SELECT
        campaign_id,
        campaign_name,
        channel,
        SUM(marketing_spend_vnd) AS marketing_spend_vnd,
        SUM(total_leads) AS total_leads,
        SUM(qualified_leads) AS qualified_leads,
        SUM(quoted_leads) AS quoted_leads,
        SUM(ordered_leads) AS ordered_leads,
        SUM(net_order_value_vnd) AS net_order_value_vnd
    FROM gold.mart_channel_quality
    GROUP BY campaign_id, campaign_name, channel
)
SELECT
    campaign_id,
    campaign_name,
    channel,
    marketing_spend_vnd,
    total_leads,
    CAST(marketing_spend_vnd / NULLIF(CAST(total_leads AS DECIMAL(18,4)), 0)
         AS DECIMAL(18,2)) AS cpl_vnd,
    CAST(qualified_leads * 1.0 / NULLIF(total_leads, 0)
         AS DECIMAL(12,6)) AS qualified_lead_rate,
    CAST(quoted_leads * 1.0 / NULLIF(total_leads, 0)
         AS DECIMAL(12,6)) AS lead_to_quote_rate,
    CAST(ordered_leads * 1.0 / NULLIF(total_leads, 0)
         AS DECIMAL(12,6)) AS lead_to_order_rate,
    CAST(net_order_value_vnd / NULLIF(CAST(total_leads AS DECIMAL(18,4)), 0)
         AS DECIMAL(18,2)) AS order_value_per_lead_vnd
FROM CampaignAgg
ORDER BY total_leads DESC, marketing_spend_vnd DESC;
GO

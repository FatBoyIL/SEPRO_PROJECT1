/* ============================================================
   PROJECT 1 - POWER BI HELPER QUERY
   Query name in Power BI: pbi_p1_lead_diagnostic
   Grain: 1 row = 1 lead
   Purpose: identify WHERE the lead stopped, then explain WHY.
   ============================================================ */
SELECT
    f.lead_id,
    f.campaign_key,
    f.customer_key,
    f.employee_key,
    f.created_date_key,
    f.created_at,
    f.channel,
    f.lifecycle_status,
    f.qualified_flag,
    f.quote_flag,
    f.order_flag,
    f.first_response_hours,
    f.response_bucket,
    f.net_order_value_vnd,
    CASE
        WHEN f.qualified_flag = 0 THEN 'Lead -> Qualified'
        WHEN f.quote_flag = 0 THEN 'Qualified -> Quote'
        WHEN f.order_flag = 0 THEN 'Quote -> Order'
        ELSE 'Converted'
    END AS funnel_outcome,
    l.lost_reason,
    l.budget_status,
    l.inquiry_type,
    l.company_size_band,
    l.purchase_timeline_days,
    l.product_interest_id,
    l.expected_value_vnd
FROM gold.mart_lead_funnel AS f
LEFT JOIN silver.leads AS l
    ON l.lead_id = f.lead_id;

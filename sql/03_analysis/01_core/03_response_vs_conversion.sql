USE [SEPRO_Master_Prod];
GO
SET NOCOUNT ON;
GO

/* ============================================================
   PROJECT 1 - RESPONSE TIME VS CONVERSION

   This is an association analysis.
   It does not prove faster response causes higher conversion.
   ============================================================ */

SELECT
    response_bucket,
    bucket_sort,
    total_leads,
    quoted_leads,
    ordered_leads,
    median_first_response_hours,
    CAST(lead_to_quote_rate * 100.0 AS DECIMAL(12,2)) AS lead_to_quote_pct,
    CAST(lead_to_order_rate * 100.0 AS DECIMAL(12,2)) AS lead_to_order_pct,
    CAST(total_leads * 1.0 / NULLIF(SUM(total_leads) OVER (), 0) AS DECIMAL(12,6))
        AS lead_share
FROM gold.mart_sales_response
ORDER BY bucket_sort;

-- Difference versus the <4h group, when the baseline exists
;WITH Baseline AS
(
    SELECT
        lead_to_quote_rate AS baseline_quote_rate,
        lead_to_order_rate AS baseline_order_rate
    FROM gold.mart_sales_response
    WHERE response_bucket = '< 4h'
)
SELECT
    r.response_bucket,
    r.total_leads,
    r.median_first_response_hours,
    CAST((r.lead_to_quote_rate - b.baseline_quote_rate) * 100.0 AS DECIMAL(12,2))
        AS quote_rate_gap_pp_vs_under_4h,
    CAST((r.lead_to_order_rate - b.baseline_order_rate) * 100.0 AS DECIMAL(12,2))
        AS order_rate_gap_pp_vs_under_4h
FROM gold.mart_sales_response r
CROSS JOIN Baseline b
ORDER BY r.bucket_sort;
GO

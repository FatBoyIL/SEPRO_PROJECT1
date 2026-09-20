USE [SEPRO_Master_Prod];
GO
SET NOCOUNT ON;
GO

/* ============================================================
   PROJECT 1 - RESPONSE TIME DISTRIBUTION & IQR OUTLIERS

   Do not start with average only.
   Outlier != data error.
   ============================================================ */

;WITH Base AS
(
    SELECT first_response_hours
    FROM gold.mart_lead_funnel
    WHERE first_response_hours IS NOT NULL
),
Agg AS
(
    SELECT
        COUNT(*) AS responded_leads,
        MIN(first_response_hours) AS min_hours,
        AVG(first_response_hours) AS avg_hours,
        MAX(first_response_hours) AS max_hours
    FROM Base
),
Pct AS
(
    SELECT DISTINCT
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY first_response_hours) OVER () AS p25,
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY first_response_hours) OVER () AS median,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY first_response_hours) OVER () AS p75,
        PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY first_response_hours) OVER () AS p90
    FROM Base
)
SELECT
    a.responded_leads,
    a.min_hours,
    CAST(p.p25 AS DECIMAL(18,4)) AS p25_hours,
    CAST(p.median AS DECIMAL(18,4)) AS median_hours,
    CAST(p.p75 AS DECIMAL(18,4)) AS p75_hours,
    CAST(p.p90 AS DECIMAL(18,4)) AS p90_hours,
    CAST(a.avg_hours AS DECIMAL(18,4)) AS avg_hours,
    a.max_hours,
    CAST(p.p75 - p.p25 AS DECIMAL(18,4)) AS iqr_hours,
    CAST(p.p25 - 1.5 * (p.p75 - p.p25) AS DECIMAL(18,4)) AS lower_bound,
    CAST(p.p75 + 1.5 * (p.p75 - p.p25) AS DECIMAL(18,4)) AS upper_bound
FROM Agg a
CROSS JOIN Pct p;

-- Outlier count
;WITH Base AS
(
    SELECT first_response_hours
    FROM gold.mart_lead_funnel
    WHERE first_response_hours IS NOT NULL
),
Pct AS
(
    SELECT DISTINCT
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY first_response_hours) OVER () AS p25,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY first_response_hours) OVER () AS p75
    FROM Base
),
Bounds AS
(
    SELECT
        p25 - 1.5 * (p75 - p25) AS lower_bound,
        p75 + 1.5 * (p75 - p25) AS upper_bound
    FROM Pct
)
SELECT
    COUNT(*) AS responded_leads,
    SUM(CASE
            WHEN f.first_response_hours < b.lower_bound
              OR f.first_response_hours > b.upper_bound
            THEN 1 ELSE 0
        END) AS potential_outliers,
    CAST(
        SUM(CASE
                WHEN f.first_response_hours < b.lower_bound
                  OR f.first_response_hours > b.upper_bound
                THEN 1 ELSE 0
            END) * 1.0 / NULLIF(COUNT(*), 0)
        AS DECIMAL(12,6)
    ) AS outlier_share
FROM gold.mart_lead_funnel f
CROSS JOIN Bounds b
WHERE f.first_response_hours IS NOT NULL;

-- Outlier drill-down
;WITH Base AS
(
    SELECT first_response_hours
    FROM gold.mart_lead_funnel
    WHERE first_response_hours IS NOT NULL
),
Pct AS
(
    SELECT DISTINCT
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY first_response_hours) OVER () AS p25,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY first_response_hours) OVER () AS p75
    FROM Base
),
Bounds AS
(
    SELECT
        p25 - 1.5 * (p75 - p25) AS lower_bound,
        p75 + 1.5 * (p75 - p25) AS upper_bound
    FROM Pct
)
SELECT TOP (100)
    f.lead_id,
    f.created_at,
    f.channel,
    c.customer_name,
    e.employee_name,
    f.lifecycle_status,
    f.first_response_hours,
    f.response_bucket,
    f.quote_flag,
    f.order_flag
FROM gold.mart_lead_funnel f
CROSS JOIN Bounds b
LEFT JOIN gold.dim_customer c
    ON f.customer_key = c.customer_key
LEFT JOIN gold.dim_employee e
    ON f.employee_key = e.employee_key
WHERE f.first_response_hours IS NOT NULL
  AND
  (
      f.first_response_hours < b.lower_bound
      OR f.first_response_hours > b.upper_bound
  )
ORDER BY f.first_response_hours DESC;
GO

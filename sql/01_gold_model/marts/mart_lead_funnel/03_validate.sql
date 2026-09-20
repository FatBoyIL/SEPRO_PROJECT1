USE SEPRO_Master_Prod;
GO

/* =========================================================
   PROJECT 1 - VALIDATE MART_LEAD_FUNNEL

   PASS criteria:
   - 1 row = 1 lead
   - No missing / extra leads
   - Flags match source evidence
   - First response uses the first activity
   - No negative response time
   - Order count/value reconcile to New orders
   ========================================================= */

SET NOCOUNT ON;


/* =========================================================
   1. DUPLICATE LEAD CHECK
   ========================================================= */

SELECT
    'Duplicate lead_id in mart' AS validation_check,
    COUNT(*) AS issue_count

FROM
(
    SELECT lead_id

    FROM gold.mart_lead_funnel

    GROUP BY lead_id

    HAVING COUNT(*) > 1
) x;


/* =========================================================
   2. SILVER/GOLD BASE LEADS MISSING FROM MART
   ========================================================= */

SELECT
    'fact_lead records missing in mart' AS validation_check,
    COUNT(*) AS issue_count

FROM
(
    SELECT lead_id
    FROM gold.fact_lead

    EXCEPT

    SELECT lead_id
    FROM gold.mart_lead_funnel
) x;


/* =========================================================
   3. EXTRA MART RECORDS
   ========================================================= */

SELECT
    'Extra mart records not in fact_lead' AS validation_check,
    COUNT(*) AS issue_count

FROM
(
    SELECT lead_id
    FROM gold.mart_lead_funnel

    EXCEPT

    SELECT lead_id
    FROM gold.fact_lead
) x;


/* =========================================================
   4. QUALIFIED FLAG VALIDATION
   ========================================================= */

SELECT
    'Qualified flag mismatch' AS validation_check,
    COUNT(*) AS issue_count

FROM gold.mart_lead_funnel m

WHERE m.qualified_flag <>
      CASE
          WHEN UPPER(m.lifecycle_status)
               IN ('QUALIFIED', 'QUOTED', 'WON')
          THEN 1
          ELSE 0
      END;


/* =========================================================
   5. QUOTE FLAG VALIDATION
   ========================================================= */

SELECT
    'Quote flag mismatch' AS validation_check,
    COUNT(*) AS issue_count

FROM gold.mart_lead_funnel m

LEFT JOIN
(
    SELECT
        lead_id,
        COUNT(*) AS quotation_count

    FROM gold.fact_quotation

    GROUP BY lead_id
) q
    ON m.lead_id = q.lead_id

WHERE m.quote_flag <>
      CASE
          WHEN COALESCE(q.quotation_count, 0) > 0
          THEN 1
          ELSE 0
      END;


/* =========================================================
   6. ORDER FLAG / COUNT VALIDATION

   Only order_type = New is included.
   ========================================================= */

SELECT
    'Order flag or order count mismatch' AS validation_check,
    COUNT(*) AS issue_count

FROM gold.mart_lead_funnel m

LEFT JOIN
(
    SELECT
        lead_id,
        COUNT(*) AS order_count

    FROM gold.fact_sales_order

    WHERE lead_id IS NOT NULL
      AND UPPER(order_type) = 'NEW'

    GROUP BY lead_id
) o
    ON m.lead_id = o.lead_id

WHERE m.order_count <> COALESCE(o.order_count, 0)

   OR m.order_flag <>
      CASE
          WHEN COALESCE(o.order_count, 0) > 0
          THEN 1
          ELSE 0
      END;


/* =========================================================
   7. FIRST RESPONSE VALIDATION
   ========================================================= */

SELECT
    'First response hours mismatch' AS validation_check,
    COUNT(*) AS issue_count

FROM gold.mart_lead_funnel m

LEFT JOIN
(
    SELECT
        lead_id,
        MIN(activity_datetime) AS first_activity_datetime

    FROM gold.fact_sales_activity

    GROUP BY lead_id
) a
    ON m.lead_id = a.lead_id

WHERE
(
    a.first_activity_datetime IS NULL
    AND m.first_response_hours IS NOT NULL
)

OR
(
    a.first_activity_datetime IS NOT NULL
    AND
    ABS
    (
        m.first_response_hours
        -
        CAST
        (
            DATEDIFF
            (
                MINUTE,
                m.created_at,
                a.first_activity_datetime
            ) / 60.0

            AS DECIMAL(10,2)
        )
    ) > 0.01
);


/* =========================================================
   8. NEGATIVE FIRST RESPONSE CHECK
   ========================================================= */

SELECT
    'Negative first response hours' AS validation_check,
    COUNT(*) AS issue_count

FROM gold.mart_lead_funnel

WHERE first_response_hours < 0;


/* =========================================================
   9. NET ORDER VALUE VALIDATION
   ========================================================= */

;WITH OrderLineAgg AS
(
    SELECT
        sales_order_id,

        SUM
        (
            CAST(quantity_ordered AS DECIMAL(18,2))
            * unit_price_vnd
            * (1 - discount_pct)
        ) AS net_order_value_vnd

    FROM gold.fact_sales_order_line

    GROUP BY sales_order_id
),

LeadOrderValue AS
(
    SELECT
        o.lead_id,

        SUM
        (
            COALESCE(ol.net_order_value_vnd, 0)
        ) AS net_order_value_vnd

    FROM gold.fact_sales_order o

    LEFT JOIN OrderLineAgg ol
        ON o.sales_order_id = ol.sales_order_id

    WHERE o.lead_id IS NOT NULL
      AND UPPER(o.order_type) = 'NEW'

    GROUP BY o.lead_id
)

SELECT
    'Net order value mismatch' AS validation_check,
    COUNT(*) AS issue_count

FROM gold.mart_lead_funnel m

LEFT JOIN LeadOrderValue o
    ON m.lead_id = o.lead_id

WHERE ABS
(
    m.net_order_value_vnd
    -
    COALESCE(o.net_order_value_vnd, 0)
) > 0.01;


/* =========================================================
   10. CHANNEL MAPPING VALIDATION
   ========================================================= */

SELECT
    'Channel mapping mismatch' AS validation_check,
    COUNT(*) AS issue_count

FROM gold.mart_lead_funnel m

LEFT JOIN gold.dim_campaign c
    ON m.campaign_key = c.campaign_key

WHERE ISNULL(m.channel, '#NULL#')
      <>
      ISNULL(c.channel, '#NULL#');


/* =========================================================
   FINAL QUICK SUMMARY

   Every query above should return issue_count = 0.
   ========================================================= */
GO

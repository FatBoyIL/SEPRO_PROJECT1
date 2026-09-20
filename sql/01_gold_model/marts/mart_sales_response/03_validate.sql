USE SEPRO_Master_Prod;
GO

/* =========================================================
   PROJECT 1 - VALIDATE MART_SALES_RESPONSE

   PASS criteria:
   - 1 row = 1 response bucket
   - All leads reconcile to mart_lead_funnel
   - Quote / Order counts reconcile
   - Conversion rates reconcile
   - Median first response reconciles
   - No Sales Activity keeps NULL median
   - No negative first response exists
   ========================================================= */

SET NOCOUNT ON;


IF OBJECT_ID('tempdb..#Expected') IS NOT NULL
    DROP TABLE #Expected;

IF OBJECT_ID('tempdb..#ValidationResults') IS NOT NULL
    DROP TABLE #ValidationResults;


/* =========================================================
   BUILD EXPECTED RESULT FROM MART_LEAD_FUNNEL
   ========================================================= */

;WITH BucketAgg AS
(
    SELECT
        response_bucket,

        COUNT(*) AS total_leads,

        SUM(CAST(quote_flag AS INT))
            AS quoted_leads,

        SUM(CAST(order_flag AS INT))
            AS ordered_leads

    FROM gold.mart_lead_funnel

    GROUP BY response_bucket
),

MedianAgg AS
(
    SELECT DISTINCT
        response_bucket,

        CAST
        (
            PERCENTILE_CONT(0.5)
            WITHIN GROUP
            (
                ORDER BY first_response_hours
            )
            OVER
            (
                PARTITION BY response_bucket
            )

            AS DECIMAL(10,2)
        ) AS median_first_response_hours

    FROM gold.mart_lead_funnel

    WHERE first_response_hours IS NOT NULL
)

SELECT
    b.response_bucket,

    CASE b.response_bucket
        WHEN '< 4h' THEN 1
        WHEN '4-12h' THEN 2
        WHEN '12-24h' THEN 3
        WHEN '> 24h' THEN 4
        WHEN 'No Sales Activity' THEN 5
        ELSE 99
    END AS bucket_sort,

    b.total_leads,
    b.quoted_leads,
    b.ordered_leads,

    m.median_first_response_hours,

    CASE
        WHEN b.total_leads = 0
        THEN NULL
        ELSE CAST
        (
            CAST(b.quoted_leads AS DECIMAL(18,4))
            / b.total_leads

            AS DECIMAL(10,4)
        )
    END AS lead_to_quote_rate,

    CASE
        WHEN b.total_leads = 0
        THEN NULL
        ELSE CAST
        (
            CAST(b.ordered_leads AS DECIMAL(18,4))
            / b.total_leads

            AS DECIMAL(10,4)
        )
    END AS lead_to_order_rate

INTO #Expected

FROM BucketAgg b

LEFT JOIN MedianAgg m
    ON b.response_bucket = m.response_bucket;


CREATE TABLE #ValidationResults
(
    validation_check  NVARCHAR(255),
    issue_count       BIGINT,
    [status]          VARCHAR(10)
);


/* =========================================================
   1. DUPLICATE RESPONSE BUCKET
   ========================================================= */

INSERT INTO #ValidationResults

SELECT
    'Duplicate response bucket',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END

FROM
(
    SELECT response_bucket

    FROM gold.mart_sales_response

    GROUP BY response_bucket

    HAVING COUNT(*) > 1
) x;


/* =========================================================
   2. EXPECTED BUCKET MISSING
   ========================================================= */

INSERT INTO #ValidationResults

SELECT
    'Expected response bucket missing from mart',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END

FROM
(
    SELECT response_bucket
    FROM #Expected

    EXCEPT

    SELECT response_bucket
    FROM gold.mart_sales_response
) x;


/* =========================================================
   3. EXTRA MART BUCKET
   ========================================================= */

INSERT INTO #ValidationResults

SELECT
    'Extra response bucket in mart',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END

FROM
(
    SELECT response_bucket
    FROM gold.mart_sales_response

    EXCEPT

    SELECT response_bucket
    FROM #Expected
) x;


/* =========================================================
   4. LEAD COUNTS RECONCILIATION
   ========================================================= */

INSERT INTO #ValidationResults

SELECT
    'Lead / Quote / Order count mismatch',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END

FROM gold.mart_sales_response m

INNER JOIN #Expected e
    ON m.response_bucket = e.response_bucket

WHERE m.total_leads <> e.total_leads
   OR m.quoted_leads <> e.quoted_leads
   OR m.ordered_leads <> e.ordered_leads;


/* =========================================================
   5. MEDIAN RESPONSE VALIDATION
   ========================================================= */

INSERT INTO #ValidationResults

SELECT
    'Median first response mismatch',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END

FROM gold.mart_sales_response m

INNER JOIN #Expected e
    ON m.response_bucket = e.response_bucket

WHERE
    (
        m.median_first_response_hours IS NULL
        AND e.median_first_response_hours IS NOT NULL
    )

    OR

    (
        m.median_first_response_hours IS NOT NULL
        AND e.median_first_response_hours IS NULL
    )

    OR

    (
        m.median_first_response_hours IS NOT NULL
        AND e.median_first_response_hours IS NOT NULL
        AND ABS
            (
                m.median_first_response_hours
                -
                e.median_first_response_hours
            ) > 0.01
    );


/* =========================================================
   6. CONVERSION RATE VALIDATION
   ========================================================= */

INSERT INTO #ValidationResults

SELECT
    'Lead-to-Quote or Lead-to-Order rate mismatch',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END

FROM gold.mart_sales_response m

INNER JOIN #Expected e
    ON m.response_bucket = e.response_bucket

WHERE
    ABS
    (
        COALESCE(m.lead_to_quote_rate, -1)
        -
        COALESCE(e.lead_to_quote_rate, -1)
    ) > 0.0001

    OR

    ABS
    (
        COALESCE(m.lead_to_order_rate, -1)
        -
        COALESCE(e.lead_to_order_rate, -1)
    ) > 0.0001;


/* =========================================================
   7. TOTAL LEADS RECONCILIATION
   ========================================================= */

INSERT INTO #ValidationResults

SELECT
    'Total lead count mismatch',
    CASE
        WHEN
        (
            SELECT COUNT(*)
            FROM gold.mart_lead_funnel
        )
        =
        (
            SELECT COALESCE(SUM(total_leads), 0)
            FROM gold.mart_sales_response
        )
        THEN 0
        ELSE 1
    END,

    CASE
        WHEN
        (
            SELECT COUNT(*)
            FROM gold.mart_lead_funnel
        )
        =
        (
            SELECT COALESCE(SUM(total_leads), 0)
            FROM gold.mart_sales_response
        )
        THEN 'PASS'
        ELSE 'FAIL'
    END;


/* =========================================================
   8. NO SALES ACTIVITY MUST NOT BECOME ZERO HOURS
   ========================================================= */

INSERT INTO #ValidationResults

SELECT
    'No Sales Activity has non-NULL median',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END

FROM gold.mart_sales_response

WHERE response_bucket = 'No Sales Activity'
  AND median_first_response_hours IS NOT NULL;


/* =========================================================
   9. NEGATIVE FIRST RESPONSE CHECK
   ========================================================= */

INSERT INTO #ValidationResults

SELECT
    'Negative first response hours in lead funnel',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END

FROM gold.mart_lead_funnel

WHERE first_response_hours < 0;


/* =========================================================
   10. BUCKET SORT VALIDATION
   ========================================================= */

INSERT INTO #ValidationResults

SELECT
    'Response bucket sort mismatch',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END

FROM gold.mart_sales_response

WHERE bucket_sort <>
      CASE response_bucket
          WHEN '< 4h' THEN 1
          WHEN '4-12h' THEN 2
          WHEN '12-24h' THEN 3
          WHEN '> 24h' THEN 4
          WHEN 'No Sales Activity' THEN 5
          ELSE 99
      END;


/* =========================================================
   FINAL RESULT
   ========================================================= */

SELECT
    validation_check,
    issue_count,
    [status]

FROM #ValidationResults

ORDER BY
    CASE WHEN [status] = 'FAIL' THEN 0 ELSE 1 END,
    validation_check;


SELECT
    SUM(CASE WHEN [status] = 'FAIL' THEN 1 ELSE 0 END)
        AS failed_checks,

    SUM(CASE WHEN [status] = 'PASS' THEN 1 ELSE 0 END)
        AS passed_checks,

    CASE
        WHEN SUM(CASE WHEN [status] = 'FAIL' THEN 1 ELSE 0 END) = 0
        THEN 'PASS - MART_SALES_RESPONSE VALIDATED'

        ELSE 'FAIL - REVIEW FAILED CHECKS'
    END AS overall_status

FROM #ValidationResults;
GO

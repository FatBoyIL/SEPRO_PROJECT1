USE SEPRO_Master_Prod;
GO

/* =========================================================
   PROJECT 1 - VALIDATE MART_CHANNEL_QUALITY

   PASS criteria:
   - 1 row = 1 date + campaign
   - No missing expected grain
   - No extra rows
   - Lead counts reconcile
   - Marketing spend reconciles
   - KPI formulas reconcile
   - Campaign/channel mapping is correct
   ========================================================= */

SET NOCOUNT ON;


/* =========================================================
   PREPARE EXPECTED AGGREGATES
   ========================================================= */

IF OBJECT_ID('tempdb..#LeadAgg') IS NOT NULL
    DROP TABLE #LeadAgg;

IF OBJECT_ID('tempdb..#MarketingAgg') IS NOT NULL
    DROP TABLE #MarketingAgg;

IF OBJECT_ID('tempdb..#ExpectedKeys') IS NOT NULL
    DROP TABLE #ExpectedKeys;

IF OBJECT_ID('tempdb..#ValidationResults') IS NOT NULL
    DROP TABLE #ValidationResults;


SELECT
    created_date_key AS date_key,
    campaign_key,

    COUNT(*) AS total_leads,

    SUM(CAST(qualified_flag AS INT))
        AS qualified_leads,

    SUM(CAST(quote_flag AS INT))
        AS quoted_leads,

    SUM(CAST(order_flag AS INT))
        AS ordered_leads,

    SUM(net_order_value_vnd)
        AS net_order_value_vnd

INTO #LeadAgg

FROM gold.mart_lead_funnel

WHERE created_date_key IS NOT NULL
  AND campaign_key IS NOT NULL

GROUP BY
    created_date_key,
    campaign_key;


SELECT
    date_key,
    campaign_key,

    SUM(spend_vnd)
        AS marketing_spend_vnd

INTO #MarketingAgg

FROM gold.fact_marketing_daily

WHERE date_key IS NOT NULL
  AND campaign_key IS NOT NULL

GROUP BY
    date_key,
    campaign_key;


SELECT
    date_key,
    campaign_key

INTO #ExpectedKeys

FROM
(
    SELECT
        date_key,
        campaign_key
    FROM #LeadAgg

    UNION

    SELECT
        date_key,
        campaign_key
    FROM #MarketingAgg
) x;


CREATE TABLE #ValidationResults
(
    validation_check  NVARCHAR(255),
    issue_count       BIGINT,
    [status]          VARCHAR(10)
);


/* =========================================================
   1. DUPLICATE MART GRAIN
   ========================================================= */

INSERT INTO #ValidationResults

SELECT
    'Duplicate mart date + campaign grain',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END

FROM
(
    SELECT
        date_key,
        campaign_key

    FROM gold.mart_channel_quality

    GROUP BY
        date_key,
        campaign_key

    HAVING COUNT(*) > 1
) x;


/* =========================================================
   2. EXPECTED ROWS MISSING FROM MART
   ========================================================= */

INSERT INTO #ValidationResults

SELECT
    'Expected date + campaign rows missing from mart',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END

FROM
(
    SELECT
        date_key,
        campaign_key
    FROM #ExpectedKeys

    EXCEPT

    SELECT
        date_key,
        campaign_key
    FROM gold.mart_channel_quality
) x;


/* =========================================================
   3. EXTRA MART ROWS
   ========================================================= */

INSERT INTO #ValidationResults

SELECT
    'Extra mart rows not found in source aggregates',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END

FROM
(
    SELECT
        date_key,
        campaign_key
    FROM gold.mart_channel_quality

    EXCEPT

    SELECT
        date_key,
        campaign_key
    FROM #ExpectedKeys
) x;


/* =========================================================
   4. LEAD MEASURE RECONCILIATION
   ========================================================= */

INSERT INTO #ValidationResults

SELECT
    'Lead counts or order value mismatch',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END

FROM gold.mart_channel_quality m

LEFT JOIN #LeadAgg l
    ON m.date_key = l.date_key
   AND m.campaign_key = l.campaign_key

WHERE m.total_leads
      <> COALESCE(l.total_leads, 0)

   OR m.qualified_leads
      <> COALESCE(l.qualified_leads, 0)

   OR m.quoted_leads
      <> COALESCE(l.quoted_leads, 0)

   OR m.ordered_leads
      <> COALESCE(l.ordered_leads, 0)

   OR ABS
      (
          m.net_order_value_vnd
          -
          COALESCE(l.net_order_value_vnd, 0)
      ) > 0.01;


/* =========================================================
   5. MARKETING SPEND RECONCILIATION
   ========================================================= */

INSERT INTO #ValidationResults

SELECT
    'Marketing spend mismatch',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END

FROM gold.mart_channel_quality m

LEFT JOIN #MarketingAgg a
    ON m.date_key = a.date_key
   AND m.campaign_key = a.campaign_key

WHERE ABS
      (
          m.marketing_spend_vnd
          -
          COALESCE(a.marketing_spend_vnd, 0)
      ) > 0.01;


/* =========================================================
   6. CAMPAIGN / CHANNEL MAPPING
   ========================================================= */

INSERT INTO #ValidationResults

SELECT
    'Campaign or channel mapping mismatch',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END

FROM gold.mart_channel_quality m

LEFT JOIN gold.dim_campaign c
    ON m.campaign_key = c.campaign_key

WHERE ISNULL(m.campaign_id, '#NULL#')
      <>
      ISNULL(c.campaign_id, '#NULL#')

   OR ISNULL(m.campaign_name, '#NULL#')
      <>
      ISNULL(c.campaign_name, '#NULL#')

   OR ISNULL(m.channel, '#NULL#')
      <>
      ISNULL(c.channel, '#NULL#');


/* =========================================================
   7. DATE MAPPING
   ========================================================= */

INSERT INTO #ValidationResults

SELECT
    'Date mapping mismatch',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END

FROM gold.mart_channel_quality m

LEFT JOIN gold.dim_date d
    ON m.date_key = d.date_key

WHERE m.analysis_date
      <>
      ISNULL(d.[date], '19000101');


/* =========================================================
   8. KPI FORMULA VALIDATION
   ========================================================= */

INSERT INTO #ValidationResults

SELECT
    'KPI formula mismatch',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END

FROM gold.mart_channel_quality m

WHERE

    /* If there are no CRM leads, denominator-based KPI = NULL. */

    (
        m.total_leads = 0

        AND
        (
            m.cpl_vnd IS NOT NULL
            OR m.qualified_lead_rate IS NOT NULL
            OR m.lead_to_quote_rate IS NOT NULL
            OR m.lead_to_order_rate IS NOT NULL
            OR m.order_value_per_lead_vnd IS NOT NULL
        )
    )

    OR

    /* Recalculate all denominator-based KPI. */

    (
        m.total_leads > 0

        AND
        (
            ABS
            (
                m.cpl_vnd
                -
                CAST
                (
                    m.marketing_spend_vnd
                    / CAST(m.total_leads AS DECIMAL(18,4))

                    AS DECIMAL(18,2)
                )
            ) > 0.01

            OR ABS
            (
                m.qualified_lead_rate
                -
                CAST
                (
                    CAST(m.qualified_leads AS DECIMAL(18,4))
                    / m.total_leads

                    AS DECIMAL(10,4)
                )
            ) > 0.0001

            OR ABS
            (
                m.lead_to_quote_rate
                -
                CAST
                (
                    CAST(m.quoted_leads AS DECIMAL(18,4))
                    / m.total_leads

                    AS DECIMAL(10,4)
                )
            ) > 0.0001

            OR ABS
            (
                m.lead_to_order_rate
                -
                CAST
                (
                    CAST(m.ordered_leads AS DECIMAL(18,4))
                    / m.total_leads

                    AS DECIMAL(10,4)
                )
            ) > 0.0001

            OR ABS
            (
                m.order_value_per_lead_vnd
                -
                CAST
                (
                    m.net_order_value_vnd
                    / CAST(m.total_leads AS DECIMAL(18,4))

                    AS DECIMAL(18,2)
                )
            ) > 0.01
        )
    );


/* =========================================================
   9. TOTAL ATTRIBUTABLE LEADS RECONCILIATION
   ========================================================= */

INSERT INTO #ValidationResults

SELECT
    'Total attributable leads mismatch',
    CASE
        WHEN
        (
            SELECT COUNT(*)
            FROM gold.mart_lead_funnel
            WHERE created_date_key IS NOT NULL
              AND campaign_key IS NOT NULL
        )
        =
        (
            SELECT SUM(total_leads)
            FROM gold.mart_channel_quality
        )
        THEN 0
        ELSE 1
    END,
    CASE
        WHEN
        (
            SELECT COUNT(*)
            FROM gold.mart_lead_funnel
            WHERE created_date_key IS NOT NULL
              AND campaign_key IS NOT NULL
        )
        =
        (
            SELECT SUM(total_leads)
            FROM gold.mart_channel_quality
        )
        THEN 'PASS'
        ELSE 'FAIL'
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
        THEN 'PASS - MART_CHANNEL_QUALITY VALIDATED'

        ELSE 'FAIL - REVIEW FAILED CHECKS'
    END AS overall_status

FROM #ValidationResults;
GO

USE SEPRO_Master_Prod;
GO

/* =========================================================
   SEPRO DATA ANALYST PORTFOLIO
   PROJECT 1 - KPI VALIDATION

   Purpose:
   Validate Project 1 KPI logic before Power BI.

   KPI scope:
   - Total Leads
   - Qualified Lead Rate
   - Lead-to-Quote Rate
   - Lead-to-Order Rate
   - CPL
   - Order Value per Lead
   - Median First Response Hours

   Important:
   - Lead grain = 1 row per lead
   - Quote conversion uses distinct lead evidence
   - Order conversion uses distinct lead evidence
   - New orders are used for first Lead-to-Order conversion
   - No Sales Activity is not converted to 0 hours
   ========================================================= */

SET NOCOUNT ON;


/* =========================================================
   CREATE VALIDATION RESULT TABLE
   ========================================================= */

IF OBJECT_ID('tempdb..#ValidationResults') IS NOT NULL
    DROP TABLE #ValidationResults;

CREATE TABLE #ValidationResults
(
    validation_group  NVARCHAR(100),
    validation_check  NVARCHAR(255),
    expected_value    DECIMAL(38,6) NULL,
    actual_value      DECIMAL(38,6) NULL,
    difference_value  DECIMAL(38,6) NULL,
    [status]          VARCHAR(10)
);


/* =========================================================
   1. TOTAL LEADS

   fact_lead is the source-of-truth lead grain.
   mart_lead_funnel must contain exactly the same leads.
   ========================================================= */

DECLARE @FactLeadCount BIGINT;
DECLARE @MartLeadCount BIGINT;

SELECT
    @FactLeadCount = COUNT(*)
FROM gold.fact_lead;

SELECT
    @MartLeadCount = COUNT(*)
FROM gold.mart_lead_funnel;


INSERT INTO #ValidationResults
SELECT
    'Funnel KPI',
    'Total Leads: fact_lead vs mart_lead_funnel',
    @FactLeadCount,
    @MartLeadCount,
    @MartLeadCount - @FactLeadCount,
    CASE
        WHEN @FactLeadCount = @MartLeadCount
        THEN 'PASS'
        ELSE 'FAIL'
    END;


/* =========================================================
   2. QUALIFIED LEADS

   Rule:
   Qualified / Quoted / Won = qualified_flag 1
   ========================================================= */

DECLARE @ExpectedQualified BIGINT;
DECLARE @ActualQualified BIGINT;

SELECT
    @ExpectedQualified =
        SUM
        (
            CASE
                WHEN UPPER(lifecycle_status)
                     IN ('QUALIFIED', 'QUOTED', 'WON')
                THEN 1
                ELSE 0
            END
        )
FROM gold.fact_lead;


SELECT
    @ActualQualified =
        SUM(CAST(qualified_flag AS INT))
FROM gold.mart_lead_funnel;


INSERT INTO #ValidationResults
SELECT
    'Funnel KPI',
    'Qualified Leads',
    @ExpectedQualified,
    @ActualQualified,
    @ActualQualified - @ExpectedQualified,
    CASE
        WHEN @ExpectedQualified = @ActualQualified
        THEN 'PASS'
        ELSE 'FAIL'
    END;


/* =========================================================
   3. QUOTED LEADS

   Quote evidence comes from fact_quotation.
   Count distinct lead_id, not quotation rows.
   ========================================================= */

DECLARE @ExpectedQuoted BIGINT;
DECLARE @ActualQuoted BIGINT;

SELECT
    @ExpectedQuoted = COUNT(*)
FROM
(
    SELECT DISTINCT q.lead_id

    FROM gold.fact_quotation q

    INNER JOIN gold.fact_lead l
        ON q.lead_id = l.lead_id

    WHERE q.lead_id IS NOT NULL
) x;


SELECT
    @ActualQuoted =
        SUM(CAST(quote_flag AS INT))
FROM gold.mart_lead_funnel;


INSERT INTO #ValidationResults
SELECT
    'Funnel KPI',
    'Quoted Leads: distinct lead evidence',
    @ExpectedQuoted,
    @ActualQuoted,
    @ActualQuoted - @ExpectedQuoted,
    CASE
        WHEN @ExpectedQuoted = @ActualQuoted
        THEN 'PASS'
        ELSE 'FAIL'
    END;


/* =========================================================
   4. ORDERED LEADS

   First Lead-to-Order conversion uses order_type = New.
   Count distinct lead_id, not number of Sales Orders.
   ========================================================= */

DECLARE @ExpectedOrdered BIGINT;
DECLARE @ActualOrdered BIGINT;

SELECT
    @ExpectedOrdered = COUNT(*)
FROM
(
    SELECT DISTINCT o.lead_id

    FROM gold.fact_sales_order o

    INNER JOIN gold.fact_lead l
        ON o.lead_id = l.lead_id

    WHERE o.lead_id IS NOT NULL
      AND UPPER(o.order_type) = 'NEW'
) x;


SELECT
    @ActualOrdered =
        SUM(CAST(order_flag AS INT))
FROM gold.mart_lead_funnel;


INSERT INTO #ValidationResults
SELECT
    'Funnel KPI',
    'Ordered Leads: distinct New-order lead evidence',
    @ExpectedOrdered,
    @ActualOrdered,
    @ActualOrdered - @ExpectedOrdered,
    CASE
        WHEN @ExpectedOrdered = @ActualOrdered
        THEN 'PASS'
        ELSE 'FAIL'
    END;


/* =========================================================
   5. QUALIFIED LEAD RATE
   ========================================================= */

DECLARE @ExpectedQualifiedRate DECIMAL(18,6);
DECLARE @ActualQualifiedRate DECIMAL(18,6);

SET @ExpectedQualifiedRate =
    CAST(@ExpectedQualified AS DECIMAL(18,6))
    / NULLIF(@FactLeadCount, 0);

SET @ActualQualifiedRate =
    CAST(@ActualQualified AS DECIMAL(18,6))
    / NULLIF(@MartLeadCount, 0);


INSERT INTO #ValidationResults
SELECT
    'Rate KPI',
    'Qualified Lead Rate',
    @ExpectedQualifiedRate,
    @ActualQualifiedRate,
    @ActualQualifiedRate - @ExpectedQualifiedRate,
    CASE
        WHEN ABS
             (
                 COALESCE(@ActualQualifiedRate, -1)
                 -
                 COALESCE(@ExpectedQualifiedRate, -1)
             ) <= 0.000001
        THEN 'PASS'
        ELSE 'FAIL'
    END;


/* =========================================================
   6. LEAD-TO-QUOTE RATE
   ========================================================= */

DECLARE @ExpectedLeadToQuoteRate DECIMAL(18,6);
DECLARE @ActualLeadToQuoteRate DECIMAL(18,6);

SET @ExpectedLeadToQuoteRate =
    CAST(@ExpectedQuoted AS DECIMAL(18,6))
    / NULLIF(@FactLeadCount, 0);

SET @ActualLeadToQuoteRate =
    CAST(@ActualQuoted AS DECIMAL(18,6))
    / NULLIF(@MartLeadCount, 0);


INSERT INTO #ValidationResults
SELECT
    'Rate KPI',
    'Lead-to-Quote Rate',
    @ExpectedLeadToQuoteRate,
    @ActualLeadToQuoteRate,
    @ActualLeadToQuoteRate - @ExpectedLeadToQuoteRate,
    CASE
        WHEN ABS
             (
                 COALESCE(@ActualLeadToQuoteRate, -1)
                 -
                 COALESCE(@ExpectedLeadToQuoteRate, -1)
             ) <= 0.000001
        THEN 'PASS'
        ELSE 'FAIL'
    END;


/* =========================================================
   7. LEAD-TO-ORDER RATE
   ========================================================= */

DECLARE @ExpectedLeadToOrderRate DECIMAL(18,6);
DECLARE @ActualLeadToOrderRate DECIMAL(18,6);

SET @ExpectedLeadToOrderRate =
    CAST(@ExpectedOrdered AS DECIMAL(18,6))
    / NULLIF(@FactLeadCount, 0);

SET @ActualLeadToOrderRate =
    CAST(@ActualOrdered AS DECIMAL(18,6))
    / NULLIF(@MartLeadCount, 0);


INSERT INTO #ValidationResults
SELECT
    'Rate KPI',
    'Lead-to-Order Rate',
    @ExpectedLeadToOrderRate,
    @ActualLeadToOrderRate,
    @ActualLeadToOrderRate - @ExpectedLeadToOrderRate,
    CASE
        WHEN ABS
             (
                 COALESCE(@ActualLeadToOrderRate, -1)
                 -
                 COALESCE(@ExpectedLeadToOrderRate, -1)
             ) <= 0.000001
        THEN 'PASS'
        ELSE 'FAIL'
    END;


/* =========================================================
   8. CHANNEL-ATTRIBUTABLE LEADS

   mart_channel_quality only uses leads that have:
   - created_date_key
   - campaign_key

   Therefore reconciliation must use the same population.
   ========================================================= */

DECLARE @ExpectedAttributedLeads BIGINT;
DECLARE @ActualAttributedLeads BIGINT;

SELECT
    @ExpectedAttributedLeads = COUNT(*)
FROM gold.mart_lead_funnel
WHERE created_date_key IS NOT NULL
  AND campaign_key IS NOT NULL;


SELECT
    @ActualAttributedLeads =
        COALESCE(SUM(total_leads), 0)
FROM gold.mart_channel_quality;


INSERT INTO #ValidationResults
SELECT
    'Channel KPI',
    'Attributable Leads',
    @ExpectedAttributedLeads,
    @ActualAttributedLeads,
    @ActualAttributedLeads - @ExpectedAttributedLeads,
    CASE
        WHEN @ExpectedAttributedLeads = @ActualAttributedLeads
        THEN 'PASS'
        ELSE 'FAIL'
    END;


/* =========================================================
   9. MARKETING SPEND

   Reconcile only marketing rows with mapped date/campaign,
   because mart_channel_quality uses the same scope.
   ========================================================= */

DECLARE @ExpectedMarketingSpend DECIMAL(38,6);
DECLARE @ActualMarketingSpend DECIMAL(38,6);

SELECT
    @ExpectedMarketingSpend =
        COALESCE(SUM(spend_vnd), 0)
FROM gold.fact_marketing_daily
WHERE date_key IS NOT NULL
  AND campaign_key IS NOT NULL;


SELECT
    @ActualMarketingSpend =
        COALESCE(SUM(marketing_spend_vnd), 0)
FROM gold.mart_channel_quality;


INSERT INTO #ValidationResults
SELECT
    'Channel KPI',
    'Marketing Spend',
    @ExpectedMarketingSpend,
    @ActualMarketingSpend,
    @ActualMarketingSpend - @ExpectedMarketingSpend,
    CASE
        WHEN ABS(@ActualMarketingSpend - @ExpectedMarketingSpend) <= 0.01
        THEN 'PASS'
        ELSE 'FAIL'
    END;


/* =========================================================
   10. CPL

   CPL = Marketing Spend / CRM Leads

   Here CPL is campaign-attributable CPL because only leads
   with date + campaign can be reconciled to marketing spend.
   ========================================================= */

DECLARE @ExpectedCPL DECIMAL(38,6);
DECLARE @ActualCPL DECIMAL(38,6);

SET @ExpectedCPL =
    @ExpectedMarketingSpend
    / NULLIF(CAST(@ExpectedAttributedLeads AS DECIMAL(38,6)), 0);

SET @ActualCPL =
    @ActualMarketingSpend
    / NULLIF(CAST(@ActualAttributedLeads AS DECIMAL(38,6)), 0);


INSERT INTO #ValidationResults
SELECT
    'Channel KPI',
    'Campaign-attributable CPL',
    @ExpectedCPL,
    @ActualCPL,
    @ActualCPL - @ExpectedCPL,
    CASE
        WHEN ABS
             (
                 COALESCE(@ActualCPL, -1)
                 -
                 COALESCE(@ExpectedCPL, -1)
             ) <= 0.01
        THEN 'PASS'
        ELSE 'FAIL'
    END;


/* =========================================================
   11. ORDER VALUE PER LEAD

   Reconcile mart_channel_quality against mart_lead_funnel.
   The detailed Sales Order line calculation was validated
   earlier in mart_lead_funnel validation.
   ========================================================= */

DECLARE @ExpectedAttributedOrderValue DECIMAL(38,6);
DECLARE @ActualAttributedOrderValue DECIMAL(38,6);

SELECT
    @ExpectedAttributedOrderValue =
        COALESCE(SUM(net_order_value_vnd), 0)
FROM gold.mart_lead_funnel
WHERE created_date_key IS NOT NULL
  AND campaign_key IS NOT NULL;


SELECT
    @ActualAttributedOrderValue =
        COALESCE(SUM(net_order_value_vnd), 0)
FROM gold.mart_channel_quality;


INSERT INTO #ValidationResults
SELECT
    'Channel KPI',
    'Attributed Net Order Value',
    @ExpectedAttributedOrderValue,
    @ActualAttributedOrderValue,
    @ActualAttributedOrderValue - @ExpectedAttributedOrderValue,
    CASE
        WHEN ABS
             (
                 @ActualAttributedOrderValue
                 -
                 @ExpectedAttributedOrderValue
             ) <= 0.01
        THEN 'PASS'
        ELSE 'FAIL'
    END;


DECLARE @ExpectedOrderValuePerLead DECIMAL(38,6);
DECLARE @ActualOrderValuePerLead DECIMAL(38,6);

SET @ExpectedOrderValuePerLead =
    @ExpectedAttributedOrderValue
    / NULLIF(CAST(@ExpectedAttributedLeads AS DECIMAL(38,6)), 0);

SET @ActualOrderValuePerLead =
    @ActualAttributedOrderValue
    / NULLIF(CAST(@ActualAttributedLeads AS DECIMAL(38,6)), 0);


INSERT INTO #ValidationResults
SELECT
    'Channel KPI',
    'Order Value per Lead',
    @ExpectedOrderValuePerLead,
    @ActualOrderValuePerLead,
    @ActualOrderValuePerLead - @ExpectedOrderValuePerLead,
    CASE
        WHEN ABS
             (
                 COALESCE(@ActualOrderValuePerLead, -1)
                 -
                 COALESCE(@ExpectedOrderValuePerLead, -1)
             ) <= 0.01
        THEN 'PASS'
        ELSE 'FAIL'
    END;


/* =========================================================
   12. SALES RESPONSE TOTAL LEADS

   Sum of response buckets must equal all leads.
   ========================================================= */

DECLARE @ResponseMartLeadCount BIGINT;

SELECT
    @ResponseMartLeadCount =
        COALESCE(SUM(total_leads), 0)
FROM gold.mart_sales_response;


INSERT INTO #ValidationResults
SELECT
    'Sales Response KPI',
    'Total Leads across response buckets',
    @MartLeadCount,
    @ResponseMartLeadCount,
    @ResponseMartLeadCount - @MartLeadCount,
    CASE
        WHEN @ResponseMartLeadCount = @MartLeadCount
        THEN 'PASS'
        ELSE 'FAIL'
    END;


/* =========================================================
   13. RESPONSE QUOTED LEADS
   ========================================================= */

DECLARE @ResponseQuoted BIGINT;

SELECT
    @ResponseQuoted =
        COALESCE(SUM(quoted_leads), 0)
FROM gold.mart_sales_response;


INSERT INTO #ValidationResults
SELECT
    'Sales Response KPI',
    'Quoted Leads across response buckets',
    @ActualQuoted,
    @ResponseQuoted,
    @ResponseQuoted - @ActualQuoted,
    CASE
        WHEN @ResponseQuoted = @ActualQuoted
        THEN 'PASS'
        ELSE 'FAIL'
    END;


/* =========================================================
   14. RESPONSE ORDERED LEADS
   ========================================================= */

DECLARE @ResponseOrdered BIGINT;

SELECT
    @ResponseOrdered =
        COALESCE(SUM(ordered_leads), 0)
FROM gold.mart_sales_response;


INSERT INTO #ValidationResults
SELECT
    'Sales Response KPI',
    'Ordered Leads across response buckets',
    @ActualOrdered,
    @ResponseOrdered,
    @ResponseOrdered - @ActualOrdered,
    CASE
        WHEN @ResponseOrdered = @ActualOrdered
        THEN 'PASS'
        ELSE 'FAIL'
    END;


/* =========================================================
   15. MEDIAN FIRST RESPONSE HOURS

   Median must use lead-level first_response_hours.
   NULL / No Sales Activity rows are excluded.
   ========================================================= */

DECLARE @MedianFirstResponse DECIMAL(18,6);

SELECT TOP 1
    @MedianFirstResponse =
        CAST
        (
            PERCENTILE_CONT(0.5)
            WITHIN GROUP
            (
                ORDER BY first_response_hours
            )
            OVER ()

            AS DECIMAL(18,6)
        )
FROM gold.mart_lead_funnel
WHERE first_response_hours IS NOT NULL;


/*
   This check validates that all non-null response values
   belong to a valid response bucket.
*/

DECLARE @InvalidResponseBucketCount BIGINT;

SELECT
    @InvalidResponseBucketCount = COUNT(*)
FROM gold.mart_lead_funnel
WHERE
    (
        first_response_hours IS NULL
        AND response_bucket <> 'No Sales Activity'
    )
    OR
    (
        first_response_hours >= 0
        AND first_response_hours < 4
        AND response_bucket <> '< 4h'
    )
    OR
    (
        first_response_hours >= 4
        AND first_response_hours < 12
        AND response_bucket <> '4-12h'
    )
    OR
    (
        first_response_hours >= 12
        AND first_response_hours < 24
        AND response_bucket <> '12-24h'
    )
    OR
    (
        first_response_hours >= 24
        AND response_bucket <> '> 24h'
    );


INSERT INTO #ValidationResults
SELECT
    'Sales Response KPI',
    'First Response bucket logic',
    0,
    @InvalidResponseBucketCount,
    @InvalidResponseBucketCount,
    CASE
        WHEN @InvalidResponseBucketCount = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END;


/* =========================================================
   16. NEGATIVE FIRST RESPONSE
   ========================================================= */

DECLARE @NegativeResponseCount BIGINT;

SELECT
    @NegativeResponseCount = COUNT(*)
FROM gold.mart_lead_funnel
WHERE first_response_hours < 0;


INSERT INTO #ValidationResults
SELECT
    'Sales Response KPI',
    'Negative First Response Hours',
    0,
    @NegativeResponseCount,
    @NegativeResponseCount,
    CASE
        WHEN @NegativeResponseCount = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END;


/* =========================================================
   17. NO SALES ACTIVITY NULL HANDLING
   ========================================================= */

DECLARE @InvalidNoActivityCount BIGINT;

SELECT
    @InvalidNoActivityCount = COUNT(*)
FROM gold.mart_lead_funnel
WHERE response_bucket = 'No Sales Activity'
  AND first_response_hours IS NOT NULL;


INSERT INTO #ValidationResults
SELECT
    'Sales Response KPI',
    'No Sales Activity keeps NULL response hours',
    0,
    @InvalidNoActivityCount,
    @InvalidNoActivityCount,
    CASE
        WHEN @InvalidNoActivityCount = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END;


/* =========================================================
   FINAL VALIDATION RESULT
   ========================================================= */

SELECT
    validation_group,
    validation_check,
    expected_value,
    actual_value,
    difference_value,
    [status]

FROM #ValidationResults

ORDER BY
    CASE WHEN [status] = 'FAIL' THEN 0 ELSE 1 END,
    validation_group,
    validation_check;


/* =========================================================
   KPI SNAPSHOT

   These are the current KPI values from the validated Gold
   layer. They are not hard-coded business conclusions.
   ========================================================= */

SELECT
    @FactLeadCount AS total_leads,

    @ActualQualified AS qualified_leads,
    CAST(@ActualQualifiedRate AS DECIMAL(10,4))
        AS qualified_lead_rate,

    @ActualQuoted AS quoted_leads,
    CAST(@ActualLeadToQuoteRate AS DECIMAL(10,4))
        AS lead_to_quote_rate,

    @ActualOrdered AS ordered_leads,
    CAST(@ActualLeadToOrderRate AS DECIMAL(10,4))
        AS lead_to_order_rate,

    CAST(@ActualMarketingSpend AS DECIMAL(18,2))
        AS attributable_marketing_spend_vnd,

    @ActualAttributedLeads
        AS attributable_leads,

    CAST(@ActualCPL AS DECIMAL(18,2))
        AS attributable_cpl_vnd,

    CAST(@ActualAttributedOrderValue AS DECIMAL(18,2))
        AS attributable_net_order_value_vnd,

    CAST(@ActualOrderValuePerLead AS DECIMAL(18,2))
        AS order_value_per_lead_vnd,

    CAST(@MedianFirstResponse AS DECIMAL(10,2))
        AS median_first_response_hours;


/* =========================================================
   OVERALL STATUS
   ========================================================= */

SELECT
    SUM(CASE WHEN [status] = 'FAIL' THEN 1 ELSE 0 END)
        AS failed_checks,

    SUM(CASE WHEN [status] = 'PASS' THEN 1 ELSE 0 END)
        AS passed_checks,

    CASE
        WHEN SUM(CASE WHEN [status] = 'FAIL' THEN 1 ELSE 0 END) = 0
        THEN 'PASS - PROJECT 1 KPI VALIDATED'

        ELSE 'FAIL - REVIEW KPI CHECKS BEFORE POWER BI'
    END AS overall_status

FROM #ValidationResults;
GO

USE SEPRO_Master_Prod;
GO

/* =========================================================
   PROJECT 1 - LOAD MART_LEAD_FUNNEL

   Grain:
   1 row = 1 lead

   Important:
   Each source fact is aggregated to lead grain BEFORE JOIN.
   This prevents fan-out and double counting.
   ========================================================= */

SET XACT_ABORT ON;
GO


BEGIN TRY

    /* =====================================================
       PRE-LOAD CHECK

       fact_lead must be unique because it is the base grain
       of this mart.
       ===================================================== */

    IF EXISTS
    (
        SELECT lead_id
        FROM gold.fact_lead
        GROUP BY lead_id
        HAVING COUNT(*) > 1
    )
        THROW 52001, 'Duplicate lead_id found in gold.fact_lead.', 1;


    BEGIN TRANSACTION;


    /* =====================================================
       AGGREGATE EACH FACT TO 1 ROW PER LEAD
       ===================================================== */

    ;WITH ActivityAgg AS
    (
        /* First sales activity for each lead. */

        SELECT
            lead_id,
            MIN(activity_datetime) AS first_activity_datetime

        FROM gold.fact_sales_activity

        GROUP BY lead_id
    ),

    QuoteAgg AS
    (
        /*
           Any quotation record is used as quotation evidence.
           No quotation-status filter is applied because no
           final valid-status rule has been confirmed.
        */

        SELECT
            lead_id,
            COUNT(*) AS quotation_count

        FROM gold.fact_quotation

        GROUP BY lead_id
    ),

    OrderLineAgg AS
    (
        /*
           Aggregate line value to sales order grain first.

           Net Order Value
           = quantity_ordered
             * unit_price_vnd
             * (1 - discount_pct)
        */

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

    OrderAgg AS
    (
        /*
           Project 1 measures first-time Lead-to-Order using
           order_type = 'New' to avoid mixing repeat orders.
        */

        SELECT
            o.lead_id,

            COUNT(*) AS order_count,

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
    ),

    MartSource AS
    (
        SELECT
            l.lead_id,

            l.campaign_key,
            dc.channel,
            l.customer_key,
            l.employee_key,
            l.created_date_key,

            l.created_at,
            l.lifecycle_status,


            /* Qualified funnel stage. */

            CASE
                WHEN UPPER(l.lifecycle_status)
                     IN ('QUALIFIED', 'QUOTED', 'WON')
                THEN CAST(1 AS BIT)

                ELSE CAST(0 AS BIT)
            END AS qualified_flag,


            /* Quotation evidence comes from fact_quotation. */

            CASE
                WHEN COALESCE(q.quotation_count, 0) > 0
                THEN CAST(1 AS BIT)

                ELSE CAST(0 AS BIT)
            END AS quote_flag,


            /* Order evidence comes from New Sales Orders. */

            CASE
                WHEN COALESCE(o.order_count, 0) > 0
                THEN CAST(1 AS BIT)

                ELSE CAST(0 AS BIT)
            END AS order_flag,


            /* Preserve NULL when no sales activity exists. */

            CASE
                WHEN a.first_activity_datetime IS NULL
                THEN NULL

                ELSE CAST
                (
                    DATEDIFF
                    (
                        MINUTE,
                        l.created_at,
                        a.first_activity_datetime
                    ) / 60.0

                    AS DECIMAL(10,2)
                )
            END AS first_response_hours,


            /* Response-time bucket for analysis. */

            CASE
                WHEN a.first_activity_datetime IS NULL
                THEN 'No Sales Activity'

                WHEN DATEDIFF
                     (
                         MINUTE,
                         l.created_at,
                         a.first_activity_datetime
                     ) < 0
                THEN 'Invalid Negative'

                WHEN DATEDIFF
                     (
                         MINUTE,
                         l.created_at,
                         a.first_activity_datetime
                     ) < 240
                THEN '< 4h'

                WHEN DATEDIFF
                     (
                         MINUTE,
                         l.created_at,
                         a.first_activity_datetime
                     ) < 720
                THEN '4-12h'

                WHEN DATEDIFF
                     (
                         MINUTE,
                         l.created_at,
                         a.first_activity_datetime
                     ) < 1440
                THEN '12-24h'

                ELSE '> 24h'
            END AS response_bucket,


            COALESCE(o.order_count, 0) AS order_count,

            CAST
            (
                COALESCE(o.net_order_value_vnd, 0)
                AS DECIMAL(18,2)
            ) AS net_order_value_vnd


        FROM gold.fact_lead l

        LEFT JOIN gold.dim_campaign dc
            ON l.campaign_key = dc.campaign_key

        LEFT JOIN ActivityAgg a
            ON l.lead_id = a.lead_id

        LEFT JOIN QuoteAgg q
            ON l.lead_id = q.lead_id

        LEFT JOIN OrderAgg o
            ON l.lead_id = o.lead_id
    )


    /* =====================================================
       UPDATE EXISTING LEADS
       ===================================================== */

    UPDATE m

    SET
        m.campaign_key         = s.campaign_key,
        m.channel              = s.channel,
        m.customer_key         = s.customer_key,
        m.employee_key         = s.employee_key,
        m.created_date_key     = s.created_date_key,

        m.created_at           = s.created_at,
        m.lifecycle_status     = s.lifecycle_status,

        m.qualified_flag       = s.qualified_flag,
        m.quote_flag           = s.quote_flag,
        m.order_flag           = s.order_flag,

        m.first_response_hours = s.first_response_hours,
        m.response_bucket      = s.response_bucket,

        m.order_count          = s.order_count,
        m.net_order_value_vnd  = s.net_order_value_vnd

    FROM gold.mart_lead_funnel m

    INNER JOIN MartSource s
        ON m.lead_id = s.lead_id;


    /* =====================================================
       INSERT NEW LEADS
       ===================================================== */

    INSERT INTO gold.mart_lead_funnel
    (
        lead_id,

        campaign_key,
        channel,
        customer_key,
        employee_key,
        created_date_key,

        created_at,
        lifecycle_status,

        qualified_flag,
        quote_flag,
        order_flag,

        first_response_hours,
        response_bucket,

        order_count,
        net_order_value_vnd
    )

    SELECT
        s.lead_id,

        s.campaign_key,
        s.channel,
        s.customer_key,
        s.employee_key,
        s.created_date_key,

        s.created_at,
        s.lifecycle_status,

        s.qualified_flag,
        s.quote_flag,
        s.order_flag,

        s.first_response_hours,
        s.response_bucket,

        s.order_count,
        s.net_order_value_vnd

    FROM MartSource s

    WHERE NOT EXISTS
    (
        SELECT 1

        FROM gold.mart_lead_funnel m

        WHERE m.lead_id = s.lead_id
    );


    COMMIT TRANSACTION;


    PRINT 'mart_lead_funnel loaded successfully.';


END TRY

BEGIN CATCH

    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    PRINT 'Error loading mart_lead_funnel:';
    PRINT CONCAT('Error Number: ', ERROR_NUMBER());
    PRINT CONCAT('Error Line: ', ERROR_LINE());
    PRINT CONCAT('Error Message: ', ERROR_MESSAGE());

    THROW;

END CATCH;
GO

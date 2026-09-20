USE SEPRO_Master_Prod;
GO

/* =========================================================
   PROJECT 1 - LOAD MART_SALES_RESPONSE

   Grain:
   1 row = 1 response bucket

   Source:
   gold.mart_lead_funnel

   Response buckets:
   < 4h
   4-12h
   12-24h
   > 24h
   No Sales Activity

   Median is used instead of average because response-time
   distributions are commonly skewed.
   ========================================================= */

SET XACT_ABORT ON;
GO

BEGIN TRY

    /* =====================================================
       PRE-LOAD CHECKS
       ===================================================== */

    IF EXISTS
    (
        SELECT lead_id
        FROM gold.mart_lead_funnel
        GROUP BY lead_id
        HAVING COUNT(*) > 1
    )
        THROW 54001, 'Duplicate lead_id found in gold.mart_lead_funnel.', 1;


    /* Negative response time indicates invalid chronology. */
    IF EXISTS
    (
        SELECT 1
        FROM gold.mart_lead_funnel
        WHERE first_response_hours < 0
    )
        THROW 54002, 'Negative first_response_hours found in mart_lead_funnel.', 1;


    BEGIN TRANSACTION;


    /* =====================================================
       FULL REFRESH

       This mart is fully derived from mart_lead_funnel.
       ===================================================== */

    DELETE FROM gold.mart_sales_response;


    /* =====================================================
       AGGREGATE RESPONSE METRICS
       ===================================================== */

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
        /*
           Exclude NULL response hours from median.

           No Sales Activity therefore keeps a NULL median,
           rather than incorrectly using 0 hours.
        */

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
    ),

    MartSource AS
    (
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


            /* Lead-to-Quote Rate. */

            CASE
                WHEN b.total_leads = 0
                THEN NULL

                ELSE CAST
                (
                    CAST(b.quoted_leads AS DECIMAL(18,4))
                    / NULLIF(b.total_leads, 0)

                    AS DECIMAL(10,4)
                )
            END AS lead_to_quote_rate,


            /* Lead-to-Order Rate. */

            CASE
                WHEN b.total_leads = 0
                THEN NULL

                ELSE CAST
                (
                    CAST(b.ordered_leads AS DECIMAL(18,4))
                    / NULLIF(b.total_leads, 0)

                    AS DECIMAL(10,4)
                )
            END AS lead_to_order_rate


        FROM BucketAgg b

        LEFT JOIN MedianAgg m
            ON b.response_bucket = m.response_bucket
    )


    INSERT INTO gold.mart_sales_response
    (
        response_bucket,
        bucket_sort,

        total_leads,
        quoted_leads,
        ordered_leads,

        median_first_response_hours,

        lead_to_quote_rate,
        lead_to_order_rate
    )

    SELECT
        response_bucket,
        bucket_sort,

        total_leads,
        quoted_leads,
        ordered_leads,

        median_first_response_hours,

        lead_to_quote_rate,
        lead_to_order_rate

    FROM MartSource;


    COMMIT TRANSACTION;


    PRINT 'mart_sales_response loaded successfully.';


END TRY

BEGIN CATCH

    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    PRINT 'Error loading mart_sales_response:';
    PRINT CONCAT('Error Number: ', ERROR_NUMBER());
    PRINT CONCAT('Error Line: ', ERROR_LINE());
    PRINT CONCAT('Error Message: ', ERROR_MESSAGE());

    THROW;

END CATCH;
GO

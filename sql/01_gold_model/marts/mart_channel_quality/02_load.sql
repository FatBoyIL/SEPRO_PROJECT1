USE SEPRO_Master_Prod;
GO

/* =========================================================
   PROJECT 1 - LOAD MART_CHANNEL_QUALITY

   Grain:
   1 row = 1 lead-created date + 1 campaign

   Sources:
   - gold.mart_lead_funnel
   - gold.fact_marketing_daily
   - gold.dim_date
   - gold.dim_campaign

   Important:
   Marketing and Lead data are aggregated separately
   BEFORE they are joined. This prevents fan-out.
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
        THROW 53001, 'Duplicate lead_id found in gold.mart_lead_funnel.', 1;


    IF EXISTS
    (
        SELECT
            marketing_date,
            campaign_id,
            source_platform
        FROM gold.fact_marketing_daily
        GROUP BY
            marketing_date,
            campaign_id,
            source_platform
        HAVING COUNT(*) > 1
    )
        THROW 53002, 'Duplicate business grain found in gold.fact_marketing_daily.', 1;


    BEGIN TRANSACTION;


    /* =====================================================
       FULL REFRESH

       This mart is fully derived from Gold facts/marts,
       so rebuilding it avoids stale aggregated rows.
       ===================================================== */

    DELETE FROM gold.mart_channel_quality;


    /* =====================================================
       BUILD SOURCE AT THE SAME GRAIN
       ===================================================== */

    ;WITH LeadAgg AS
    (
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

        FROM gold.mart_lead_funnel

        /* Channel quality requires an attributable campaign. */
        WHERE created_date_key IS NOT NULL
          AND campaign_key IS NOT NULL

        GROUP BY
            created_date_key,
            campaign_key
    ),

    MarketingAgg AS
    (
        SELECT
            date_key,
            campaign_key,

            SUM(spend_vnd)
                AS marketing_spend_vnd

        FROM gold.fact_marketing_daily

        WHERE date_key IS NOT NULL
          AND campaign_key IS NOT NULL

        GROUP BY
            date_key,
            campaign_key
    ),

    GrainKeys AS
    (
        /*
           UNION keeps:
           - dates/campaigns with Leads but no spend;
           - dates/campaigns with Spend but no CRM Leads.
        */

        SELECT
            date_key,
            campaign_key
        FROM LeadAgg

        UNION

        SELECT
            date_key,
            campaign_key
        FROM MarketingAgg
    ),

    MartSource AS
    (
        SELECT
            k.date_key,
            k.campaign_key,

            dd.[date] AS analysis_date,

            dc.campaign_id,
            dc.campaign_name,
            dc.channel,

            CAST
            (
                COALESCE(m.marketing_spend_vnd, 0)
                AS DECIMAL(18,2)
            ) AS marketing_spend_vnd,

            COALESCE(l.total_leads, 0)
                AS total_leads,

            COALESCE(l.qualified_leads, 0)
                AS qualified_leads,

            COALESCE(l.quoted_leads, 0)
                AS quoted_leads,

            COALESCE(l.ordered_leads, 0)
                AS ordered_leads,

            CAST
            (
                COALESCE(l.net_order_value_vnd, 0)
                AS DECIMAL(18,2)
            ) AS net_order_value_vnd,


            /* CPL = Marketing Spend / CRM Leads. */

            CASE
                WHEN COALESCE(l.total_leads, 0) = 0
                THEN NULL

                ELSE CAST
                (
                    COALESCE(m.marketing_spend_vnd, 0)
                    / NULLIF(CAST(l.total_leads AS DECIMAL(18,4)), 0)

                    AS DECIMAL(18,2)
                )
            END AS cpl_vnd,


            /* Qualified Lead Rate. */

            CASE
                WHEN COALESCE(l.total_leads, 0) = 0
                THEN NULL

                ELSE CAST
                (
                    CAST(l.qualified_leads AS DECIMAL(18,4))
                    / NULLIF(l.total_leads, 0)

                    AS DECIMAL(10,4)
                )
            END AS qualified_lead_rate,


            /* Lead-to-Quote Rate. */

            CASE
                WHEN COALESCE(l.total_leads, 0) = 0
                THEN NULL

                ELSE CAST
                (
                    CAST(l.quoted_leads AS DECIMAL(18,4))
                    / NULLIF(l.total_leads, 0)

                    AS DECIMAL(10,4)
                )
            END AS lead_to_quote_rate,


            /* Lead-to-Order Rate. */

            CASE
                WHEN COALESCE(l.total_leads, 0) = 0
                THEN NULL

                ELSE CAST
                (
                    CAST(l.ordered_leads AS DECIMAL(18,4))
                    / NULLIF(l.total_leads, 0)

                    AS DECIMAL(10,4)
                )
            END AS lead_to_order_rate,


            /*
               Order Value per Lead.

               Denominator includes all attributable leads,
               not only leads that generated an order.
            */

            CASE
                WHEN COALESCE(l.total_leads, 0) = 0
                THEN NULL

                ELSE CAST
                (
                    COALESCE(l.net_order_value_vnd, 0)
                    / NULLIF(CAST(l.total_leads AS DECIMAL(18,4)), 0)

                    AS DECIMAL(18,2)
                )
            END AS order_value_per_lead_vnd


        FROM GrainKeys k

        INNER JOIN gold.dim_date dd
            ON k.date_key = dd.date_key

        INNER JOIN gold.dim_campaign dc
            ON k.campaign_key = dc.campaign_key

        LEFT JOIN LeadAgg l
            ON k.date_key = l.date_key
           AND k.campaign_key = l.campaign_key

        LEFT JOIN MarketingAgg m
            ON k.date_key = m.date_key
           AND k.campaign_key = m.campaign_key
    )


    INSERT INTO gold.mart_channel_quality
    (
        date_key,
        campaign_key,

        analysis_date,
        campaign_id,
        campaign_name,
        channel,

        marketing_spend_vnd,

        total_leads,
        qualified_leads,
        quoted_leads,
        ordered_leads,

        net_order_value_vnd,

        cpl_vnd,
        qualified_lead_rate,
        lead_to_quote_rate,
        lead_to_order_rate,
        order_value_per_lead_vnd
    )

    SELECT
        date_key,
        campaign_key,

        analysis_date,
        campaign_id,
        campaign_name,
        channel,

        marketing_spend_vnd,

        total_leads,
        qualified_leads,
        quoted_leads,
        ordered_leads,

        net_order_value_vnd,

        cpl_vnd,
        qualified_lead_rate,
        lead_to_quote_rate,
        lead_to_order_rate,
        order_value_per_lead_vnd

    FROM MartSource;


    COMMIT TRANSACTION;


    PRINT 'mart_channel_quality loaded successfully.';


END TRY

BEGIN CATCH

    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    PRINT 'Error loading mart_channel_quality:';
    PRINT CONCAT('Error Number: ', ERROR_NUMBER());
    PRINT CONCAT('Error Line: ', ERROR_LINE());
    PRINT CONCAT('Error Message: ', ERROR_MESSAGE());

    THROW;

END CATCH;
GO

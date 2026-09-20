USE SEPRO_Master_Prod;
GO

/* =========================================================
   PROJECT 1 - LOAD FACT_MARKETING_DAILY
   Grain: date + campaign + source platform
   ========================================================= */

SET XACT_ABORT ON;
GO

BEGIN TRY

    IF EXISTS
    (
        SELECT
            [date],
            campaign_id,
            source_platform
        FROM silver.marketing_daily
        GROUP BY
            [date],
            campaign_id,
            source_platform
        HAVING COUNT(*) > 1
    )
        THROW 51006, 'Duplicate marketing grain found in silver.marketing_daily.', 1;

    BEGIN TRANSACTION;

    UPDATE f
    SET
        f.date_key        = dd.date_key,
        f.campaign_key    = dc.campaign_key,
        f.impressions     = s.impressions,
        f.clicks          = s.clicks,
        f.sessions        = s.sessions,
        f.spend_vnd       = s.spend_vnd,
        f.platform_leads  = s.leads_reported
    FROM gold.fact_marketing_daily f
    INNER JOIN silver.marketing_daily s
        ON f.marketing_date = s.[date]
       AND f.campaign_id = s.campaign_id
       AND f.source_platform = s.source_platform
    LEFT JOIN gold.dim_date dd
        ON s.[date] = dd.[date]
    LEFT JOIN gold.dim_campaign dc
        ON s.campaign_id = dc.campaign_id;

    INSERT INTO gold.fact_marketing_daily
    (
        marketing_date,
        campaign_id,
        date_key,
        campaign_key,
        source_platform,
        impressions,
        clicks,
        sessions,
        spend_vnd,
        platform_leads
    )
    SELECT
        s.[date],
        s.campaign_id,
        dd.date_key,
        dc.campaign_key,
        s.source_platform,
        s.impressions,
        s.clicks,
        s.sessions,
        s.spend_vnd,
        s.leads_reported
    FROM silver.marketing_daily s
    LEFT JOIN gold.dim_date dd
        ON s.[date] = dd.[date]
    LEFT JOIN gold.dim_campaign dc
        ON s.campaign_id = dc.campaign_id
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM gold.fact_marketing_daily f
        WHERE f.marketing_date = s.[date]
          AND f.campaign_id = s.campaign_id
          AND f.source_platform = s.source_platform
    );

    COMMIT TRANSACTION;

    PRINT 'fact_marketing_daily loaded successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    PRINT ERROR_MESSAGE();
    THROW;
END CATCH;
GO

USE SEPRO_Master_Prod;
GO

/* =========================================================
   PROJECT 1 - CREATE FACT_MARKETING_DAILY

   Grain:
   1 row = 1 date + campaign + source platform
   ========================================================= */

SET XACT_ABORT ON;
GO

BEGIN TRY
    BEGIN TRANSACTION;

    IF OBJECT_ID('gold.fact_marketing_daily', 'U') IS NULL
    BEGIN
        CREATE TABLE gold.fact_marketing_daily
        (
            marketing_daily_key  BIGINT IDENTITY(1,1) NOT NULL,
            marketing_date       DATE                 NOT NULL,
            campaign_id          NVARCHAR(50)         NOT NULL,
            date_key             INT                  NULL,
            campaign_key         INT                  NULL,
            source_platform      NVARCHAR(100)        NOT NULL,
            impressions          BIGINT               NOT NULL,
            clicks               BIGINT               NOT NULL,
            sessions             BIGINT               NOT NULL,
            spend_vnd            DECIMAL(18,2)        NOT NULL,
            platform_leads       INT                  NOT NULL,

            CONSTRAINT PK_fact_marketing_daily
                PRIMARY KEY (marketing_daily_key),

            CONSTRAINT UQ_fact_marketing_daily_grain
                UNIQUE (marketing_date, campaign_id, source_platform),

            CONSTRAINT FK_fact_marketing_daily_date
                FOREIGN KEY (date_key)
                REFERENCES gold.dim_date(date_key),

            CONSTRAINT FK_fact_marketing_daily_campaign
                FOREIGN KEY (campaign_key)
                REFERENCES gold.dim_campaign(campaign_key)
        );

        PRINT 'Created gold.fact_marketing_daily';
    END
    ELSE
        PRINT 'gold.fact_marketing_daily already exists.';

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    PRINT ERROR_MESSAGE();
    THROW;
END CATCH;
GO

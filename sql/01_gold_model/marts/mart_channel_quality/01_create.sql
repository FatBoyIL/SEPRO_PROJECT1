USE SEPRO_Master_Prod;
GO

/* =========================================================
   PROJECT 1 - CREATE MART_CHANNEL_QUALITY

   Grain:
   1 row = 1 lead-created date + 1 campaign

   Purpose:
   Compare marketing cost and lead quality by campaign/channel.

   Time attribution used in this mart:
   Lead.created_date_key = Marketing.date_key
   and the same campaign_key.
   ========================================================= */

SET XACT_ABORT ON;
GO

BEGIN TRY

    BEGIN TRANSACTION;

    IF OBJECT_ID('gold.mart_channel_quality', 'U') IS NULL
    BEGIN

        CREATE TABLE gold.mart_channel_quality
        (
            channel_quality_key        BIGINT IDENTITY(1,1) NOT NULL,

            date_key                   INT                  NOT NULL,
            campaign_key               INT                  NOT NULL,

            analysis_date              DATE                 NOT NULL,
            campaign_id                NVARCHAR(50)         NOT NULL,
            campaign_name              NVARCHAR(255)        NULL,
            channel                    NVARCHAR(100)        NULL,

            marketing_spend_vnd        DECIMAL(18,2)        NOT NULL,

            total_leads                INT                  NOT NULL,
            qualified_leads            INT                  NOT NULL,
            quoted_leads               INT                  NOT NULL,
            ordered_leads              INT                  NOT NULL,

            net_order_value_vnd        DECIMAL(18,2)        NOT NULL,

            cpl_vnd                    DECIMAL(18,2)        NULL,
            qualified_lead_rate        DECIMAL(10,4)        NULL,
            lead_to_quote_rate         DECIMAL(10,4)        NULL,
            lead_to_order_rate         DECIMAL(10,4)        NULL,
            order_value_per_lead_vnd   DECIMAL(18,2)        NULL,

            CONSTRAINT PK_mart_channel_quality
                PRIMARY KEY (channel_quality_key),

            CONSTRAINT UQ_mart_channel_quality_grain
                UNIQUE (date_key, campaign_key),

            CONSTRAINT FK_mart_channel_quality_date
                FOREIGN KEY (date_key)
                REFERENCES gold.dim_date(date_key),

            CONSTRAINT FK_mart_channel_quality_campaign
                FOREIGN KEY (campaign_key)
                REFERENCES gold.dim_campaign(campaign_key)
        );

        PRINT 'Created gold.mart_channel_quality';

    END
    ELSE
    BEGIN

        PRINT 'gold.mart_channel_quality already exists.';

    END;


    COMMIT TRANSACTION;


END TRY

BEGIN CATCH

    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    PRINT 'Error creating mart_channel_quality:';
    PRINT ERROR_MESSAGE();

    THROW;

END CATCH;
GO

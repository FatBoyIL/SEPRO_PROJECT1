USE SEPRO_Master_Prod;
GO

/* =========================================================
   PROJECT 1 - CREATE MART_SALES_RESPONSE

   Grain:
   1 row = 1 response bucket

   Purpose:
   Compare Lead-to-Quote and Lead-to-Order conversion
   across first-response-time groups.
   ========================================================= */

SET XACT_ABORT ON;
GO

BEGIN TRY

    BEGIN TRANSACTION;

    IF OBJECT_ID('gold.mart_sales_response', 'U') IS NULL
    BEGIN

        CREATE TABLE gold.mart_sales_response
        (
            response_bucket              NVARCHAR(50)  NOT NULL,
            bucket_sort                  TINYINT       NOT NULL,

            total_leads                  INT           NOT NULL,
            quoted_leads                 INT           NOT NULL,
            ordered_leads                INT           NOT NULL,

            median_first_response_hours  DECIMAL(10,2) NULL,

            lead_to_quote_rate           DECIMAL(10,4) NULL,
            lead_to_order_rate           DECIMAL(10,4) NULL,

            CONSTRAINT PK_mart_sales_response
                PRIMARY KEY (response_bucket),

            CONSTRAINT UQ_mart_sales_response_sort
                UNIQUE (bucket_sort)
        );

        PRINT 'Created gold.mart_sales_response';

    END
    ELSE
    BEGIN

        PRINT 'gold.mart_sales_response already exists.';

    END;


    COMMIT TRANSACTION;


END TRY

BEGIN CATCH

    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    PRINT 'Error creating mart_sales_response:';
    PRINT ERROR_MESSAGE();

    THROW;

END CATCH;
GO

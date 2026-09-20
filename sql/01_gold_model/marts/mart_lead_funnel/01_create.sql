USE SEPRO_Master_Prod;
GO

/* =========================================================
   PROJECT 1 - CREATE MART_LEAD_FUNNEL

   Grain:
   1 row = 1 lead

   Purpose:
   Combine Lead, Sales Activity, Quotation and Sales Order
   into one analytical table for funnel analysis.
   ========================================================= */

SET XACT_ABORT ON;
GO

BEGIN TRY

    BEGIN TRANSACTION;

    IF OBJECT_ID('gold.mart_lead_funnel', 'U') IS NULL
    BEGIN

        CREATE TABLE gold.mart_lead_funnel
        (
            lead_id                 NVARCHAR(50)   NOT NULL,

            campaign_key            INT            NULL,
            channel                 NVARCHAR(100)  NULL,
            customer_key            INT            NULL,
            employee_key            INT            NULL,
            created_date_key        INT            NULL,

            created_at              DATETIME2(0)   NOT NULL,
            lifecycle_status        NVARCHAR(50)   NOT NULL,

            qualified_flag          BIT            NOT NULL,
            quote_flag              BIT            NOT NULL,
            order_flag              BIT            NOT NULL,

            first_response_hours    DECIMAL(10,2)  NULL,
            response_bucket         NVARCHAR(50)   NOT NULL,

            order_count             INT            NOT NULL,
            net_order_value_vnd     DECIMAL(18,2)  NOT NULL,

            CONSTRAINT PK_mart_lead_funnel
                PRIMARY KEY (lead_id),

            CONSTRAINT FK_mart_lead_funnel_campaign
                FOREIGN KEY (campaign_key)
                REFERENCES gold.dim_campaign(campaign_key),

            CONSTRAINT FK_mart_lead_funnel_customer
                FOREIGN KEY (customer_key)
                REFERENCES gold.dim_customer(customer_key),

            CONSTRAINT FK_mart_lead_funnel_employee
                FOREIGN KEY (employee_key)
                REFERENCES gold.dim_employee(employee_key),

            CONSTRAINT FK_mart_lead_funnel_date
                FOREIGN KEY (created_date_key)
                REFERENCES gold.dim_date(date_key)
        );

        PRINT 'Created gold.mart_lead_funnel';

    END
    ELSE
    BEGIN

        PRINT 'gold.mart_lead_funnel already exists.';

    END;


    COMMIT TRANSACTION;


END TRY

BEGIN CATCH

    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    PRINT 'Error creating mart_lead_funnel:';
    PRINT ERROR_MESSAGE();

    THROW;

END CATCH;
GO

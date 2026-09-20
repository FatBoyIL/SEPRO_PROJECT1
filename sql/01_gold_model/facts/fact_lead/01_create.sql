/* =========================================================
   PROJECT 1 - FACT LEAD
   Grain: 1 row = 1 lead
   ========================================================= */

BEGIN TRY

    BEGIN TRANSACTION;


    IF OBJECT_ID('gold.fact_lead', 'U') IS NULL
    BEGIN

        CREATE TABLE gold.fact_lead
        (
            lead_id           NVARCHAR(50)  NOT NULL,

            customer_key      INT           NULL,
            campaign_key      INT           NULL,
            employee_key      INT           NULL,
            created_date_key  INT           NULL,

            created_at        DATETIME2(0)  NOT NULL,
            lifecycle_status  NVARCHAR(50)  NOT NULL,

            CONSTRAINT PK_fact_lead
                PRIMARY KEY (lead_id),

            CONSTRAINT FK_fact_lead_customer
                FOREIGN KEY (customer_key)
                REFERENCES gold.dim_customer(customer_key),

            CONSTRAINT FK_fact_lead_campaign
                FOREIGN KEY (campaign_key)
                REFERENCES gold.dim_campaign(campaign_key),

            CONSTRAINT FK_fact_lead_employee
                FOREIGN KEY (employee_key)
                REFERENCES gold.dim_employee(employee_key),

            CONSTRAINT FK_fact_lead_date
                FOREIGN KEY (created_date_key)
                REFERENCES gold.dim_date(date_key)
        );

        PRINT 'Created gold.fact_lead';

    END
    ELSE
    BEGIN
        PRINT 'gold.fact_lead already exists.';
    END;


    COMMIT TRANSACTION;

END TRY

BEGIN CATCH

    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    PRINT 'Error creating fact_lead:';
    PRINT ERROR_MESSAGE();

    THROW;

END CATCH;
GO
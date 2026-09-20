USE SEPRO_Master_Prod;
GO

/* =========================================================
   PROJECT 1 - CREATE FACT_QUOTATION
   Grain: 1 row = 1 quotation record / version
   ========================================================= */

SET XACT_ABORT ON;
GO

BEGIN TRY
    BEGIN TRANSACTION;

    IF OBJECT_ID('gold.fact_quotation', 'U') IS NULL
    BEGIN
        CREATE TABLE gold.fact_quotation
        (
            quotation_id         NVARCHAR(50)   NOT NULL,
            lead_id              NVARCHAR(50)   NOT NULL,
            customer_key         INT            NULL,
            employee_key         INT            NULL,
            quotation_date_key   INT            NULL,
            quotation_date       DATE           NOT NULL,
            version_no           INT            NOT NULL,
            valid_until          DATE           NULL,
            currency             NVARCHAR(10)   NULL,
            fx_rate_to_vnd       DECIMAL(18,6)  NULL,
            quotation_status     NVARCHAR(50)   NULL,
            header_total_vnd     DECIMAL(18,2)  NULL,

            CONSTRAINT PK_fact_quotation
                PRIMARY KEY (quotation_id),

            CONSTRAINT FK_fact_quotation_customer
                FOREIGN KEY (customer_key)
                REFERENCES gold.dim_customer(customer_key),

            CONSTRAINT FK_fact_quotation_employee
                FOREIGN KEY (employee_key)
                REFERENCES gold.dim_employee(employee_key),

            CONSTRAINT FK_fact_quotation_date
                FOREIGN KEY (quotation_date_key)
                REFERENCES gold.dim_date(date_key)
        );

        PRINT 'Created gold.fact_quotation';
    END
    ELSE
        PRINT 'gold.fact_quotation already exists.';

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    PRINT ERROR_MESSAGE();
    THROW;
END CATCH;
GO

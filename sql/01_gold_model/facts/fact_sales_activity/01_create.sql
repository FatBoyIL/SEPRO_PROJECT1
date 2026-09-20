USE SEPRO_Master_Prod;
GO

/* =========================================================
   PROJECT 1 - CREATE FACT_SALES_ACTIVITY
   Grain: 1 row = 1 sales activity
   ========================================================= */

SET XACT_ABORT ON;
GO

BEGIN TRY
    BEGIN TRANSACTION;

    IF OBJECT_ID('gold.fact_sales_activity', 'U') IS NULL
    BEGIN
        CREATE TABLE gold.fact_sales_activity
        (
            activity_id          NVARCHAR(50)  NOT NULL,
            lead_id              NVARCHAR(50)  NOT NULL,
            employee_key         INT           NULL,
            activity_date_key    INT           NULL,
            activity_datetime    DATETIME2(0)  NOT NULL,
            activity_type        NVARCHAR(100) NOT NULL,
            outcome              NVARCHAR(100) NULL,
            next_followup_date   DATE          NULL,
            data_entry_source    NVARCHAR(100) NULL,

            CONSTRAINT PK_fact_sales_activity
                PRIMARY KEY (activity_id),

            CONSTRAINT FK_fact_sales_activity_employee
                FOREIGN KEY (employee_key)
                REFERENCES gold.dim_employee(employee_key),

            CONSTRAINT FK_fact_sales_activity_date
                FOREIGN KEY (activity_date_key)
                REFERENCES gold.dim_date(date_key)
        );

        PRINT 'Created gold.fact_sales_activity';
    END
    ELSE
        PRINT 'gold.fact_sales_activity already exists.';

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    PRINT ERROR_MESSAGE();
    THROW;
END CATCH;
GO

USE SEPRO_Master_Prod;
GO

/* =========================================================
   PROJECT 1 - CREATE FACT_SALES_ORDER
   Grain: 1 row = 1 sales order
   ========================================================= */

SET XACT_ABORT ON;
GO

BEGIN TRY
    BEGIN TRANSACTION;

    IF OBJECT_ID('gold.fact_sales_order', 'U') IS NULL
    BEGIN
        CREATE TABLE gold.fact_sales_order
        (
            sales_order_id            NVARCHAR(50)   NOT NULL,
            quotation_id              NVARCHAR(50)   NULL,
            lead_id                   NVARCHAR(50)   NULL,
            customer_key              INT            NULL,
            employee_key              INT            NULL,
            order_date_key            INT            NULL,
            order_date                DATE           NOT NULL,
            requested_delivery_date   DATE           NOT NULL,
            payment_term              NVARCHAR(100)  NOT NULL,
            order_status              NVARCHAR(50)   NOT NULL,
            order_type                NVARCHAR(50)   NOT NULL,
            currency                  NVARCHAR(10)   NOT NULL,
            fx_rate_to_vnd            DECIMAL(18,6)  NOT NULL,

            CONSTRAINT PK_fact_sales_order
                PRIMARY KEY (sales_order_id),

            CONSTRAINT FK_fact_sales_order_customer
                FOREIGN KEY (customer_key)
                REFERENCES gold.dim_customer(customer_key),

            CONSTRAINT FK_fact_sales_order_employee
                FOREIGN KEY (employee_key)
                REFERENCES gold.dim_employee(employee_key),

            CONSTRAINT FK_fact_sales_order_date
                FOREIGN KEY (order_date_key)
                REFERENCES gold.dim_date(date_key)
        );

        PRINT 'Created gold.fact_sales_order';
    END
    ELSE
        PRINT 'gold.fact_sales_order already exists.';

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    PRINT ERROR_MESSAGE();
    THROW;
END CATCH;
GO

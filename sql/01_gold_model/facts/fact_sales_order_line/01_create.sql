USE SEPRO_Master_Prod;
GO

/* =========================================================
   PROJECT 1 - CREATE FACT_SALES_ORDER_LINE
   Grain: 1 row = 1 product line in 1 sales order
   ========================================================= */

SET XACT_ABORT ON;
GO

BEGIN TRY
    BEGIN TRANSACTION;

    IF OBJECT_ID('gold.fact_sales_order_line', 'U') IS NULL
    BEGIN
        CREATE TABLE gold.fact_sales_order_line
        (
            sales_order_line_id        NVARCHAR(50)   NOT NULL,
            sales_order_id             NVARCHAR(50)   NOT NULL,
            product_key                INT            NULL,
            promised_delivery_date_key INT            NULL,
            quantity_ordered           INT            NOT NULL,
            unit_price_vnd             DECIMAL(18,2)  NOT NULL,
            unit_cost_vnd              DECIMAL(18,2)  NOT NULL,
            discount_pct               DECIMAL(9,4)   NOT NULL,
            promised_delivery_date     DATE           NOT NULL,
            line_status                NVARCHAR(50)   NOT NULL,
            quantity_shipped_to_date   INT            NOT NULL,

            CONSTRAINT PK_fact_sales_order_line
                PRIMARY KEY (sales_order_line_id),

            CONSTRAINT FK_fact_sales_order_line_product
                FOREIGN KEY (product_key)
                REFERENCES gold.dim_product(product_key),

            CONSTRAINT FK_fact_sales_order_line_date
                FOREIGN KEY (promised_delivery_date_key)
                REFERENCES gold.dim_date(date_key)
        );

        PRINT 'Created gold.fact_sales_order_line';
    END
    ELSE
        PRINT 'gold.fact_sales_order_line already exists.';

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    PRINT ERROR_MESSAGE();
    THROW;
END CATCH;
GO

USE SEPRO_Master_Prod;
GO

/* =========================================================
   PROJECT 1 - LOAD FACT_SALES_ORDER_LINE
   ========================================================= */

SET XACT_ABORT ON;
GO

BEGIN TRY

    IF EXISTS
    (
        SELECT sales_order_line_id
        FROM silver.sales_order_lines
        GROUP BY sales_order_line_id
        HAVING COUNT(*) > 1
    )
        THROW 51005, 'Duplicate sales_order_line_id found in silver.sales_order_lines.', 1;

    BEGIN TRANSACTION;

    UPDATE f
    SET
        f.sales_order_id              = s.sales_order_id,
        f.product_key                 = dp.product_key,
        f.promised_delivery_date_key  = dd.date_key,
        f.quantity_ordered            = s.quantity_ordered,
        f.unit_price_vnd              = s.unit_price_vnd,
        f.unit_cost_vnd               = s.unit_cost_vnd,
        f.discount_pct                = s.discount_pct,
        f.promised_delivery_date      = s.promised_delivery_date,
        f.line_status                 = s.line_status,
        f.quantity_shipped_to_date    = s.quantity_shipped_to_date
    FROM gold.fact_sales_order_line f
    INNER JOIN silver.sales_order_lines s
        ON f.sales_order_line_id = s.sales_order_line_id
    LEFT JOIN gold.dim_product dp
        ON s.product_id = dp.product_id
    LEFT JOIN gold.dim_date dd
        ON s.promised_delivery_date = dd.[date];

    INSERT INTO gold.fact_sales_order_line
    (
        sales_order_line_id,
        sales_order_id,
        product_key,
        promised_delivery_date_key,
        quantity_ordered,
        unit_price_vnd,
        unit_cost_vnd,
        discount_pct,
        promised_delivery_date,
        line_status,
        quantity_shipped_to_date
    )
    SELECT
        s.sales_order_line_id,
        s.sales_order_id,
        dp.product_key,
        dd.date_key,
        s.quantity_ordered,
        s.unit_price_vnd,
        s.unit_cost_vnd,
        s.discount_pct,
        s.promised_delivery_date,
        s.line_status,
        s.quantity_shipped_to_date
    FROM silver.sales_order_lines s
    LEFT JOIN gold.dim_product dp
        ON s.product_id = dp.product_id
    LEFT JOIN gold.dim_date dd
        ON s.promised_delivery_date = dd.[date]
    WHERE s.sales_order_line_id IS NOT NULL
      AND NOT EXISTS
      (
          SELECT 1
          FROM gold.fact_sales_order_line f
          WHERE f.sales_order_line_id = s.sales_order_line_id
      );

    COMMIT TRANSACTION;

    PRINT 'fact_sales_order_line loaded successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    PRINT ERROR_MESSAGE();
    THROW;
END CATCH;
GO

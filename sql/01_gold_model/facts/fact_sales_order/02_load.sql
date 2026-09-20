USE SEPRO_Master_Prod;
GO

/* =========================================================
   PROJECT 1 - LOAD FACT_SALES_ORDER
   ========================================================= */

SET XACT_ABORT ON;
GO

BEGIN TRY

    IF EXISTS
    (
        SELECT sales_order_id
        FROM silver.sales_orders
        GROUP BY sales_order_id
        HAVING COUNT(*) > 1
    )
        THROW 51004, 'Duplicate sales_order_id found in silver.sales_orders.', 1;

    BEGIN TRANSACTION;

    UPDATE f
    SET
        f.quotation_id            = s.quotation_id,
        f.lead_id                 = s.lead_id,
        f.customer_key            = dc.customer_key,
        f.employee_key            = de.employee_key,
        f.order_date_key          = dd.date_key,
        f.order_date              = s.order_date,
        f.requested_delivery_date = s.requested_delivery_date,
        f.payment_term            = s.payment_term,
        f.order_status            = s.order_status,
        f.order_type              = s.order_type,
        f.currency                = s.currency,
        f.fx_rate_to_vnd          = s.fx_rate_to_vnd
    FROM gold.fact_sales_order f
    INNER JOIN silver.sales_orders s
        ON f.sales_order_id = s.sales_order_id
    LEFT JOIN gold.dim_customer dc
        ON s.customer_id = dc.customer_id
    LEFT JOIN gold.dim_employee de
        ON s.salesperson_id = de.employee_id
    LEFT JOIN gold.dim_date dd
        ON s.order_date = dd.[date];

    INSERT INTO gold.fact_sales_order
    (
        sales_order_id,
        quotation_id,
        lead_id,
        customer_key,
        employee_key,
        order_date_key,
        order_date,
        requested_delivery_date,
        payment_term,
        order_status,
        order_type,
        currency,
        fx_rate_to_vnd
    )
    SELECT
        s.sales_order_id,
        s.quotation_id,
        s.lead_id,
        dc.customer_key,
        de.employee_key,
        dd.date_key,
        s.order_date,
        s.requested_delivery_date,
        s.payment_term,
        s.order_status,
        s.order_type,
        s.currency,
        s.fx_rate_to_vnd
    FROM silver.sales_orders s
    LEFT JOIN gold.dim_customer dc
        ON s.customer_id = dc.customer_id
    LEFT JOIN gold.dim_employee de
        ON s.salesperson_id = de.employee_id
    LEFT JOIN gold.dim_date dd
        ON s.order_date = dd.[date]
    WHERE s.sales_order_id IS NOT NULL
      AND NOT EXISTS
      (
          SELECT 1
          FROM gold.fact_sales_order f
          WHERE f.sales_order_id = s.sales_order_id
      );

    COMMIT TRANSACTION;

    PRINT 'fact_sales_order loaded successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    PRINT ERROR_MESSAGE();
    THROW;
END CATCH;
GO

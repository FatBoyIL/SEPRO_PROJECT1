USE SEPRO_Master_Prod;
GO

/* =========================================================
   PROJECT 1 - LOAD FACT_QUOTATION
   ========================================================= */

SET XACT_ABORT ON;
GO

BEGIN TRY

    IF EXISTS
    (
        SELECT quotation_id
        FROM silver.quotations
        GROUP BY quotation_id
        HAVING COUNT(*) > 1
    )
        THROW 51003, 'Duplicate quotation_id found in silver.quotations.', 1;

    BEGIN TRANSACTION;

    UPDATE f
    SET
        f.lead_id             = s.lead_id,
        f.customer_key        = dc.customer_key,
        f.employee_key        = de.employee_key,
        f.quotation_date_key  = dd.date_key,
        f.quotation_date      = s.quote_date,
        f.version_no          = s.version_no,
        f.valid_until         = s.valid_until,
        f.currency            = s.currency,
        f.fx_rate_to_vnd      = s.fx_rate_to_vnd,
        f.quotation_status    = s.quotation_status,
        f.header_total_vnd    = s.header_total_vnd
    FROM gold.fact_quotation f
    INNER JOIN silver.quotations s
        ON f.quotation_id = s.quotation_id
    LEFT JOIN gold.dim_customer dc
        ON s.customer_id = dc.customer_id
    LEFT JOIN gold.dim_employee de
        ON s.salesperson_id = de.employee_id
    LEFT JOIN gold.dim_date dd
        ON s.quote_date = dd.[date];

    INSERT INTO gold.fact_quotation
    (
        quotation_id,
        lead_id,
        customer_key,
        employee_key,
        quotation_date_key,
        quotation_date,
        version_no,
        valid_until,
        currency,
        fx_rate_to_vnd,
        quotation_status,
        header_total_vnd
    )
    SELECT
        s.quotation_id,
        s.lead_id,
        dc.customer_key,
        de.employee_key,
        dd.date_key,
        s.quote_date,
        s.version_no,
        s.valid_until,
        s.currency,
        s.fx_rate_to_vnd,
        s.quotation_status,
        s.header_total_vnd
    FROM silver.quotations s
    LEFT JOIN gold.dim_customer dc
        ON s.customer_id = dc.customer_id
    LEFT JOIN gold.dim_employee de
        ON s.salesperson_id = de.employee_id
    LEFT JOIN gold.dim_date dd
        ON s.quote_date = dd.[date]
    WHERE s.quotation_id IS NOT NULL
      AND NOT EXISTS
      (
          SELECT 1
          FROM gold.fact_quotation f
          WHERE f.quotation_id = s.quotation_id
      );

    COMMIT TRANSACTION;

    PRINT 'fact_quotation loaded successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    PRINT ERROR_MESSAGE();
    THROW;
END CATCH;
GO

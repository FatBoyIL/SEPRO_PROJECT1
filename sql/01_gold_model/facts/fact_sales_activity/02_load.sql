USE SEPRO_Master_Prod;
GO

/* =========================================================
   PROJECT 1 - LOAD FACT_SALES_ACTIVITY
   ========================================================= */

SET XACT_ABORT ON;
GO

BEGIN TRY

    IF EXISTS
    (
        SELECT activity_id
        FROM silver.sales_activities
        GROUP BY activity_id
        HAVING COUNT(*) > 1
    )
        THROW 51002, 'Duplicate activity_id found in silver.sales_activities.', 1;

    BEGIN TRANSACTION;

    UPDATE f
    SET
        f.lead_id            = s.lead_id,
        f.employee_key       = de.employee_key,
        f.activity_date_key  = dd.date_key,
        f.activity_datetime  = s.activity_datetime,
        f.activity_type      = s.activity_type,
        f.outcome            = s.outcome,
        f.next_followup_date = s.next_followup_date,
        f.data_entry_source  = s.data_entry_source
    FROM gold.fact_sales_activity f
    INNER JOIN silver.sales_activities s
        ON f.activity_id = s.activity_id
    LEFT JOIN gold.dim_employee de
        ON s.employee_id = de.employee_id
    LEFT JOIN gold.dim_date dd
        ON CAST(s.activity_datetime AS DATE) = dd.[date];

    INSERT INTO gold.fact_sales_activity
    (
        activity_id,
        lead_id,
        employee_key,
        activity_date_key,
        activity_datetime,
        activity_type,
        outcome,
        next_followup_date,
        data_entry_source
    )
    SELECT
        s.activity_id,
        s.lead_id,
        de.employee_key,
        dd.date_key,
        s.activity_datetime,
        s.activity_type,
        s.outcome,
        s.next_followup_date,
        s.data_entry_source
    FROM silver.sales_activities s
    LEFT JOIN gold.dim_employee de
        ON s.employee_id = de.employee_id
    LEFT JOIN gold.dim_date dd
        ON CAST(s.activity_datetime AS DATE) = dd.[date]
    WHERE s.activity_id IS NOT NULL
      AND NOT EXISTS
      (
          SELECT 1
          FROM gold.fact_sales_activity f
          WHERE f.activity_id = s.activity_id
      );

    COMMIT TRANSACTION;

    PRINT 'fact_sales_activity loaded successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    PRINT ERROR_MESSAGE();
    THROW;
END CATCH;
GO

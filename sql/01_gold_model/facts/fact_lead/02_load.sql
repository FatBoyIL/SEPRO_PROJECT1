/* =========================================================
   LOAD FACT_LEAD
   ========================================================= */

SET XACT_ABORT ON;
GO


BEGIN TRY

    BEGIN TRANSACTION;


    /* =====================================================
       UPDATE EXISTING LEADS
       ===================================================== */

    UPDATE f

    SET
        f.customer_key     = dc.customer_key,
        f.campaign_key     = dca.campaign_key,
        f.employee_key     = de.employee_key,
        f.created_date_key = dd.date_key,
        f.created_at       = s.created_at,
        f.lifecycle_status = s.lifecycle_status

    FROM gold.fact_lead f

    INNER JOIN silver.leads s
        ON f.lead_id = s.lead_id

    LEFT JOIN gold.dim_customer dc
        ON s.customer_id = dc.customer_id

    LEFT JOIN gold.dim_campaign dca
        ON s.campaign_id = dca.campaign_id

    LEFT JOIN gold.dim_employee de
        ON s.assigned_sales_id = de.employee_id

    LEFT JOIN gold.dim_date dd
        ON CAST(s.created_at AS DATE) = dd.[date];


    PRINT 'Existing leads updated.';



    /* =====================================================
       INSERT NEW LEADS
       ===================================================== */

    INSERT INTO gold.fact_lead
    (
        lead_id,
        customer_key,
        campaign_key,
        employee_key,
        created_date_key,
        created_at,
        lifecycle_status
    )

    SELECT
        s.lead_id,
        dc.customer_key,
        dca.campaign_key,
        de.employee_key,
        dd.date_key,
        s.created_at,
        s.lifecycle_status

    FROM silver.leads s

    LEFT JOIN gold.dim_customer dc
        ON s.customer_id = dc.customer_id

    LEFT JOIN gold.dim_campaign dca
        ON s.campaign_id = dca.campaign_id

    LEFT JOIN gold.dim_employee de
        ON s.assigned_sales_id = de.employee_id

    LEFT JOIN gold.dim_date dd
        ON CAST(s.created_at AS DATE) = dd.[date]

    WHERE s.lead_id IS NOT NULL

      AND NOT EXISTS
      (
          SELECT 1
          FROM gold.fact_lead f
          WHERE f.lead_id = s.lead_id
      );


    PRINT 'New leads inserted.';


    COMMIT TRANSACTION;

    PRINT 'fact_lead loaded successfully.';


END TRY

BEGIN CATCH

    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;


    PRINT 'Error loading fact_lead';

    PRINT 'Error Number:';
    PRINT ERROR_NUMBER();

    PRINT 'Error Message:';
    PRINT ERROR_MESSAGE();

    PRINT 'Error Line:';
    PRINT ERROR_LINE();


    THROW;

END CATCH;
GO
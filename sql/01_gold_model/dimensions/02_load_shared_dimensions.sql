/* =========================================================
   SEPRO DATA ANALYST PORTFOLIO
   GOLD LAYER - LOAD SHARED DIMENSIONS
   SQL SERVER
   ========================================================= */
use SEPRO_Master_Prod
SET XACT_ABORT ON;
GO


/* =========================================================
   GET DATE RANGE FROM SILVER
   ========================================================= */

DECLARE @StartDate DATE;
DECLARE @EndDate   DATE;


/* Get the earliest and latest dates from Silver tables */

SELECT
    @StartDate = MIN(date_value),
    @EndDate   = MAX(date_value)
FROM
(
    SELECT CAST(created_at AS DATE) AS date_value
    FROM silver.leads
    WHERE created_at IS NOT NULL

    UNION ALL

    SELECT CAST(order_date AS DATE)
    FROM silver.sales_orders
    WHERE order_date IS NOT NULL

    UNION ALL

    SELECT CAST(snapshot_date AS DATE)
    FROM silver.inventory_daily_snapshot
    WHERE snapshot_date IS NOT NULL

) AS AllDates;



BEGIN TRY

    BEGIN TRANSACTION;


    /* =====================================================
       1. LOAD DIM_DATE

       Grain:
       1 row = 1 calendar date
       ===================================================== */


    /* Stop the load if no valid date is found */

    IF @StartDate IS NULL OR @EndDate IS NULL
        THROW 50001, 'No valid date found in Silver tables.', 1;


    /* Validate the date range */

    IF @StartDate > @EndDate
        THROW 50002, 'StartDate cannot be greater than EndDate.', 1;



    /* Generate one row for each date Ex: 01/01/2024 - 01/02/2024 */

    ;WITH DateSeries AS
    (
        SELECT @StartDate AS calendar_date

        UNION ALL

        SELECT DATEADD(DAY, 1, calendar_date)

        FROM DateSeries

        WHERE calendar_date < @EndDate
    )


    INSERT INTO gold.dim_date
    (
        date_key,
        [date],
        [year],
        [quarter],
        [month],
        month_name,
        [week],
        is_month_end,
        is_working_day
    )


    SELECT
        /* Convert date to YYYYMMDD format */
        CONVERT(INT, CONVERT(CHAR(8), calendar_date, 112)),

        calendar_date,

        YEAR(calendar_date),

        DATEPART(QUARTER, calendar_date),

        MONTH(calendar_date),

        DATENAME(MONTH, calendar_date),

        DATEPART(ISO_WEEK, calendar_date),


        /* Check if the date is the last day of the month */

        CASE
            WHEN calendar_date = EOMONTH(calendar_date)
            THEN 1
            ELSE 0
        END,


        /* Monday to Friday = working day */

        CASE
            WHEN DATEDIFF(DAY, '19000101', calendar_date) % 7
                 BETWEEN 0 AND 4
            THEN 1
            ELSE 0
        END


    FROM DateSeries d


    /* Insert only dates that do not already exist */

    WHERE NOT EXISTS
    (
        SELECT 1

        FROM gold.dim_date g

        WHERE g.[date] = d.calendar_date
    )


    OPTION (MAXRECURSION 0);


    PRINT 'dim_date loaded successfully.';



    /* =====================================================
       2. LOAD DIM_CUSTOMER

       Source:
       silver.customers

       Existing records -> UPDATE
       New records      -> INSERT
       ===================================================== */

    UPDATE g
    SET
        g.customer_name = s.company_name,
        g.segment       = s.customer_segment,
        g.industry      = s.industry,
        g.province      = s.province

    FROM gold.dim_customer g

    INNER JOIN silver.customers s
        ON g.customer_id = s.customer_id;


    INSERT INTO gold.dim_customer
    (
        customer_id,
        customer_name,
        segment,
        industry,
        province
    )

    SELECT
        s.customer_id,
        s.company_name,
        s.customer_segment,
        s.industry,
        s.province

    FROM silver.customers s

    WHERE s.customer_id IS NOT NULL

      AND NOT EXISTS
      (
          SELECT 1
          FROM gold.dim_customer g
          WHERE g.customer_id = s.customer_id
      );

    PRINT 'dim_customer loaded successfully.';



    /* =====================================================
       3. LOAD DIM_PRODUCT
       ===================================================== */

    UPDATE g
    SET
        g.sku          = s.sku,
        g.product_name = s.product_name,
        g.category     = s.product_category,
        g.family       = s.product_family,
        g.brand        = s.brand

    FROM gold.dim_product g

    INNER JOIN silver.products s
        ON g.product_id = s.product_id;


    INSERT INTO gold.dim_product
    (
        product_id,
        sku,
        product_name,
        category,
        family,
        brand
    )

    SELECT
        s.product_id,
        s.sku,
        s.product_name,
        s.product_category,
        s.product_family,
        s.brand

    FROM silver.products s

    WHERE s.product_id IS NOT NULL

      AND NOT EXISTS
      (
          SELECT 1
          FROM gold.dim_product g
          WHERE g.product_id = s.product_id
      );

    PRINT 'dim_product loaded successfully.';



    /* =====================================================
       4. LOAD DIM_SUPPLIER
       ===================================================== */

    UPDATE g
    SET
        g.supplier_name = s.supplier_name,
        g.country       = s.country,
        g.currency      = s.currency,
        g.payment_term  = s.payment_term,
        g.incoterm      = s.incoterm

    FROM gold.dim_supplier g

    INNER JOIN silver.suppliers s
        ON g.supplier_id = s.supplier_id;


    INSERT INTO gold.dim_supplier
    (
        supplier_id,
        supplier_name,
        country,
        currency,
        payment_term,
        incoterm
    )

    SELECT
        s.supplier_id,
        s.supplier_name,
        s.country,
        s.currency,
        s.payment_term,
        s.incoterm

    FROM silver.suppliers s

    WHERE s.supplier_id IS NOT NULL

      AND NOT EXISTS
      (
          SELECT 1
          FROM gold.dim_supplier g
          WHERE g.supplier_id = s.supplier_id
      );

    PRINT 'dim_supplier loaded successfully.';



    /* =====================================================
       5. LOAD DIM_EMPLOYEE

       Source:
       silver.employees

       Attributes:
       employee_name
       department_id
       job_title
       hire_date
       termination_date
       ===================================================== */

    UPDATE g
    SET
        g.employee_name    = s.employee_name,
        g.department_id    = s.department_id,
        g.job_title        = s.job_title,
        g.hire_date        = s.hire_date,
        g.termination_date = s.termination_date

    FROM gold.dim_employee g

    INNER JOIN silver.employees s
        ON g.employee_id = s.employee_id;


    INSERT INTO gold.dim_employee
    (
        employee_id,
        employee_name,
        department_id,
        job_title,
        hire_date,
        termination_date
    )

    SELECT
        s.employee_id,
        s.employee_name,
        s.department_id,
        s.job_title,
        s.hire_date,
        s.termination_date

    FROM silver.employees s

    WHERE s.employee_id IS NOT NULL

      AND NOT EXISTS
      (
          SELECT 1
          FROM gold.dim_employee g
          WHERE g.employee_id = s.employee_id
      );

    PRINT 'dim_employee loaded successfully.';



    /* =====================================================
       6. LOAD DIM_DEPARTMENT

       Source:
       silver.departments
       ===================================================== */

    UPDATE g
    SET
        g.department_name = s.department_name

    FROM gold.dim_department g

    INNER JOIN silver.departments s
        ON g.department_id = s.department_id;


    INSERT INTO gold.dim_department
    (
        department_id,
        department_name
    )

    SELECT
        s.department_id,
        s.department_name

    FROM silver.departments s

    WHERE s.department_id IS NOT NULL

      AND NOT EXISTS
      (
          SELECT 1
          FROM gold.dim_department g
          WHERE g.department_id = s.department_id
      );

    PRINT 'dim_department loaded successfully.';



    /* =====================================================
       7. LOAD DIM_WAREHOUSE

       Source:
       silver.warehouses

       Attributes:
       warehouse_name
       city
       province
       warehouse_type
       ===================================================== */

    UPDATE g
    SET
        g.warehouse_name = s.warehouse_name,
        g.city           = s.city,
        g.province       = s.province,
        g.warehouse_type = s.warehouse_type

    FROM gold.dim_warehouse g

    INNER JOIN silver.warehouses s
        ON g.warehouse_id = s.warehouse_id;


    INSERT INTO gold.dim_warehouse
    (
        warehouse_id,
        warehouse_name,
        city,
        province,
        warehouse_type
    )

    SELECT
        s.warehouse_id,
        s.warehouse_name,
        s.city,
        s.province,
        s.warehouse_type

    FROM silver.warehouses s

    WHERE s.warehouse_id IS NOT NULL

      AND NOT EXISTS
      (
          SELECT 1
          FROM gold.dim_warehouse g
          WHERE g.warehouse_id = s.warehouse_id
      );

    PRINT 'dim_warehouse loaded successfully.';



    /* =====================================================
       8. LOAD DIM_CAMPAIGN
       ===================================================== */

    UPDATE g
    SET
        g.campaign_name = s.campaign_name,
        g.channel       = s.channel,
        g.start_date    = s.start_date,
        g.end_date      = s.end_date,
        g.objective     = s.objective

    FROM gold.dim_campaign g

    INNER JOIN silver.marketing_campaigns s
        ON g.campaign_id = s.campaign_id;


    INSERT INTO gold.dim_campaign
    (
        campaign_id,
        campaign_name,
        channel,
        start_date,
        end_date,
        objective
    )

    SELECT
        s.campaign_id,
        s.campaign_name,
        s.channel,
        s.start_date,
        s.end_date,
        s.objective

    FROM silver.marketing_campaigns s

    WHERE s.campaign_id IS NOT NULL

      AND NOT EXISTS
      (
          SELECT 1
          FROM gold.dim_campaign g
          WHERE g.campaign_id = s.campaign_id
      );

    PRINT 'dim_campaign loaded successfully.';



    /* =====================================================
       COMMIT TRANSACTION
       ===================================================== */

    COMMIT TRANSACTION;

    PRINT '-----------------------------------------';
    PRINT 'All Gold dimensions loaded successfully.';
    PRINT '-----------------------------------------';


END TRY


BEGIN CATCH

    /* Roll back all changes if any error occurs. */

    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;


    PRINT '-----------------------------------------';
    PRINT 'Error loading Gold dimensions';

    PRINT 'Error Number:';
    PRINT ERROR_NUMBER();

    PRINT 'Error Message:';
    PRINT ERROR_MESSAGE();

    PRINT 'Error Line:';
    PRINT ERROR_LINE();

    PRINT '-----------------------------------------';

    THROW;

END CATCH;
GO
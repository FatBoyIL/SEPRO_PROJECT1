/* =========================================================
   SEPRO DATA ANALYST PORTFOLIO
   GOLD LAYER - SHARED DIMENSIONS
   SQL SERVER
   ========================================================= */
use SEPRO_Master_Prod
SET XACT_ABORT ON;
GO


/* =========================================================
   0. CREATE GOLD SCHEMA
   ========================================================= */

BEGIN TRY

    IF SCHEMA_ID('gold') IS NULL
    BEGIN
        EXEC('CREATE SCHEMA gold');
        PRINT 'Schema gold created successfully.';
    END
    ELSE
    BEGIN
        PRINT 'Schema gold already exists.';
    END;

END TRY

BEGIN CATCH

    PRINT 'Error creating gold schema:';
    PRINT ERROR_MESSAGE();

    THROW;

END CATCH;
GO


/* =========================================================
   1. CREATE SHARED DIMENSIONS
   ========================================================= */

BEGIN TRY

    BEGIN TRANSACTION;


    /* =====================================================
       DIM_DATE

       Grain:
       1 row = 1 calendar date

       date_key format:
       YYYYMMDD

       Example:
       20260918
       ===================================================== */

    IF OBJECT_ID('gold.dim_date', 'U') IS NULL
    BEGIN

        CREATE TABLE gold.dim_date
        (
            date_key        INT          NOT NULL,
            [date]          DATE         NOT NULL,
            [year]          SMALLINT     NOT NULL,
            [quarter]       TINYINT      NOT NULL,
            [month]         TINYINT      NOT NULL,
            month_name      NVARCHAR(20) NULL,
            [week]          TINYINT      NULL,
            is_month_end    BIT          NULL,
            is_working_day  BIT          NULL,

            CONSTRAINT PK_dim_date
                PRIMARY KEY (date_key),

            CONSTRAINT UQ_dim_date_date
                UNIQUE ([date])
        );

        PRINT 'Created gold.dim_date';

    END;



    /* =====================================================
       DIM_CUSTOMER

       Grain:
       1 row = 1 customer

       customer_key:
       Surrogate Key generated in Gold.

       customer_id:
       Natural Key from Silver.
       ===================================================== */

    IF OBJECT_ID('gold.dim_customer', 'U') IS NULL
    BEGIN

        CREATE TABLE gold.dim_customer
        (
            customer_key   INT IDENTITY(1,1) NOT NULL,
            customer_id    NVARCHAR(50)       NOT NULL,

            customer_name  NVARCHAR(255)      NULL,
            segment        NVARCHAR(100)      NULL,
            industry       NVARCHAR(100)      NULL,
            province       NVARCHAR(100)      NULL,

            CONSTRAINT PK_dim_customer
                PRIMARY KEY (customer_key),

            CONSTRAINT UQ_dim_customer_id
                UNIQUE (customer_id)
        );

        PRINT 'Created gold.dim_customer';

    END;



    /* =====================================================
       DIM_PRODUCT

       Grain:
       1 row = 1 product

       product_key:
       Surrogate Key generated in Gold.

       product_id:
       Natural Key from Silver.
       ===================================================== */

    IF OBJECT_ID('gold.dim_product', 'U') IS NULL
    BEGIN

        CREATE TABLE gold.dim_product
        (
            product_key    INT IDENTITY(1,1) NOT NULL,
            product_id     NVARCHAR(50)       NOT NULL,

            sku            NVARCHAR(100)      NULL,
            product_name   NVARCHAR(255)      NULL,
            category       NVARCHAR(100)      NULL,
            family         NVARCHAR(100)      NULL,
            brand          NVARCHAR(100)      NULL,

            CONSTRAINT PK_dim_product
                PRIMARY KEY (product_key),

            CONSTRAINT UQ_dim_product_id
                UNIQUE (product_id)
        );

        PRINT 'Created gold.dim_product';

    END;



    /* =====================================================
       DIM_SUPPLIER

       Grain:
       1 row = 1 supplier
       ===================================================== */

    IF OBJECT_ID('gold.dim_supplier', 'U') IS NULL
    BEGIN

        CREATE TABLE gold.dim_supplier
        (
            supplier_key   INT IDENTITY(1,1) NOT NULL,
            supplier_id    NVARCHAR(50)       NOT NULL,

            supplier_name  NVARCHAR(255)      NULL,
            country        NVARCHAR(100)      NULL,
            currency       NVARCHAR(10)       NULL,
            payment_term   NVARCHAR(100)      NULL,
            incoterm       NVARCHAR(50)       NULL,

            CONSTRAINT PK_dim_supplier
                PRIMARY KEY (supplier_key),

            CONSTRAINT UQ_dim_supplier_id
                UNIQUE (supplier_id)
        );

        PRINT 'Created gold.dim_supplier';

    END;



    /* =====================================================
       DIM_EMPLOYEE

       Grain:
       1 row = 1 employee

       Source:
       silver.employees

       Main attributes:
       - Employee name
       - Department
       - Job title
       - Hire date
       - Termination date
       ===================================================== */

    IF OBJECT_ID('gold.dim_employee', 'U') IS NULL
    BEGIN

        CREATE TABLE gold.dim_employee
        (
            employee_key     INT IDENTITY(1,1) NOT NULL,
            employee_id      NVARCHAR(50)       NOT NULL,

            employee_name    NVARCHAR(255)      NULL,
            department_id    NVARCHAR(50)       NULL,
            job_title        NVARCHAR(150)      NULL,
            hire_date        DATE               NULL,
            termination_date DATE               NULL,

            CONSTRAINT PK_dim_employee
                PRIMARY KEY (employee_key),

            CONSTRAINT UQ_dim_employee_id
                UNIQUE (employee_id)
        );

        PRINT 'Created gold.dim_employee';

    END;



    /* =====================================================
       DIM_DEPARTMENT

       Grain:
       1 row = 1 department

       Source:
       silver.departments
       ===================================================== */

    IF OBJECT_ID('gold.dim_department', 'U') IS NULL
    BEGIN

        CREATE TABLE gold.dim_department
        (
            department_key   INT IDENTITY(1,1) NOT NULL,
            department_id    NVARCHAR(50)       NOT NULL,

            department_name  NVARCHAR(150)      NULL,

            CONSTRAINT PK_dim_department
                PRIMARY KEY (department_key),

            CONSTRAINT UQ_dim_department_id
                UNIQUE (department_id)
        );

        PRINT 'Created gold.dim_department';

    END;



    /* =====================================================
       DIM_WAREHOUSE

       Grain:
       1 row = 1 warehouse

       Source:
       silver.warehouses

       Main attributes:
       - Warehouse name
       - City
       - Province
       - Warehouse type
       ===================================================== */

    IF OBJECT_ID('gold.dim_warehouse', 'U') IS NULL
    BEGIN

        CREATE TABLE gold.dim_warehouse
        (
            warehouse_key   INT IDENTITY(1,1) NOT NULL,
            warehouse_id    NVARCHAR(50)       NOT NULL,

            warehouse_name  NVARCHAR(255)      NULL,
            city            NVARCHAR(100)      NULL,
            province        NVARCHAR(100)      NULL,
            warehouse_type  NVARCHAR(100)      NULL,

            CONSTRAINT PK_dim_warehouse
                PRIMARY KEY (warehouse_key),

            CONSTRAINT UQ_dim_warehouse_id
                UNIQUE (warehouse_id)
        );

        PRINT 'Created gold.dim_warehouse';

    END;



    /* =====================================================
       DIM_CAMPAIGN

       Grain:
       1 row = 1 marketing campaign

       Source:
       silver.marketing_campaigns
       ===================================================== */

    IF OBJECT_ID('gold.dim_campaign', 'U') IS NULL
    BEGIN

        CREATE TABLE gold.dim_campaign
        (
            campaign_key   INT IDENTITY(1,1) NOT NULL,
            campaign_id    NVARCHAR(50)       NOT NULL,

            campaign_name  NVARCHAR(255)      NULL,
            channel        NVARCHAR(100)      NULL,
            start_date     DATE               NULL,
            end_date       DATE               NULL,
            objective      NVARCHAR(255)      NULL,

            CONSTRAINT PK_dim_campaign
                PRIMARY KEY (campaign_key),

            CONSTRAINT UQ_dim_campaign_id
                UNIQUE (campaign_id)
        );

        PRINT 'Created gold.dim_campaign';

    END;



    /* =====================================================
       Commit all changes if all tables are created
       successfully.
       ===================================================== */

    COMMIT TRANSACTION;

    PRINT '---------------------------------------';
    PRINT 'All shared dimensions created successfully.';
    PRINT '---------------------------------------';


END TRY


BEGIN CATCH

    /* Roll back all changes if an error occurs. */

    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;


    PRINT '---------------------------------------';
    PRINT 'Error creating Gold dimensions';

    PRINT 'Error Number:';
    PRINT ERROR_NUMBER();

    PRINT 'Error Message:';
    PRINT ERROR_MESSAGE();

    PRINT 'Error Line:';
    PRINT ERROR_LINE();

    PRINT '---------------------------------------';


    /* Return the original SQL Server error. */

    THROW;

END CATCH;
GO
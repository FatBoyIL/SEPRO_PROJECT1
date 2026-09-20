--/* =========================================
--   GOLD DIMENSION VALIDATION
--   ========================================= */


--/* 1. Check row counts */

--SELECT 'dim_date' AS table_name, COUNT(*) AS row_count
--FROM gold.dim_date

--UNION ALL

--SELECT 'dim_customer', COUNT(*)
--FROM gold.dim_customer

--UNION ALL

--SELECT 'dim_product', COUNT(*)
--FROM gold.dim_product

--UNION ALL

--SELECT 'dim_supplier', COUNT(*)
--FROM gold.dim_supplier

--UNION ALL

--SELECT 'dim_employee', COUNT(*)
--FROM gold.dim_employee

--UNION ALL

--SELECT 'dim_department', COUNT(*)
--FROM gold.dim_department

--UNION ALL

--SELECT 'dim_warehouse', COUNT(*)
--FROM gold.dim_warehouse

--UNION ALL

--SELECT 'dim_campaign', COUNT(*)
--FROM gold.dim_campaign;

--/* 2. Check duplicate Natural Keys */

--SELECT customer_id, COUNT(*) AS row_count
--FROM gold.dim_customer
--GROUP BY customer_id
--HAVING COUNT(*) > 1;


--SELECT product_id, COUNT(*) AS row_count
--FROM gold.dim_product
--GROUP BY product_id
--HAVING COUNT(*) > 1;


--SELECT supplier_id, COUNT(*) AS row_count
--FROM gold.dim_supplier
--GROUP BY supplier_id
--HAVING COUNT(*) > 1;


--SELECT employee_id, COUNT(*) AS row_count
--FROM gold.dim_employee
--GROUP BY employee_id
--HAVING COUNT(*) > 1;


--SELECT department_id, COUNT(*) AS row_count
--FROM gold.dim_department
--GROUP BY department_id
--HAVING COUNT(*) > 1;


--SELECT warehouse_id, COUNT(*) AS row_count
--FROM gold.dim_warehouse
--GROUP BY warehouse_id
--HAVING COUNT(*) > 1;


--SELECT campaign_id, COUNT(*) AS row_count
--FROM gold.dim_campaign
--GROUP BY campaign_id
--HAVING COUNT(*) > 1;

--/* 3. Reconcile Silver vs Gold */

--SELECT
--    (SELECT COUNT(*) FROM silver.customers) AS silver_count,
--    (SELECT COUNT(*) FROM gold.dim_customer) AS gold_count;

--SELECT
--    (SELECT COUNT(*) FROM silver.products) AS silver_count,
--    (SELECT COUNT(*) FROM gold.dim_product) AS gold_count;

--SELECT
--    (SELECT COUNT(*) FROM silver.suppliers) AS silver_count,
--    (SELECT COUNT(*) FROM gold.dim_supplier) AS gold_count;

--SELECT
--    (SELECT COUNT(*) FROM silver.employees) AS silver_count,
--    (SELECT COUNT(*) FROM gold.dim_employee) AS gold_count;

--SELECT
--    (SELECT COUNT(*) FROM silver.departments) AS silver_count,
--    (SELECT COUNT(*) FROM gold.dim_department) AS gold_count;

--SELECT
--    (SELECT COUNT(*) FROM silver.warehouses) AS silver_count,
--    (SELECT COUNT(*) FROM gold.dim_warehouse) AS gold_count;

--SELECT
--    (SELECT COUNT(*) FROM silver.marketing_campaigns) AS silver_count,
--    (SELECT COUNT(*) FROM gold.dim_campaign) AS gold_count;
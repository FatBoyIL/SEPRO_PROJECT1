USE SEPRO_Master_Prod;
GO

/* =========================================================
   PROJECT 1 - VALIDATE FACT_SALES_ORDER_LINE
   ========================================================= */

SELECT 'Duplicate Silver sales_order_line_id' AS validation_check, COUNT(*) AS issue_count
FROM
(
    SELECT sales_order_line_id
    FROM silver.sales_order_lines
    GROUP BY sales_order_line_id
    HAVING COUNT(*) > 1
) x;

SELECT 'Duplicate Gold sales_order_line_id' AS validation_check, COUNT(*) AS issue_count
FROM
(
    SELECT sales_order_line_id
    FROM gold.fact_sales_order_line
    GROUP BY sales_order_line_id
    HAVING COUNT(*) > 1
) x;

SELECT 'Silver records missing in Gold' AS validation_check, COUNT(*) AS issue_count
FROM
(
    SELECT sales_order_line_id FROM silver.sales_order_lines
    EXCEPT
    SELECT sales_order_line_id FROM gold.fact_sales_order_line
) x;

SELECT 'Extra Gold records' AS validation_check, COUNT(*) AS issue_count
FROM
(
    SELECT sales_order_line_id FROM gold.fact_sales_order_line
    EXCEPT
    SELECT sales_order_line_id FROM silver.sales_order_lines
) x;

SELECT 'Sales order relationship missing' AS validation_check, COUNT(*) AS issue_count
FROM silver.sales_order_lines s
LEFT JOIN gold.fact_sales_order o
    ON s.sales_order_id = o.sales_order_id
WHERE o.sales_order_id IS NULL;

SELECT 'Product mapping mismatch' AS validation_check, COUNT(*) AS issue_count
FROM silver.sales_order_lines s
JOIN gold.fact_sales_order_line f
    ON s.sales_order_line_id = f.sales_order_line_id
LEFT JOIN gold.dim_product d
    ON f.product_key = d.product_key
WHERE s.product_id IS NOT NULL
  AND ISNULL(d.product_id, '#MISSING#') <> s.product_id;

SELECT 'Date mapping mismatch' AS validation_check, COUNT(*) AS issue_count
FROM silver.sales_order_lines s
JOIN gold.fact_sales_order_line f
    ON s.sales_order_line_id = f.sales_order_line_id
LEFT JOIN gold.dim_date d
    ON f.promised_delivery_date_key = d.date_key
WHERE s.promised_delivery_date <> ISNULL(d.[date], '19000101');
GO

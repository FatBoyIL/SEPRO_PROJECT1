USE SEPRO_Master_Prod;
GO

/* =========================================================
   PROJECT 1 - VALIDATE FACT_SALES_ORDER
   ========================================================= */

SELECT 'Duplicate Silver sales_order_id' AS validation_check, COUNT(*) AS issue_count
FROM
(
    SELECT sales_order_id
    FROM silver.sales_orders
    GROUP BY sales_order_id
    HAVING COUNT(*) > 1
) x;

SELECT 'Duplicate Gold sales_order_id' AS validation_check, COUNT(*) AS issue_count
FROM
(
    SELECT sales_order_id
    FROM gold.fact_sales_order
    GROUP BY sales_order_id
    HAVING COUNT(*) > 1
) x;

SELECT 'Silver records missing in Gold' AS validation_check, COUNT(*) AS issue_count
FROM
(
    SELECT sales_order_id FROM silver.sales_orders
    EXCEPT
    SELECT sales_order_id FROM gold.fact_sales_order
) x;

SELECT 'Extra Gold records' AS validation_check, COUNT(*) AS issue_count
FROM
(
    SELECT sales_order_id FROM gold.fact_sales_order
    EXCEPT
    SELECT sales_order_id FROM silver.sales_orders
) x;

SELECT 'Lead relationship missing' AS validation_check, COUNT(*) AS issue_count
FROM silver.sales_orders s
LEFT JOIN gold.fact_lead l
    ON s.lead_id = l.lead_id
WHERE s.lead_id IS NOT NULL
  AND l.lead_id IS NULL;

SELECT 'Quotation relationship missing' AS validation_check, COUNT(*) AS issue_count
FROM silver.sales_orders s
LEFT JOIN gold.fact_quotation q
    ON s.quotation_id = q.quotation_id
WHERE s.quotation_id IS NOT NULL
  AND q.quotation_id IS NULL;

SELECT 'Customer mapping mismatch' AS validation_check, COUNT(*) AS issue_count
FROM silver.sales_orders s
JOIN gold.fact_sales_order f
    ON s.sales_order_id = f.sales_order_id
LEFT JOIN gold.dim_customer d
    ON f.customer_key = d.customer_key
WHERE s.customer_id IS NOT NULL
  AND ISNULL(d.customer_id, '#MISSING#') <> s.customer_id;

SELECT 'Employee mapping mismatch' AS validation_check, COUNT(*) AS issue_count
FROM silver.sales_orders s
JOIN gold.fact_sales_order f
    ON s.sales_order_id = f.sales_order_id
LEFT JOIN gold.dim_employee d
    ON f.employee_key = d.employee_key
WHERE s.salesperson_id IS NOT NULL
  AND ISNULL(d.employee_id, '#MISSING#') <> s.salesperson_id;

SELECT 'Date mapping mismatch' AS validation_check, COUNT(*) AS issue_count
FROM silver.sales_orders s
JOIN gold.fact_sales_order f
    ON s.sales_order_id = f.sales_order_id
LEFT JOIN gold.dim_date d
    ON f.order_date_key = d.date_key
WHERE s.order_date <> ISNULL(d.[date], '19000101');
GO

USE SEPRO_Master_Prod;
GO

/* =========================================================
   PROJECT 1 - VALIDATE FACT_SALES_ACTIVITY
   ========================================================= */

SELECT 'Duplicate Silver activity_id' AS validation_check, COUNT(*) AS issue_count
FROM
(
    SELECT activity_id
    FROM silver.sales_activities
    GROUP BY activity_id
    HAVING COUNT(*) > 1
) x;

SELECT 'Duplicate Gold activity_id' AS validation_check, COUNT(*) AS issue_count
FROM
(
    SELECT activity_id
    FROM gold.fact_sales_activity
    GROUP BY activity_id
    HAVING COUNT(*) > 1
) x;

SELECT 'Silver records missing in Gold' AS validation_check, COUNT(*) AS issue_count
FROM
(
    SELECT activity_id FROM silver.sales_activities
    EXCEPT
    SELECT activity_id FROM gold.fact_sales_activity
) x;

SELECT 'Extra Gold records' AS validation_check, COUNT(*) AS issue_count
FROM
(
    SELECT activity_id FROM gold.fact_sales_activity
    EXCEPT
    SELECT activity_id FROM silver.sales_activities
) x;

SELECT 'Lead relationship missing' AS validation_check, COUNT(*) AS issue_count
FROM silver.sales_activities s
LEFT JOIN gold.fact_lead l
    ON s.lead_id = l.lead_id
WHERE s.lead_id IS NOT NULL
  AND l.lead_id IS NULL;

SELECT 'Employee mapping mismatch' AS validation_check, COUNT(*) AS issue_count
FROM silver.sales_activities s
JOIN gold.fact_sales_activity f
    ON s.activity_id = f.activity_id
LEFT JOIN gold.dim_employee d
    ON f.employee_key = d.employee_key
WHERE s.employee_id IS NOT NULL
  AND ISNULL(d.employee_id, '#MISSING#') <> s.employee_id;

SELECT 'Date mapping mismatch' AS validation_check, COUNT(*) AS issue_count
FROM silver.sales_activities s
JOIN gold.fact_sales_activity f
    ON s.activity_id = f.activity_id
LEFT JOIN gold.dim_date d
    ON f.activity_date_key = d.date_key
WHERE CAST(s.activity_datetime AS DATE) <> ISNULL(d.[date], '19000101');
GO

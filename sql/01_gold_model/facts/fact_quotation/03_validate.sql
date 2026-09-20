USE SEPRO_Master_Prod;
GO

/* =========================================================
   PROJECT 1 - VALIDATE FACT_QUOTATION
   ========================================================= */

SELECT 'Duplicate Silver quotation_id' AS validation_check, COUNT(*) AS issue_count
FROM
(
    SELECT quotation_id
    FROM silver.quotations
    GROUP BY quotation_id
    HAVING COUNT(*) > 1
) x;

SELECT 'Duplicate Gold quotation_id' AS validation_check, COUNT(*) AS issue_count
FROM
(
    SELECT quotation_id
    FROM gold.fact_quotation
    GROUP BY quotation_id
    HAVING COUNT(*) > 1
) x;

SELECT 'Silver records missing in Gold' AS validation_check, COUNT(*) AS issue_count
FROM
(
    SELECT quotation_id FROM silver.quotations
    EXCEPT
    SELECT quotation_id FROM gold.fact_quotation
) x;

SELECT 'Extra Gold records' AS validation_check, COUNT(*) AS issue_count
FROM
(
    SELECT quotation_id FROM gold.fact_quotation
    EXCEPT
    SELECT quotation_id FROM silver.quotations
) x;

SELECT 'Lead relationship missing' AS validation_check, COUNT(*) AS issue_count
FROM silver.quotations s
LEFT JOIN gold.fact_lead l
    ON s.lead_id = l.lead_id
WHERE s.lead_id IS NOT NULL
  AND l.lead_id IS NULL;

SELECT 'Customer mapping mismatch' AS validation_check, COUNT(*) AS issue_count
FROM silver.quotations s
JOIN gold.fact_quotation f
    ON s.quotation_id = f.quotation_id
LEFT JOIN gold.dim_customer d
    ON f.customer_key = d.customer_key
WHERE s.customer_id IS NOT NULL
  AND ISNULL(d.customer_id, '#MISSING#') <> s.customer_id;

SELECT 'Employee mapping mismatch' AS validation_check, COUNT(*) AS issue_count
FROM silver.quotations s
JOIN gold.fact_quotation f
    ON s.quotation_id = f.quotation_id
LEFT JOIN gold.dim_employee d
    ON f.employee_key = d.employee_key
WHERE s.salesperson_id IS NOT NULL
  AND ISNULL(d.employee_id, '#MISSING#') <> s.salesperson_id;

SELECT 'Date mapping mismatch' AS validation_check, COUNT(*) AS issue_count
FROM silver.quotations s
JOIN gold.fact_quotation f
    ON s.quotation_id = f.quotation_id
LEFT JOIN gold.dim_date d
    ON f.quotation_date_key = d.date_key
WHERE s.quote_date <> ISNULL(d.[date], '19000101');
GO

/*
==========================================================================================
Quality Checks
==========================================================================================
Script Purpose:
  This Script performs various quality checks for data consistency, accuracy, and 
  standardization across the 'Silver' schema. It includes checks for:
  - Null or duplicate Primary keys.
  - Unwanted spaces in String fields.
  - Data Standardization and Consistency.
  - Invalid date ranges and Orders
  - Data Consistency between related fields.

Usage Notes:
  - Run these checks after loading Silve layer.
  - Investigate and resolve any discrepencies found during the checks.
==========================================================================================
*/


--=========================================================================
-- Checks for ' silver.crm_cust_info'
--=========================================================================

-- Check for unwanted spaces
--Expectation:No Results

SELECT cst_firstname
FROM silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname);

SELECT cst_lastname
FROM silver.crm_cust_info
WHERE cst_lastname != TRIM (cst_lastname);


SELECT cst_gndr
FROM bronze.crm_cust_info
WHERE cst_gndr != TRIM (cst_gndr);


--=========================================================================
-- Checks for 'silver.crm_prd_info'
--=========================================================================

-- Check for the Nulls and Duplicates in Primary key
-- Expectation: No Result

SELECT 
prd_id,
COUNT(*)
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;

-- Check for unwanted spaces
-- Expectation: No results
SELECT prd_nm
FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);

-- Check for NULLS or Negative Numbers
-- Expectation: No Results
SELECT prd_cost
FROM silver.crm_prd_info
WHERE prd_cost <0 or prd_cost IS NULL;

-- Check for Invalid Date Orders
SELECT *
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt;




--=========================================================================
-- Checks for 'silver.crm_sales_details'
--=========================================================================

SELECT *
FROM (
	SELECT *,
	ROW_NUMBER() OVER (PARTITION BY sls_ord_num ORDER by sls_ord_num DESC) AS flag_last
	FROM bronze.crm_sales_details
	WHERE sls_ord_num IS NOT NULL
)t WHERE flag_last = 1;

-- Check data Consistency: Between Sales, Quantity, and Price.
-- >> Sales = Quantity * Price
-- >> Values must not be NULL, zero OR negative.
SELECT DISTINCT
	sls_sales,
	sls_quantity,
	sls_price
FROM bronze.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <=0; 

SELECT *
FROM silver.crm_sales_details;



--=========================================================================
-- Checks for ' silver.erp_cust_az12'
--=========================================================================

SELECT DISTINCT 
	bdate
FROM bronze.erp_cust_az12
WHERE bdate < '1925-01-01' OR bdate > GETDATE();

--=========================================================================
-- Checks for ' silver.erp_loc_a101'
--=========================================================================

SELECT DISTINCT 
	cntry AS old_cntry,
	CASE WHEN TRIM(cntry) = 'DE'THEN 'Germany'
		 WHEN TRIM(cntry) IN ('US','USA') THEN 'United States'
		 WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
		 ELSE TRIM(cntry)
	END AS cntry
FROM bronze.erp_loc_a101
ORDER BY cntry;

--=========================================================================
-- Checks for ' silver.erp_px_cat_g1v2'
--=========================================================================

-- Check for unwanted spaces
SELECT * FROM bronze.erp_px_cat_g1v2
WHERE cat != TRIM(cat) OR subcat != TRIM(subcat) OR maintainence != TRIM(maintainence);

-- Data Standardization & Consistency
SELECT DISTINCT
	cat,
	subcat,
	maintainence
FROM bronze.erp_px_cat_g1v2;



-- identify quality issues from bronze layer

-- check the primary key IF WE HAVE DUPLICATES (expectation: no result)

SELECT 
cst_id,
COUNT(*)
FROM bronze.crm_cust_info GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;



SELECT
*
FROM bronze.crm_cust_info
WHERE cst_id = 29466;

-- rank and pick the highest. ALSO CHECK FOR DUPLICATES

SELECT * FROM(
SELECT
*,
ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_creater_date DESC) as FLAG_LAST
FROM bronze.crm_cust_info

)t WHERE flag_last !=1

-- transform and get only once

SELECT * FROM(
SELECT
*,
ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_creater_date DESC) as FLAG_LAST
FROM bronze.crm_cust_info

)t WHERE flag_last =1



-- check unwanted spaces for string values. expectation = no results
-- we can do this for all string columns
SELECT cst_firstname
FROM bronze.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname)


-- write transformation:

SELECT 
cst_id,
cst_key,
TRIM(cst_firstname) as cst_firstname,
TRIM(cst_lastname) as cst_lastname,
cst_material_status,
cst_gndr,
cst_creater_date
FROM(
SELECT
*,
ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_creater_date DESC) as FLAG_LAST
FROM bronze.crm_cust_info
WHERE cst_id IS NOT NULL

)t WHERE flag_last =1


-- data standardization and consistency

SELECT DISTINCT cst_gndr
FROM bronze.crm_cust_info


SELECT 
cst_id,
cst_key,
TRIM(cst_firstname) as cst_firstname,
TRIM(cst_lastname) as cst_lastname,
CASE WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
	WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
	ELSE 'n/a' -- if its null
	END cst_gndr,

CASE WHEN UPPER(TRIM(cst_material_status)) = 'S' THEN 'Single'
	WHEN UPPER(TRIM(cst_material_status)) = 'M' THEN 'Married'
	ELSE 'n/a' -- if its null
	END cst_material_status,
cst_creater_date
FROM(
SELECT
*,
ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_creater_date DESC) as FLAG_LAST
FROM bronze.crm_cust_info
WHERE cst_id IS NOT NULL

)t WHERE flag_last =1


-- insertt into silver table the transformed data
TRUNCATE TABLE silver.crm_cust_info;
INSERT INTO silver.crm_cust_info(cst_id,cst_key,cst_firstname,cst_lastname,cst_material_status,cst_gndr,cst_creater_date)

SELECT 
cst_id,
cst_key,
TRIM(cst_firstname) as cst_firstname,
TRIM(cst_lastname) as cst_lastname,
CASE WHEN UPPER(TRIM(cst_material_status)) = 'S' THEN 'Single'
	WHEN UPPER(TRIM(cst_material_status)) = 'M' THEN 'Married'
	ELSE 'n/a' -- if its null
	END cst_material_status,
CASE WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
	WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
	ELSE 'n/a' -- if its null
	END cst_gndr,


cst_creater_date
FROM(
SELECT
*,
ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_creater_date DESC) as FLAG_LAST
FROM bronze.crm_cust_info
WHERE cst_id IS NOT NULL

)t WHERE flag_last =1


-- CHECK THE QUALITY OF SILVER:

SELECT cst_id, COUNT(*) FROM 
silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL

SELECT cst_key
FROM silver.crm_cust_info
WHERE cst_key!=TRIM(cst_key)

SELECT DISTINCT cst_gndr
FROM silver.crm_cust_info



-- 2. SECOND TABLE

-- check for nulls or duplicates in primary key

SELECT
prd_id,
COUNT(*)
FROM bronze.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;

-- split the product key in two columns since it has a lot of info
-- here we derived columns

SELECT
prd_id,
prd_key,
REPLACE(SUBSTRING(prd_key,1,5),'-','_') as cat_id,
SUBSTRING(prd_key,7, LEN(prd_key)) as prd_key, -- we need to join with sales details
prd_nm,
prd_cost,
prd_line,
prd_start_dt,
prd_end_dt
FROM bronze.crm_prd_info
/*
WHERE REPLACE(SUBSTRING(prd_key,1,5),'-','_') 
NOT IN 
SELECT DISTINCT id FROM bronze.erp_px_cat_g1v2*/


-- check if we can join those two columns.
-- in one table we have underscore in the other we have dash
-- we must do matching

SELECT DISTINCT id FROM bronze.erp_px_cat_g1v2


-- to see product name if we have any spaces

SELECT
prd_nm
FROM bronze.crm_prd_info
WHERE prd_nm != TRIM(prd_nm)

-- check for nulls or negative numbers
SELECT
prd_cost
FROM bronze.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS null


-- replace null with zeros

SELECT
prd_id,
prd_key,
REPLACE(SUBSTRING(prd_key,1,5),'-','_') as cat_id,
SUBSTRING(prd_key,7, LEN(prd_key)) as prd_key, -- we need to join with sales details
prd_nm,
ISNULL(prd_cost,0) AS prd_cost,
prd_line,
prd_start_dt,
prd_end_dt
FROM bronze.crm_prd_info

-- prd_line has abbreviation
SELECT DISTINCT 
prd_line FROM bronze.crm_prd_info

-- replace abbreviation
-- here we did data normalization

SELECT
prd_id,
prd_key,
REPLACE(SUBSTRING(prd_key,1,5),'-','_') as cat_id,
SUBSTRING(prd_key,7, LEN(prd_key)) as prd_key, -- we need to join with sales details
prd_nm,
ISNULL(prd_cost,0) AS prd_cost,
CASE WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
	WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
	WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
	WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
	ELSE 'n/a'
	END AS prd_line,
prd_start_dt,
prd_end_dt
FROM bronze.crm_prd_info

-- start and end date

SELECT * FROM
bronze.crm_prd_info
WHERE prd_end_dt  < prd_start_dt

-- first solution switch first date with start date
-- each record must have a start, and can be null
-- rebuild the end date from the start date. the end of the date can be the start of the next




SELECT
prd_id,
prd_key,
REPLACE(SUBSTRING(prd_key,1,5),'-','_') as cat_id,
SUBSTRING(prd_key,7, LEN(prd_key)) as prd_key, -- we need to join with sales details
prd_nm,
ISNULL(prd_cost,0) AS prd_cost,
CASE WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
	WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
	WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
	WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
	ELSE 'n/a'
	END AS prd_line,
CAST(prd_start_dt AS DATE) AS prd_start_dt,
CAST(LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt)-1  AS DATE)as prd_end_dt_test
FROM bronze.crm_prd_info


-- INSERT NOW
TRUNCATE TABLE silver.crm_prd_info
INSERT INTO silver.crm_prd_info (
prd_id, cat_id, prd_key, prd_nm, prd_cost, prd_line, prd_start_dt, prd_end_dt
)
SELECT
prd_id,

REPLACE(SUBSTRING(prd_key,1,5),'-','_') as cat_id,
SUBSTRING(prd_key,7, LEN(prd_key)) as prd_key, -- we need to join with sales details
prd_nm,
ISNULL(prd_cost,0) AS prd_cost,
CASE WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
	WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
	WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
	WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
	ELSE 'n/a'
	END AS prd_line,
CAST(prd_start_dt AS DATE) AS prd_start_dt,
CAST(LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt)-1  AS DATE)as prd_end_dt_test
FROM bronze.crm_prd_info





-- 3. TABELA 3

SELECT
sls_ord_num, 
sls_prd_key,
sls_cust_id,
sls_order_dt,
sls_ship_dt,
sls_due_dt,
sls_sales,
sls_quantity,
sls_price
FROM bronze.crm_sales_details

-- change the datatypes of date from integer to date

SELECT 
nullif(sls_order_dt,0) as sls_order_dt
FROM bronze.crm_sales_details
WHERE sls_order_dt <= 0 OR len(sls_order_dt) !=8


SELECT
sls_ord_num, 
sls_prd_key,
sls_cust_id,
CASE 
	WHEN sls_order_dt = 0 OR LEN(sls_order_dt) !=8 THEN NULL
	ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
END AS sls_order_dt,
sls_ship_dt,
sls_due_dt,
sls_sales,
sls_quantity,
sls_price
FROM bronze.crm_sales_details

-- shipping day and due dt
SELECT
sls_ord_num, 
sls_prd_key,
sls_cust_id,
CASE 
	WHEN sls_order_dt = 0 OR LEN(sls_order_dt) !=8 THEN NULL
	ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
END AS sls_order_dt,
CASE 
	WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) !=8 THEN NULL
	ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
END AS sls_ship_dt,
CASE 
	WHEN sls_due_dt = 0 OR LEN(sls_due_dt) !=8 THEN NULL
	ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
END AS sls_due_dt,
sls_sales,
sls_quantity,
sls_price
FROM bronze.crm_sales_details

-- order date must be lower than ship date and due date

SELECT *
FROM bronze.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt

-- check data consistency for sales

SELECT
sls_sales,
sls_quantity,
sls_price
FROM bronze.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <= 0 OR sls_quantity<=0 OR sls_price <=0

-- solution 1: data issue will be fixed in source system
-- solution 2: data issue has to be fixed in data warehouse


SELECT
sls_sales,
sls_quantity,
sls_price,
CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
	THEN sls_quantity * ABS(sls_price)
	ELSE sls_sales
END AS sls_sales,
CASE WHEN sls_price IS NULL OR sls_price <=0
	THEN sls_sales / NULLIF(sls_quantity,0)
	ELSE sls_price
END AS sls_price,
FROM bronze.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <= 0 OR sls_quantity<=0 OR sls_price <=0



SELECT
sls_ord_num, 
sls_prd_key,
sls_cust_id,
CASE 
	WHEN sls_order_dt = 0 OR LEN(sls_order_dt) !=8 THEN NULL
	ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
END AS sls_order_dt,
CASE 
	WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) !=8 THEN NULL
	ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
END AS sls_ship_dt,
CASE 
	WHEN sls_due_dt = 0 OR LEN(sls_due_dt) !=8 THEN NULL
	ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
END AS sls_due_dt,
CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
	THEN sls_quantity * ABS(sls_price)
	ELSE sls_sales
END AS sls_sales,
sls_quantity,
CASE WHEN sls_price IS NULL OR sls_price <=0
	THEN sls_sales / NULLIF(sls_quantity,0)
	ELSE sls_price
END AS sls_price
FROM bronze.crm_sales_details

-- insert:
TRUNCATE TABLE silver.crm_sales_details
INSERT INTO silver.crm_sales_details(

sls_ord_num,
sls_prd_key,
sls_cust_id,
sls_order_dt,
sls_ship_dt,
sls_due_dt,
sls_sales,
sls_quantity,
sls_price

)
SELECT
sls_ord_num, 
sls_prd_key,
sls_cust_id,
CASE 
	WHEN sls_order_dt = 0 OR LEN(sls_order_dt) !=8 THEN NULL
	ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
END AS sls_order_dt,
CASE 
	WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) !=8 THEN NULL
	ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
END AS sls_ship_dt,
CASE 
	WHEN sls_due_dt = 0 OR LEN(sls_due_dt) !=8 THEN NULL
	ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
END AS sls_due_dt,
CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
	THEN sls_quantity * ABS(sls_price)
	ELSE sls_sales
END AS sls_sales,
sls_quantity,
CASE WHEN sls_price IS NULL OR sls_price <=0
	THEN sls_sales / NULLIF(sls_quantity,0)
	ELSE sls_price
END AS sls_price
FROM bronze.crm_sales_details


-- tabela 4
-- remove first characters from cid in order to connect with crm cust info
 
SELECT
CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LEN(cid)) 
ELSE cid
END AS cid,
bdate,
gen
FROM bronze.erp_cust_az12

-- check if we have date beyond range
SELECT *
FROM bronze.erp_cust_az12
WHERE bdate< '1924-01-01' or bdate > GETDATE()
--fix
SELECT
CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LEN(cid)) 
ELSE cid
END AS cid,
CASE WHEN bdate > GETDATE() THEN NULL
ELSE bdate
END AS bdate,
gen
FROM bronze.erp_cust_az12


-- gender

select distinct gen
from bronze.erp_cust_az12

-- fix

SELECT
CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LEN(cid)) 
ELSE cid
END AS cid,
CASE WHEN bdate > GETDATE() THEN NULL
ELSE bdate
END AS bdate,
CASE WHEN UPPER(TRIM(gen)) IN ('F','FEMALE') THEN 'Female'
	WHEN UPPER(TRIM(gen)) IN ('M','MALE') THEN 'Male'
	ELSE 'n/a'
END AS gen
FROM bronze.erp_cust_az12

-- insert
TRUNCATE TABLE silver.erp_cust_az12 
INSERT INTO silver.erp_cust_az12 
(cid,bdate,gen)
SELECT
CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LEN(cid)) 
ELSE cid
END AS cid,
CASE WHEN bdate > GETDATE() THEN NULL
ELSE bdate
END AS bdate,
CASE WHEN UPPER(TRIM(gen)) IN ('F','FEMALE') THEN 'Female'
	WHEN UPPER(TRIM(gen)) IN ('M','MALE') THEN 'Male'
	ELSE 'n/a'
END AS gen
FROM bronze.erp_cust_az12


-- TABELA 5:

SELECT
cid,
cntry
FROM bronze.erp_loc_a101;

-- get rid from - in cid in order to join with crm cust info
SELECT
REPLACE(cid,'-','') cid,
cntry
FROM bronze.erp_loc_a101;

-- data standardization and consistency

SELECT DISTINCT cntry
FROM bronze.erp_loc_a101
ORDER BY cntry

SELECT
REPLACE(cid,'-','') cid,

CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany'
	WHEN TRIM(cntry) IN ('US','USA') THEN 'United States'
	WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
	ELSE TRIM(cntry)
END AS cntry

FROM bronze.erp_loc_a101;

-- insert
TRUNCATE TABLE silver.erp_local_a101
INSERT INTO silver.erp_local_a101 (cid,cntry)
SELECT
REPLACE(cid,'-','') cid,

CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany'
	WHEN TRIM(cntry) IN ('US','USA') THEN 'United States'
	WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
	ELSE TRIM(cntry)
END AS cntry

FROM bronze.erp_loc_a101;

-- TABELA 6: 

SELECT
id,
cat,
subcat,
maintenance
FROM bronze.erp_px_cat_g1v2

-- check for unwanted spaces

SELECT * FROM bronze.erp_px_cat_g1v2
WHERE cat != TRIM(cat) or subcat != TRIM(subcat) OR maintenance != TRIM(maintenance)

-- data standardization and consistency
SELECT DISTINCT cat FROM bronze.erp_px_cat_g1v2
SELECT DISTINCT subcat FROM bronze.erp_px_cat_g1v2
SELECT DISTINCT maintenance FROM bronze.erp_px_cat_g1v2

-- insert
TRUNCATE TABLE silver.erp_px_cat_g1v2;
INSERT INTO silver.erp_px_cat_g1v2(id,cat,subcat,maintenance)
SELECT
id,
cat,
subcat,
maintenance
FROM bronze.erp_px_cat_g1v2







-- CREATE PROCEDURE
CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
	TRUNCATE TABLE silver.crm_cust_info;
	INSERT INTO silver.crm_cust_info(cst_id,cst_key,cst_firstname,cst_lastname,cst_material_status,cst_gndr,cst_creater_date)

	SELECT 
	cst_id,
	cst_key,
	TRIM(cst_firstname) as cst_firstname,
	TRIM(cst_lastname) as cst_lastname,
	CASE WHEN UPPER(TRIM(cst_material_status)) = 'S' THEN 'Single'
		WHEN UPPER(TRIM(cst_material_status)) = 'M' THEN 'Married'
		ELSE 'n/a' -- if its null
		END cst_material_status,
	CASE WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
		WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
		ELSE 'n/a' -- if its null
		END cst_gndr,


	cst_creater_date
	FROM(
	SELECT
	*,
	ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_creater_date DESC) as FLAG_LAST
	FROM bronze.crm_cust_info
	WHERE cst_id IS NOT NULL

	)t WHERE flag_last =1


	-- CHECK THE QUALITY OF SILVER:

	SELECT cst_id, COUNT(*) FROM 
	silver.crm_cust_info
	GROUP BY cst_id
	HAVING COUNT(*) > 1 OR cst_id IS NULL

	SELECT cst_key
	FROM silver.crm_cust_info
	WHERE cst_key!=TRIM(cst_key)

	SELECT DISTINCT cst_gndr
	FROM silver.crm_cust_info



	TRUNCATE TABLE silver.crm_prd_info
	INSERT INTO silver.crm_prd_info (
	prd_id, cat_id, prd_key, prd_nm, prd_cost, prd_line, prd_start_dt, prd_end_dt
	)
	SELECT
	prd_id,

	REPLACE(SUBSTRING(prd_key,1,5),'-','_') as cat_id,
	SUBSTRING(prd_key,7, LEN(prd_key)) as prd_key, -- we need to join with sales details
	prd_nm,
	ISNULL(prd_cost,0) AS prd_cost,
	CASE WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
		WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
		WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
		WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
		ELSE 'n/a'
		END AS prd_line,
	CAST(prd_start_dt AS DATE) AS prd_start_dt,
	CAST(LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt)-1  AS DATE)as prd_end_dt_test
	FROM bronze.crm_prd_info


	TRUNCATE TABLE silver.crm_sales_details
	INSERT INTO silver.crm_sales_details(

	sls_ord_num,
	sls_prd_key,
	sls_cust_id,
	sls_order_dt,
	sls_ship_dt,
	sls_due_dt,
	sls_sales,
	sls_quantity,
	sls_price

	)
	SELECT
	sls_ord_num, 
	sls_prd_key,
	sls_cust_id,
	CASE 
		WHEN sls_order_dt = 0 OR LEN(sls_order_dt) !=8 THEN NULL
		ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
	END AS sls_order_dt,
	CASE 
		WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) !=8 THEN NULL
		ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
	END AS sls_ship_dt,
	CASE 
		WHEN sls_due_dt = 0 OR LEN(sls_due_dt) !=8 THEN NULL
		ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
	END AS sls_due_dt,
	CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
		THEN sls_quantity * ABS(sls_price)
		ELSE sls_sales
	END AS sls_sales,
	sls_quantity,
	CASE WHEN sls_price IS NULL OR sls_price <=0
		THEN sls_sales / NULLIF(sls_quantity,0)
		ELSE sls_price
	END AS sls_price
	FROM bronze.crm_sales_details



	TRUNCATE TABLE silver.erp_cust_az12 
	INSERT INTO silver.erp_cust_az12 
	(cid,bdate,gen)
	SELECT
	CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LEN(cid)) 
	ELSE cid
	END AS cid,
	CASE WHEN bdate > GETDATE() THEN NULL
	ELSE bdate
	END AS bdate,
	CASE WHEN UPPER(TRIM(gen)) IN ('F','FEMALE') THEN 'Female'
		WHEN UPPER(TRIM(gen)) IN ('M','MALE') THEN 'Male'
		ELSE 'n/a'
	END AS gen
	FROM bronze.erp_cust_az12

	TRUNCATE TABLE silver.erp_local_a101
	INSERT INTO silver.erp_local_a101 (cid,cntry)
	SELECT
	REPLACE(cid,'-','') cid,

	CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany'
		WHEN TRIM(cntry) IN ('US','USA') THEN 'United States'
		WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
		ELSE TRIM(cntry)
	END AS cntry

	FROM bronze.erp_loc_a101;

	TRUNCATE TABLE silver.erp_px_cat_g1v2;
	INSERT INTO silver.erp_px_cat_g1v2(id,cat,subcat,maintenance)
	SELECT
	id,
	cat,
	subcat,
	maintenance
	FROM bronze.erp_px_cat_g1v2
END
EXEC silver.load_silver

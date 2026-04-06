
use DataWarehouse;


IF OBJECT_ID ('bronze.crm_cust_info','U') IS NOT NULL
DROP TABLE bronze.crm_cust_info
CREATE TABLE bronze.crm_cust_info
(
cst_id INT,
cst_key NVARCHAR(50),
cst_firstname NVARCHAR(50),
cst_lastname NVARCHAR(50),
cst_material_status NVARCHAR(50),
cst_gndr NVARCHAR(50),
cst_creater_date DATE
);
IF OBJECT_ID ('bronze.crm_prd_info','U') IS NOT NULL
DROP TABLE bronze.crm_prd_info
CREATE TABLE bronze.crm_prd_info (
prd_id INT,
prd_key NVARCHAR(50),
prd_nm NVARCHAR(50),
prd_cost INT,
prd_line NVARCHAR(50),
prd_start_dt DATETIME,
prd_end_dt DATETIME
);

IF OBJECT_ID ('bronze.crm_sales_details','U') IS NOT NULL
DROP TABLE bronze.crm_sales_details

CREATE TABLE bronze.crm_sales_details (
sls_ord_num NVARCHAR(50),
sls_prd_key NVARCHAR(50),
sls_cust_id INT,
sls_order_dt INT,
sls_ship_dt INT,
sls_due_dt INT,
sls_sales INT,
sls_quantity INT,
sls_price INT
);

IF OBJECT_ID ('bronze.erp_cust_az12','U') IS NOT NULL
DROP TABLE bronze.erp_cust_az12

CREATE TABLE bronze.erp_cust_az12(
cid NVARCHAR(50),
bdate DATE,
gen NVARCHAR(20)
);


IF OBJECT_ID ('bronze.erp_loc_a101','U') IS NOT NULL
DROP TABLE bronze.erp_loc_a101


CREATE TABLE bronze.erp_loc_a101(
cid NVARCHAR(50),
cntry NVARCHAR(50)
);


IF OBJECT_ID ('bronze.erp_px_cat_g1v2','U') IS NOT NULL
DROP TABLE bronze.erp_px_cat_g1v2


CREATE TABLE bronze.erp_px_cat_g1v2(
id NVARCHAR(50),
cat NVARCHAR(50),
subcat NVARCHAR(50),
maintenance NVARCHAR(30)
);


CREATE OR ALTER PROCEDURE bronze.load_bronze AS 
	BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
		BEGIN TRY

		SET @batch_start_time = GETDATE();
		
			PRINT '==========================================';
			PRINT 'Loading Bronze Layer';
			PRINT '==========================================';
			PRINT'------------------------------------------';
			PRINT 'Loading CRM Tables';
			PRINT'------------------------------------------';

		SET @start_time = GETDATE();
		PRINT '>> Truncating table ';
		TRUNCATE TABLE bronze.crm_cust_info; -- first make the table empty then load. This is FULL LOAD

		PRINT '>> Inserting Data';
		BULK INSERT bronze.crm_cust_info
		FROM 'C:\Users\lenovo\Desktop\Udemy\SQL-Udemy-Course\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
		WITH (
		FIRSTROW = 2, -- SKIP THE FIRST ROW BECAUSE THEY ARE THE NAME OF FIELDS
		FIELDTERMINATOR = ',',
		TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + ' SECONDS';

		

		SET @start_time = GETDATE();
		TRUNCATE TABLE bronze.crm_prd_info; -- first make the table empty then load. This is FULL LOAD

		BULK INSERT bronze.crm_prd_info
		FROM 'C:\Users\lenovo\Desktop\Udemy\SQL-Udemy-Course\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
		WITH (
		FIRSTROW = 2, -- SKIP THE FIRST ROW BECAUSE THEY ARE THE NAME OF FIELDS
		FIELDTERMINATOR = ',',
		TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + ' SECONDS';
		
		SET @start_time = GETDATE();
		TRUNCATE TABLE bronze.crm_sales_details; -- first make the table empty then load. This is FULL LOAD

		BULK INSERT bronze.crm_sales_details
		FROM 'C:\Users\lenovo\Desktop\Udemy\SQL-Udemy-Course\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
		WITH (
		FIRSTROW = 2, -- SKIP THE FIRST ROW BECAUSE THEY ARE THE NAME OF FIELDS
		FIELDTERMINATOR = ',',
		TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + ' SECONDS';

		SET @start_time = GETDATE();
		TRUNCATE TABLE bronze.erp_cust_az12; -- first make the table empty then load. This is FULL LOAD

		BULK INSERT bronze.erp_cust_az12
		FROM 'C:\Users\lenovo\Desktop\Udemy\SQL-Udemy-Course\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\cust_az12.csv'
		WITH (
		FIRSTROW = 2, -- SKIP THE FIRST ROW BECAUSE THEY ARE THE NAME OF FIELDS
		FIELDTERMINATOR = ',',
		TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + ' SECONDS';


		SET @start_time = GETDATE();
		TRUNCATE TABLE bronze.erp_loc_a101; -- first make the table empty then load. This is FULL LOAD

		BULK INSERT bronze.erp_loc_a101
		FROM 'C:\Users\lenovo\Desktop\Udemy\SQL-Udemy-Course\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\loc_a101.csv'
		WITH (
		FIRSTROW = 2, -- SKIP THE FIRST ROW BECAUSE THEY ARE THE NAME OF FIELDS
		FIELDTERMINATOR = ',',
		TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + ' SECONDS';

		SET @start_time = GETDATE();
		TRUNCATE TABLE bronze.erp_px_cat_g1v2; -- first make the table empty then load. This is FULL LOAD

		BULK INSERT bronze.erp_px_cat_g1v2
		FROM 'C:\Users\lenovo\Desktop\Udemy\SQL-Udemy-Course\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\px_cat_g1v2.csv'
		WITH (
		FIRSTROW = 2, -- SKIP THE FIRST ROW BECAUSE THEY ARE THE NAME OF FIELDS
		FIELDTERMINATOR = ',',
		TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + ' SECONDS';
		SET @batch_end_time = GETDATE();
		PRINT 'Loading Bronze Layer is Completed';
		PRINT 'Total Duration: ' + CAST(DATEDIFF(SECOND,@batch_start_time,@batch_end_time) AS NVARCHAR) + ' seconds';
	END TRY
	BEGIN CATCH
		PRINT '===================================';
		PRINT 'ERROR OCURRED DURING LOADING BRONZE LAYER';
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Message '+ CAST(ERROR_NUMBER() AS NVARCHAR);
		PRINT '===================================';
	END CATCH

END


EXEC bronze.load_bronze

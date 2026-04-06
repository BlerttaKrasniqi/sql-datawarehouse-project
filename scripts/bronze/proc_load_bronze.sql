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

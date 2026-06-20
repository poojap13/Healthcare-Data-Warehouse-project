CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
    DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
    BEGIN TRY
        SET @batch_start_time = GETDATE();
        PRINT '================================================';
        PRINT 'Loading Bronze Layer';
        PRINT '================================================';

        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: bronze.patients';
        TRUNCATE TABLE bronze.patients;
        PRINT '>> Inserting Data Into: bronze.patients';
        BULK INSERT bronze.patients
        FROM 'C:\Users\pooja\Desktop\Healthcare_Dataware_sql\dataset\new_dataset\patients.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '0x0a',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: bronze.encounters';
        TRUNCATE TABLE bronze.encounters;
        PRINT '>> Inserting Data Into: bronze.encounters';
        BULK INSERT bronze.encounters
        FROM 'C:\Users\pooja\Desktop\Healthcare_Dataware_sql\dataset\new_dataset\encounters.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '0x0a',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: bronze.conditions';
        TRUNCATE TABLE bronze.conditions;
        PRINT '>> Inserting Data Into: bronze.conditions';
        BULK INSERT bronze.conditions
        FROM 'C:\Users\pooja\Desktop\Healthcare_Dataware_sql\dataset\new_dataset\conditions.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '0x0a',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: bronze.organizations';
        TRUNCATE TABLE bronze.organizations;
        PRINT '>> Inserting Data Into: bronze.organizations';
        BULK INSERT bronze.organizations
        FROM 'C:\Users\pooja\Desktop\Healthcare_Dataware_sql\dataset\new_dataset\organizations.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '0x0a',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: bronze.payers';
        TRUNCATE TABLE bronze.payers;
        PRINT '>> Inserting Data Into: bronze.payers';
        BULK INSERT bronze.payers
        FROM 'C:\Users\pooja\Desktop\Healthcare_Dataware_sql\dataset\new_dataset\payers.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '0x0a',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        SET @batch_end_time = GETDATE();
        PRINT '==========================================';
        PRINT 'Loading Bronze Layer is Completed';
        PRINT '   - Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
        PRINT '==========================================';
    END TRY
    BEGIN CATCH
        PRINT '==========================================';
        PRINT 'ERROR OCCURRED DURING LOADING BRONZE LAYER';
        PRINT 'Error Message' + ERROR_MESSAGE();
        PRINT 'Error Message' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error Message' + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT '==========================================';
    END CATCH
END


--------------------------------------------
EXEC bronze.load_bronze;



----------------------------------Data quality check-----------
SELECT 'patients' AS table_name, COUNT(*) AS row_count FROM bronze.patients
UNION ALL
SELECT 'encounters', COUNT(*) FROM bronze.encounters
UNION ALL
SELECT 'conditions', COUNT(*) FROM bronze.conditions
UNION ALL
SELECT 'organizations', COUNT(*) FROM bronze.organizations
UNION ALL
SELECT 'payers', COUNT(*) FROM bronze.payers;


SELECT TOP 5 * FROM bronze.patients;
SELECT TOP 5 * FROM bronze.encounters;
SELECT TOP 5 * FROM bronze.conditions;
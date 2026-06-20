CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
    DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
    BEGIN TRY
        SET @batch_start_time = GETDATE();
        PRINT '================================================';
        PRINT 'Loading Silver Layer';
        PRINT '================================================';

        -- patients
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.patients';
        TRUNCATE TABLE silver.patients;
        PRINT '>> Inserting Data Into: silver.patients';
        INSERT INTO silver.patients (
            Id, BIRTHDATE, DEATHDATE, FIRST, LAST,
            MARITAL_STATUS, RACE, ETHNICITY, GENDER,
            CITY, STATE, ZIP,
            HEALTHCARE_EXPENSES, HEALTHCARE_COVERAGE, INCOME,
            dwh_create_date
        )
        SELECT
            Id,
            BIRTHDATE,
            DEATHDATE,
            TRIM(FIRST),
            TRIM(LAST),
            CASE 
                WHEN UPPER(TRIM(MARITAL)) = 'M' THEN 'Married'
                WHEN UPPER(TRIM(MARITAL)) = 'D' THEN 'Divorced'
                WHEN UPPER(TRIM(MARITAL)) = 'S' THEN 'Single'
                WHEN UPPER(TRIM(MARITAL)) = 'W' THEN 'Widowed'
                ELSE 'n/a'
            END,
            TRIM(RACE),
            TRIM(ETHNICITY),
            CASE 
                WHEN UPPER(TRIM(GENDER)) = 'F' THEN 'Female'
                WHEN UPPER(TRIM(GENDER)) = 'M' THEN 'Male'
                ELSE 'n/a'
            END,
            TRIM(CITY),
            TRIM(STATE),
            NULLIF(ZIP, '00000'),
            HEALTHCARE_EXPENSES,
            HEALTHCARE_COVERAGE,
            INCOME,
            GETDATE()
        FROM bronze.patients
        WHERE Id IS NOT NULL;
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        -- encounters
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.encounters';
        TRUNCATE TABLE silver.encounters;
        PRINT '>> Inserting Data Into: silver.encounters';
        INSERT INTO silver.encounters (
            Id, START, STOP, PATIENT, ORGANIZATION, PAYER,
            ENCOUNTERCLASS, DESCRIPTION,
            BASE_ENCOUNTER_COST, TOTAL_CLAIM_COST, PAYER_COVERAGE,
            dwh_create_date
        )
        SELECT
            Id,
            START,
            STOP,
            PATIENT,
            ORGANIZATION,
            PAYER,
            CASE 
                WHEN ENCOUNTERCLASS IS NULL OR TRIM(ENCOUNTERCLASS) = '' THEN 'n/a'
                ELSE UPPER(LEFT(TRIM(ENCOUNTERCLASS), 1)) + LOWER(SUBSTRING(TRIM(ENCOUNTERCLASS), 2, LEN(ENCOUNTERCLASS)))
            END,
            TRIM(DESCRIPTION),
            BASE_ENCOUNTER_COST,
            TOTAL_CLAIM_COST,
            PAYER_COVERAGE,
            GETDATE()
        FROM bronze.encounters
        WHERE Id IS NOT NULL AND PATIENT IS NOT NULL;
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        -- conditions
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.conditions';
        TRUNCATE TABLE silver.conditions;
        PRINT '>> Inserting Data Into: silver.conditions';
        INSERT INTO silver.conditions (
            START, STOP, PATIENT, ENCOUNTER, CODE, DESCRIPTION, dwh_create_date
        )
        SELECT
            START,
            STOP,
            PATIENT,
            ENCOUNTER,
            CODE,
            TRIM(DESCRIPTION),
            GETDATE()
        FROM bronze.conditions
        WHERE PATIENT IS NOT NULL AND ENCOUNTER IS NOT NULL;
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        -- organizations
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.organizations';
        TRUNCATE TABLE silver.organizations;
        PRINT '>> Inserting Data Into: silver.organizations';
        INSERT INTO silver.organizations (
            Id, NAME, CITY, STATE, ZIP, UTILIZATION, dwh_create_date
        )
        SELECT
            Id,
            TRIM(NAME),
            TRIM(CITY),
            TRIM(STATE),
            ZIP,
            UTILIZATION,
            GETDATE()
        FROM bronze.organizations
        WHERE Id IS NOT NULL;
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        -- payers
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.payers';
        TRUNCATE TABLE silver.payers;
        PRINT '>> Inserting Data Into: silver.payers';
        INSERT INTO silver.payers (
            Id, NAME, OWNERSHIP, AMOUNT_COVERED, AMOUNT_UNCOVERED,
            COVERED_ENCOUNTERS, UNCOVERED_ENCOUNTERS, UNIQUE_CUSTOMERS,
            dwh_create_date
        )
        SELECT
            Id,
            TRIM(NAME),
            TRIM(OWNERSHIP),
            AMOUNT_COVERED,
            AMOUNT_UNCOVERED,
            COVERED_ENCOUNTERS,
            UNCOVERED_ENCOUNTERS,
            UNIQUE_CUSTOMERS,
            GETDATE()
        FROM bronze.payers
        WHERE Id IS NOT NULL;
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        SET @batch_end_time = GETDATE();
        PRINT '==========================================';
        PRINT 'Loading Silver Layer is Completed';
        PRINT '   - Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
        PRINT '==========================================';
    END TRY
    BEGIN CATCH
        PRINT '==========================================';
        PRINT 'ERROR OCCURRED DURING LOADING SILVER LAYER';
        PRINT 'Error Message' + ERROR_MESSAGE();
        PRINT 'Error Message' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error Message' + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT '==========================================';
    END CATCH
END
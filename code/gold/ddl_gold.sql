-- ===========================================
-- GOLD VIEW: Demographics
-- ===========================================
IF OBJECT_ID('gold.vw_demographics', 'V') IS NOT NULL
    DROP VIEW gold.vw_demographics;
GO

CREATE VIEW gold.vw_demographics AS
SELECT
    GENDER,
    RACE,
    ETHNICITY,
    MARITAL_STATUS,
    CASE 
        WHEN DATEDIFF(YEAR, BIRTHDATE, GETDATE()) < 18 THEN 'Under 18'
        WHEN DATEDIFF(YEAR, BIRTHDATE, GETDATE()) BETWEEN 18 AND 34 THEN '18-34'
        WHEN DATEDIFF(YEAR, BIRTHDATE, GETDATE()) BETWEEN 35 AND 54 THEN '35-54'
        WHEN DATEDIFF(YEAR, BIRTHDATE, GETDATE()) BETWEEN 55 AND 74 THEN '55-74'
        ELSE '75+'
    END AS AGE_GROUP,
    STATE,
    COUNT(*) AS PATIENT_COUNT,
    AVG(INCOME) AS AVG_INCOME
FROM silver.patients
GROUP BY 
    GENDER, RACE, ETHNICITY, MARITAL_STATUS,
    CASE 
        WHEN DATEDIFF(YEAR, BIRTHDATE, GETDATE()) < 18 THEN 'Under 18'
        WHEN DATEDIFF(YEAR, BIRTHDATE, GETDATE()) BETWEEN 18 AND 34 THEN '18-34'
        WHEN DATEDIFF(YEAR, BIRTHDATE, GETDATE()) BETWEEN 35 AND 54 THEN '35-54'
        WHEN DATEDIFF(YEAR, BIRTHDATE, GETDATE()) BETWEEN 55 AND 74 THEN '55-74'
        ELSE '75+'
    END,
    STATE;
GO

-- ===========================================
-- GOLD VIEW: Costs
-- ===========================================
IF OBJECT_ID('gold.vw_costs', 'V') IS NOT NULL
    DROP VIEW gold.vw_costs;
GO

CREATE VIEW gold.vw_costs AS
SELECT
    e.ENCOUNTERCLASS,
    FORMAT(e.START, 'yyyy-MM') AS ENCOUNTER_MONTH,
    p.NAME AS PAYER_NAME,
    o.NAME AS ORGANIZATION_NAME,
    COUNT(*) AS ENCOUNTER_COUNT,
    AVG(e.BASE_ENCOUNTER_COST) AS AVG_BASE_COST,
    AVG(e.TOTAL_CLAIM_COST) AS AVG_TOTAL_CLAIM_COST,
    SUM(e.TOTAL_CLAIM_COST) AS TOTAL_CLAIM_COST,
    SUM(e.PAYER_COVERAGE) AS TOTAL_PAYER_COVERAGE,
    SUM(e.TOTAL_CLAIM_COST - e.PAYER_COVERAGE) AS TOTAL_UNCOVERED_COST
FROM silver.encounters e
LEFT JOIN silver.payers p ON e.PAYER = p.Id
LEFT JOIN silver.organizations o ON e.ORGANIZATION = o.Id
GROUP BY
    e.ENCOUNTERCLASS,
    FORMAT(e.START, 'yyyy-MM'),
    p.NAME,
    o.NAME;
GO

-- ===========================================
-- GOLD VIEW: Conditions
-- ===========================================
IF OBJECT_ID('gold.vw_conditions', 'V') IS NOT NULL
    DROP VIEW gold.vw_conditions;
GO

CREATE VIEW gold.vw_conditions AS
SELECT
    c.DESCRIPTION AS CONDITION_NAME,
    c.CODE,
    p.GENDER,
    CASE 
        WHEN DATEDIFF(YEAR, p.BIRTHDATE, c.START) < 18 THEN 'Under 18'
        WHEN DATEDIFF(YEAR, p.BIRTHDATE, c.START) BETWEEN 18 AND 34 THEN '18-34'
        WHEN DATEDIFF(YEAR, p.BIRTHDATE, c.START) BETWEEN 35 AND 54 THEN '35-54'
        WHEN DATEDIFF(YEAR, p.BIRTHDATE, c.START) BETWEEN 55 AND 74 THEN '55-74'
        ELSE '75+'
    END AS AGE_AT_DIAGNOSIS,
    CASE WHEN c.STOP IS NULL THEN 'Active' ELSE 'Resolved' END AS CONDITION_STATUS,
    COUNT(*) AS DIAGNOSIS_COUNT,
    COUNT(DISTINCT c.PATIENT) AS UNIQUE_PATIENTS
FROM silver.conditions c
LEFT JOIN silver.patients p ON c.PATIENT = p.Id
GROUP BY 
    c.DESCRIPTION,
    c.CODE,
    p.GENDER,
    CASE 
        WHEN DATEDIFF(YEAR, p.BIRTHDATE, c.START) < 18 THEN 'Under 18'
        WHEN DATEDIFF(YEAR, p.BIRTHDATE, c.START) BETWEEN 18 AND 34 THEN '18-34'
        WHEN DATEDIFF(YEAR, p.BIRTHDATE, c.START) BETWEEN 35 AND 54 THEN '35-54'
        WHEN DATEDIFF(YEAR, p.BIRTHDATE, c.START) BETWEEN 55 AND 74 THEN '55-74'
        ELSE '75+'
    END,
    CASE WHEN c.STOP IS NULL THEN 'Active' ELSE 'Resolved' END;
GO
-- ===========================================
-- SETUP: Database and Schemas
-- ===========================================
USE master;
GO

CREATE DATABASE HealthcareDataWarehouse;
GO

USE HealthcareDataWarehouse;
GO

CREATE SCHEMA bronze;
GO
CREATE SCHEMA silver;
GO
CREATE SCHEMA gold;
GO

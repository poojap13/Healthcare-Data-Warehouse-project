# Data Catalog for Gold Layer

## Overview
The Gold Layer is the business-level data representation for the Healthcare Data Warehouse project, structured to support analytical and reporting use cases. It consists of three views, each answering a specific business question: who are our patients (demographics), where is money going (costs), and what's actually wrong with people (conditions).

---

### 1. **gold.vw_demographics**
- **Purpose:** Summarizes the patient population by demographic and geographic attributes, with average income per group. Answers "who are our patients."
- **Columns:**

| Column Name      | Data Type     | Description                                                                                   |
|-------------------|---------------|-----------------------------------------------------------------------------------------------|
| GENDER            | NVARCHAR(10)  | Patient gender, standardized to 'Female', 'Male', or 'n/a'.                                   |
| RACE              | NVARCHAR(50)  | Patient race as recorded in the source data (e.g., 'white', 'asian', 'black').               |
| ETHNICITY         | NVARCHAR(50)  | Patient ethnicity (e.g., 'hispanic', 'nonhispanic').                                          |
| MARITAL_STATUS    | NVARCHAR(20)  | Standardized marital status ('Married', 'Single', 'Divorced', 'Widowed', or 'n/a').           |
| AGE_GROUP         | NVARCHAR(20)  | Patient's current age bucket, calculated from birthdate ('Under 18', '18-34', '35-54', '55-74', '75+'). |
| STATE             | NVARCHAR(50)  | Patient's state of residence.                                                                 |
| PATIENT_COUNT     | INT           | Number of patients in this demographic group.                                                 |
| AVG_INCOME        | FLOAT         | Average reported income for patients in this group.                                           |

- **Notes:** Several groups have very small patient counts (n=1 or n=2) given the 111-patient sample size, so `AVG_INCOME` can be skewed by outliers in small groups — worth flagging in analysis rather than treating every average as reliable.

---

### 2. **gold.vw_costs**
- **Purpose:** Summarizes encounter costs by type, month, payer, and facility — including how much of each cost was actually covered by insurance. Answers "where is the money going, and who's paying for it."
- **Columns:**

| Column Name           | Data Type     | Description                                                                                   |
|------------------------|---------------|-----------------------------------------------------------------------------------------------|
| ENCOUNTERCLASS         | NVARCHAR(20)  | Type of visit (e.g., 'Ambulatory', 'Emergency', 'Inpatient', 'Wellness'), capitalized for readability. |
| ENCOUNTER_MONTH        | NVARCHAR(7)   | The year and month the encounter occurred, formatted as 'YYYY-MM'.                            |
| PAYER_NAME             | NVARCHAR(100) | Name of the insurance payer (e.g., 'Medicare', 'Humana'), or 'NO_INSURANCE' if uninsured.     |
| ORGANIZATION_NAME      | NVARCHAR(200) | Name of the healthcare facility where the encounter took place.                               |
| ENCOUNTER_COUNT        | INT           | Number of encounters in this group.                                                           |
| AVG_BASE_COST          | FLOAT         | Average base encounter cost (the standard fee before claim adjustments).                      |
| AVG_TOTAL_CLAIM_COST   | FLOAT         | Average total billed cost per encounter in this group.                                        |
| TOTAL_CLAIM_COST       | FLOAT         | Sum of all billed costs for this group.                                                       |
| TOTAL_PAYER_COVERAGE   | FLOAT         | Sum of the amount insurance actually covered for this group.                                  |
| TOTAL_UNCOVERED_COST   | FLOAT         | Total claim cost minus payer coverage — the out-of-pocket/unpaid burden for this group.        |

- **Key finding:** Encounters with `PAYER_NAME = 'NO_INSURANCE'` dominate the highest `TOTAL_UNCOVERED_COST` rows, confirming that lack of insurance — not just treatment cost — is the primary driver of unpaid medical bills in this dataset.

---

### 3. **gold.vw_conditions**
- **Purpose:** Summarizes diagnosed conditions by demographic group, age at diagnosis, and whether the condition is still active. Answers "what's actually wrong with our patients, and who does it affect."
- **Columns:**

| Column Name        | Data Type     | Description                                                                                   |
|----------------------|---------------|-----------------------------------------------------------------------------------------------|
| CONDITION_NAME       | NVARCHAR(200) | Human-readable name of the diagnosis (e.g., 'Prediabetes (finding)', 'Anemia (disorder)').     |
| CODE                 | NVARCHAR(50)  | SNOMED clinical code for the condition.                                                       |
| GENDER               | NVARCHAR(10)  | Gender of the diagnosed patient.                                                               |
| AGE_AT_DIAGNOSIS      | NVARCHAR(20)  | Patient's age bucket *at the time the condition started* (not their current age).             |
| CONDITION_STATUS     | NVARCHAR(10)  | 'Active' if the condition has no recorded end date, 'Resolved' if it does.                    |
| DIAGNOSIS_COUNT      | INT           | Number of times this condition was diagnosed within this group.                               |
| UNIQUE_PATIENTS      | INT           | Number of distinct patients affected, within this group.                                      |

- **Notes:** `AGE_AT_DIAGNOSIS` is deliberately calculated from the condition's start date rather than the patient's current age, since a patient's age today can be very different from their age when an older condition was first recorded.

---

## How These Connect
All three views are built on top of the **Silver layer**, joining `silver.encounters` (the fact table) out to `silver.patients`, `silver.organizations`, and `silver.payers` (the dimension tables) — a textbook star schema. See `docs/data_integration.png` for the full table relationship diagram.

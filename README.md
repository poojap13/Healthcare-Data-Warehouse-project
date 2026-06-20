# Healthcare Data Warehouse Project

A SQL Server data warehouse built on synthetic patient data, using the **medallion architecture** (Bronze → Silver → Gold) to turn raw, fragmented healthcare records into clean, decision-ready insights on patient demographics, encounter costs, and diagnosed conditions.

---

## Problem Statement

Healthcare organizations typically have patient data scattered across multiple sources — patient demographics in one system, visit/encounter records in another, diagnosis codes and insurance/billing data elsewhere. In raw form, this data is too fragmented and inconsistent to answer real operational questions like:

- Who are our patients, and how does that vary by region or demographic group?
- Where is healthcare spending actually going, and who is absorbing the cost when insurance doesn't cover it?
- What conditions are most common in our patient population, and who do they affect?

This project builds a data warehouse that pulls that scattered data together, cleans it, and exposes it through three reporting-ready views built specifically to answer those three questions.

---

## Architecture

This project follows the **medallion architecture** — three layers, each with a distinct responsibility:

| Layer | Purpose | Object Type |
|-------|---------|--------------|
| **Bronze** | Raw data, loaded exactly as it arrives from source CSVs. No cleaning, no transformations. Exists so the original source is always recoverable. | Tables |
| **Silver** | Cleaned, standardized, de-identified data. Inconsistent codes are translated to readable values, irrelevant/sensitive columns are dropped, and types are corrected to match the real shape of the data. | Tables |
| **Gold** | Business-ready views, built by joining and aggregating Silver tables to directly answer the three questions in the problem statement above. | Views |

See `docs/data_architecture.png` for the high-level flow and `docs/data_integration.png` for how the individual tables relate to each other (which tables are the fact table vs. dimension tables).

---

## Tech Stack

- **Database engine:** Microsoft SQL Server (T-SQL), managed via SQL Server Management Studio (SSMS)
- **Source data:** [Synthea](https://synthetichealth.github.io/synthea/) — open-source synthetic patient data generator (no real PHI; safe to use and share publicly)
- **Loading method:** `BULK INSERT` wrapped in stored procedures, with full TRY/CATCH error handling and load-duration logging

---

## Dataset

Synthea's "100 Sample Synthetic Patient Records" CSV export, scoped down to the five source files relevant to this project's three KPI categories:

| File | Rows Loaded | Maps To |
|------|-------------|---------|
| `patients.csv` | 111 | Demographics |
| `encounters.csv` | 6,032 | Costs |
| `conditions.csv` | 3,817 | Conditions |
| `organizations.csv` | 291 | Costs (facility dimension) |
| `payers.csv` | 10 | Costs (payer dimension) |

Other Synthea files (medications, procedures, immunizations, claims, etc.) were intentionally excluded — they don't map to the three KPI categories this project targets, and including them would have added scope without adding insight.

---

## Project Structure

```
healthcare-data-warehouse-project/
│
├── datasets/
│   └── new_dataset/              # raw Synthea CSV files
│       ├── patients.csv
│       ├── encounters.csv
│       ├── conditions.csv
│       ├── organizations.csv
│       └── payers.csv
│
├── docs/
│   ├── data_architecture.png     # high-level Bronze/Silver/Gold flow
│   ├── data_integration.png      # table relationships (fact/dimension)
│   └── data_catalog.md           # column-level documentation of all Gold views
│
├── scripts/
│   ├── init_database.sql         # creates the database and bronze/silver/gold schemas
│   │
│   ├── bronze/
│   │   ├── ddl_bronze.sql        # CREATE TABLE statements for all 5 raw tables
│   │   └── proc_load_bronze.sql  # bronze.load_bronze — truncates + reloads all 5 tables
│   │
│   ├── silver/
│   │   ├── ddl_silver.sql        # CREATE TABLE statements for cleaned tables
│   │   └── proc_load_silver.sql  # silver.load_silver — cleans Bronze into Silver
│   │
│   └── gold/
│       └── ddl_gold.sql          # CREATE VIEW statements for all 3 KPI views
│
└── README.md
```

---

## Data Model

The Gold layer follows a **star schema**: `silver.encounters` is the fact table (one row per patient visit, with the cost numbers), and `silver.patients`, `silver.organizations`, and `silver.payers` are dimension tables joined in to provide context. `silver.conditions` joins back to both `patients` and `encounters` to attribute diagnoses to the right person and visit.

```
Fact table:        silver.encounters
Dimension tables:   silver.patients, silver.organizations, silver.payers
```

---

## ETL Process

1. **`init_database.sql`** creates the database and the three schemas (`bronze`, `silver`, `gold`).
2. **`bronze/ddl_bronze.sql`** creates five empty raw tables, matching the exact column names and order of the source CSVs.
3. **`bronze/proc_load_bronze.sql`** defines `bronze.load_bronze`, a stored procedure that truncates and reloads all five Bronze tables from the CSV files using `BULK INSERT`. Logs load duration per table and reports errors via TRY/CATCH.
4. **`silver/ddl_silver.sql`** creates five cleaned Silver tables — fewer columns than Bronze, since sensitive/irrelevant fields (SSN, driver's license, raw provider IDs, etc.) are deliberately excluded.
5. **`silver/proc_load_silver.sql`** defines `silver.load_silver`, which cleans Bronze data into Silver: trims whitespace, standardizes coded values (e.g. `'F'` → `'Female'`, `'M'` marital status → `'Married'`), drops rows with missing required keys, and converts placeholder values (e.g. ZIP `'00000'`) to proper NULLs.
6. **`gold/ddl_gold.sql`** creates three views — `vw_demographics`, `vw_costs`, `vw_conditions` — that join and aggregate Silver tables. Views, not tables, since Gold should always reflect the current state of Silver without a separate load step.

**To refresh the entire warehouse after this initial setup:**
```sql
EXEC bronze.load_bronze;
EXEC silver.load_silver;
-- Gold views update automatically — no separate load needed
```

---

## Key Findings

### Demographics (`gold.vw_demographics`)
The largest single patient segment is **Female, white, married, 35-54, Massachusetts**, with an average income of roughly $176,500. However, with only 111 total patients, many demographic groups have a sample size of 1-2 patients — meaning their average income figures are easily skewed by a single outlier and shouldn't be treated as statistically reliable without a larger dataset or a minimum group-size threshold.

### Costs (`gold.vw_costs`)
Encounters with **no insurance coverage** (`PAYER_NAME = 'NO_INSURANCE'`) dominate the highest-uncovered-cost rows in the dataset — one ambulatory encounter category alone shows **$44,050.92** in total uncovered cost. This confirms that lack of insurance, rather than the underlying treatment cost itself, is the primary driver of unpaid medical bills in this population. Even insured encounters (Humana, Aetna, etc.) show meaningful uncovered amounts in emergency and inpatient categories, where total claim costs are highest.

### Conditions (`gold.vw_conditions`)
Built to calculate each patient's **age at the time of diagnosis** rather than their current age — a deliberate design choice, since using current age would misrepresent when older or resolved conditions actually occurred. The view also distinguishes **Active** vs. **Resolved** conditions based on whether an end date is recorded, which matters for understanding ongoing vs. historical patient health burden.

---

## What I Learned

- Bulk-loading real-world export data (even synthetic data) surfaces messy edge cases that clean tutorial datasets don't — Unix-style line endings causing `BULK INSERT` to fail, inconsistent casing in source column names, and mixed data types in columns that look numeric but contain text (e.g. `sls_price`-style cost fields needing `NVARCHAR` instead of `INT` in Bronze, deferring proper numeric conversion to Silver).
- Designing Silver around a known set of Gold outputs (rather than cleaning everything indiscriminately) is both faster and more defensible — every column-keep/drop decision in Silver was made by working backward from the three Gold views this project needed to produce.
- Small sample sizes distort aggregate metrics in ways that are easy to miss if you only look at the summary numbers — checking `COUNT(*)` alongside any `AVG()` is essential before treating a group's average as meaningful.

---

## Future Improvements

- Expand beyond the 5 source files used here (e.g. incorporate `medications.csv` or `procedures.csv`) for a richer set of KPIs.
- Add a minimum group-size filter to the demographics view to suppress unreliable averages from very small patient groups.
- Build a lightweight dashboard (Power BI or a simple web front end) on top of the three Gold views for visual reporting.

---

## How to Run This Project

1. Install SQL Server (Express or Developer edition) and SQL Server Management Studio (SSMS).
2. Download the [Synthea 100-patient sample CSV dataset](https://synthetichealth.github.io/synthea-sample-data/downloads/latest/synthea_sample_data_csv_latest.zip) and place the relevant CSVs in `datasets/new_dataset/`.
3. Run `scripts/init_database.sql`.
4. Run `scripts/bronze/ddl_bronze.sql`, then `scripts/bronze/proc_load_bronze.sql`, then `EXEC bronze.load_bronze;` — update the file paths in the procedure to match your local CSV location first.
5. Run `scripts/silver/ddl_silver.sql`, then `scripts/silver/proc_load_silver.sql`, then `EXEC silver.load_silver;`.
6. Run `scripts/gold/ddl_gold.sql`.
7. Query the Gold views directly, e.g.:
   ```sql
   SELECT * FROM gold.vw_costs ORDER BY TOTAL_UNCOVERED_COST DESC;
   ```

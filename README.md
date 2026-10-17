# Retail Sales Data Warehouse (RetailDWH)
**Author:** Mahmoud 

## 1. Runbook & Deployment Guide
This repository contains the foundational DDL and staging architecture for the RetailDWH project. 

**Prerequisites:**
* SQL Server 2016 or later (required for `DROP TABLE IF EXISTS` syntax).
* The provided `ProductCatalog_Batch1.csv` file available for staging load.

**Execution Order (Must be run sequentially):**
1. `01_Create_OLTP_Source.sql` (Provided material - creates source `RetailOLTP`)
2. `01b_Insert_OLTP_Sample_Data.sql` (Provided material - populates source)
3. `02_create_database_and_schemas.sql` (Creates `RetailDWH` and `stg`, `dim`, `fact`, `etl` schemas)
4. `03_staging_ddl.sql` (Creates empty staging tables)
5. `04_dimensions_ddl.sql` (Creates empty dimensions; MUST run before fact)
6. `05_fact_sales_ddl.sql` (Creates empty fact table with FK constraints)
7. `06_validation_queries.sql` (Execution baseline and DWH reporting validation)

*Note: Staging tables use a drop-and-create strategy for full-refresh isolation. Dimensions and Facts use `IF OBJECT_ID IS NULL` to protect data, meaning schema changes require manual drops or explicit `ALTER` statements.*

---

## 2. Source Profiling & Staging Policy
* **Staging Strategy:** A full-refresh snapshot approach is used for Sprint 01. 
* **NULL Policy:** All staging columns are intentionally declared as `NULLable` (even if source business keys are `NOT NULL`). This is a deliberate design choice to prevent the ETL pipeline from crashing during extraction. Data quality validation (e.g., catching missing IDs) will be handled downstream before loading into the dimensional layer.
* **Audit Columns:** To ensure consistency across the warehouse, the tracking column is standardized as `LoadedAt (DATETIME2(3))` across all staging, dimension, and fact tables.

---

## 3. Dimensional Modeling Decisions & Business Rules

### Fact Table Grain & Measures
* **Documented Grain:** Exactly **one row per source order line**. The `SourceOrderLineID` column has a `UNIQUE` constraint to enforce this grain and prevent duplicate loads.
* **Degenerate Dimension (OrderID):** `OrderID` is kept directly in `FactSales`. It contains no descriptive attributes of its own but is required to group order lines together for market basket analysis. A separate `DimOrder` table would cause unnecessary overhead.
* **Measure Nullability:** Fact measures (`Quantity`, `UnitPrice`, etc.) will be strictly enforced as `NOT NULL` during the ETL load process. 
* **Revenue Filtering:** Only source orders with `OrderStatus = 'Completed'` contribute to `FactSales`. Pending/Cancelled orders are excluded.

### Slowly Changing Dimension (SCD) Policies
* **DimCustomer & DimStore (SCD Type 1):** Changes to customer or store attributes (e.g., location, email) simply overwrite the existing record. No history is retained.
* **DimProduct (SCD Type 2):** Preserves pricing and attribute history. `ProductID` is non-unique to allow multiple historical versions.
  * **Triggers:** A new version is triggered if `UnitCost`, `Category`, `Brand`, or `IsActive` changes. 
  * **IsActive Status:** `IsActive` represents the product's operational business status. It is treated as a standard tracked attribute, completely independent of the SCD tracking dates.
  * **Effective-Date Policy (Non-Overlapping):** The initial load sets a default `StartDate` of `'1900-01-01'` to guarantee that historical orders resolve successfully. The current active version maintains an `EndDate` of `'9999-12-31 23:59:59.999'`. Upon an attribute change, the closing record's `EndDate` and the new record's `StartDate` are set to the exact same ETL execution timestamp (`SYSDATETIME()`) to prevent overlapping validity intervals. 

### The Unknown Member Policy (Orphaned Facts)
The provided source data contains an order line referencing an invalid catalog item (`OrderLineID 50470 / ProductID 9999`). 
* We will **not** modify the source files to fake a product.
* Instead, a default **`-1` (Unknown Product)** member will be explicitly inserted into `dim.DimProduct` before the fact load. The ETL pipeline will map any orphaned order lines to this `-1` key, preserving the revenue totals while maintaining the strict `NOT NULL` foreign key constraint on the fact table.

---

## 4. Evidence & Deliverables Checklist
*(To be populated by the developer prior to submission)*
* [x] DDL Scripts (`02` through `05`)
* [x] Validation Queries (`06`)
* [x] **Screenshot:** Source tables in SSMS Object Explorer (Step 01/02)
* [x] **Screenshot:** Final Star Schema Relationship Diagram (Step 05)
* [x] **Output Log:** Successful execution of a clean run
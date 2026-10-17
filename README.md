# Retail Sales Data Warehouse (RetailDWH)

## 📌 Project Overview
An analytical data warehouse built on SQL Server to analyze retail sales performance. This project transforms a transactional database (RetailOLTP) and external flat files (ProductCatalog) into a Kimball-style dimensional model (Star Schema) to support historical reporting and business intelligence.

## 📁 Repository Structure
* `/sql/01_Create_OLTP_Source.sql` - Source system creation
* `/sql/01b_Insert_OLTP_Sample_Data.sql` - Source system sample data
* `/sql/02_create_database_and_schemas.sql` - DWH schema architecture (stg, dim, fact, etl)
* `/sql/03_staging_ddl.sql` - Nuke-and-pave staging tables
* `/sql/04_dimensions_ddl.sql` - Dimensions (SCD Type 1 & Type 2)
* `/sql/05_fact_sales_ddl.sql` - Transactional fact table
* `/sql/06_validation_queries.sql` - Data quality and reporting queries
* `/docs/SSMS_Database_Diagram.png` - Physical star schema relationship diagram

---

## 🏗️ Architectural Design Decisions (Lab Explanations)

### 1. Staging Layer Strategy
Staging tables preserve original source columns, data types, and business IDs without modification. This provides a 1:1 trace back to the source system for auditing and ensures that data extraction is decoupled from heavy ETL transformations.

### 2. Surrogate Keys vs. Business Keys
Dimension keys (e.g., `ProductKey`) are database-generated surrogate keys (IDENTITY integers), which are completely separate from source business IDs (e.g., `ProductID`). This isolates the data warehouse from source system key reassignments and is strictly required to support multiple historical versions of the same business entity.

### 3. DimProduct & SCD Type 2 Effective-Date Policy
`DimProduct` implements Slowly Changing Dimension (SCD) Type 2 to preserve historical product pricing and status changes. 
* **Effective-Date Policy:** Initial loads are assigned a `StartDate` of `'1900-01-01'` to ensure historical orders resolve correctly. The active version maintains an `EndDate` of `'9999-12-31 23:59:59.999'`. When attributes change, the current row's `EndDate` is capped at `SYSDATETIME()`, and a new row is inserted with that exact timestamp as its `StartDate`.

### 4. Degenerate Dimension (OrderID)
`OrderID` is retained directly inside `FactSales` as a Degenerate Dimension. Because the order number itself contains no descriptive attributes (customer, date, and store are handled by other dimensions), creating a separate `DimOrder` table would cause unnecessary overhead and massive joins. It remains in the fact table to allow grouping of order lines for market basket analysis.

### 5. Fact Table Load Sequence
`FactSales` must be loaded *after* all dimension keys are generated and available. The fact load relies on looking up source business IDs against the populated dimensions to retrieve the correct surrogate keys before insertion.

---

## 📜 Business Rules & Handling Policies

* **Revenue Filtering:** Only source orders with `OrderStatus = 'Completed'` are loaded into `FactSales`. Pending and Cancelled orders are excluded from revenue counts.
* **Calculations:** 
  * `GrossSales` = `Quantity * UnitPrice`
  * `NetSales` = `GrossSales - DiscountAmount`
* **Unknown Member Policy:** Source order lines referencing products missing from the catalog (e.g., OrderLineID 50470 / ProductID 9999) are mapped to a dedicated Unknown member (`ProductKey = -1`). A default `-1` row is seeded into `DimProduct` prior to the fact load to preserve referential integrity without silently dropping revenue data.

---

## ⚙️ ETL / SSIS Control Flow Sketch
1. **Truncate Staging:** Clear all tables in the `stg` schema.
2. **Extract:** Load raw SQL OLTP tables and the Product CSV into staging.
3. **Data Quality Check:** Validate data types, handle NULLs, and log exact duplicates.
4. **Load Dimensions:**
   * Generate `DimDate` calendar rows.
   * Process SCD Type 1 updates for `DimCustomer` and `DimStore`.
   * Process SCD Type 2 historical inserts/closures for `DimProduct`.
5. **Load Fact Table:**
   * Join staging orders to dimensions to resolve surrogate keys.
   * Calculate `GrossSales` and `NetSales`.
   * Insert new records into `fact.FactSales`.

---

## 📊 Data Validation & Reporting Checks
*(See `06_validation_queries.sql` for execution code)*
1. Source orders with 'Completed' status count.
2. Valid order lines after product lookup.
3. Fact row count vs. SourceOrderLineID distinct count reconciliation.
4. Monthly revenue calculation by brand and store.
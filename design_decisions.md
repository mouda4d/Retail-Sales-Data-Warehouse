# RetailDWH: Grain, Keys, and SCD Architecture

## 1. Fact Table Grain & Degenerate Dimension
The grain of `fact.FactSales` is strictly defined as **one row per source order line**. 
The `SourceOrderLineID` column enforces this grain to prevent duplicate loads. We retain `OrderID` directly inside the fact table as a **Degenerate Dimension**. Because an order number contains no descriptive attributes of its own (the date, customer, and store are handled by other dimensions), creating a separate `DimOrder` table would cause unnecessary overhead and massive joins. `OrderID` remains in the fact table strictly to allow grouping of order lines for order-level metric rollups and market basket analysis.

## 2. Surrogate Keys vs. Source Business IDs
The data warehouse strictly separates operational identifiers from analytical keys.
* **Surrogate Keys:** Dimension primary keys (`CustomerKey`, `StoreKey`, `ProductKey`) are database-generated integer sequences (`IDENTITY(1,1)`). They have no inherent business meaning.
* **Business Keys:** The original IDs (`CustomerID`, `StoreID`, `ProductID`) are preserved in the dimensions. Surrogate keys are required to isolate the warehouse from upstream source changes and to allow multiple historical versions of the same `ProductID` to exist in `DimProduct`.
* **Fact Load Sequence:** `FactSales` must be loaded *after* all dimensions. The ETL pipeline must use the source business keys to look up and retrieve the correct surrogate keys before fact records can be inserted.

## 3. Slowly Changing Dimensions (SCD) & Data Handling
* **SCD Type 1 (Customer & Store):** Changes to customer or store attributes (e.g., email, region) overwrite the existing record. History is intentionally not retained.
* **SCD Type 2 (Product):** `DimProduct` utilizes Type 2 tracking to preserve the history of pricing and categorizations. 
  * **Effective-Date Policy:** To ensure historical orders resolve successfully, the initial load assigns a `StartDate` of `'1900-01-01'`. The active version maintains an `EndDate` of `'9999-12-31 23:59:59.999'`. Upon an attribute change, the closing record's `EndDate` and the new record's `StartDate` are set to the exact same ETL execution timestamp (`SYSDATETIME()`) to prevent overlaps. 
  * **Unknown Member Policy:** The provided sample data contains an orphaned order line (`OrderLineID 50470 / ProductID 9999`). We will not fake source data. Instead, a default `-1` (Unknown) member is explicitly seeded into `DimProduct`. The ETL pipeline will map missing products to `ProductKey = -1`, preserving revenue data while satisfying the strict `NOT NULL` foreign key constraints.
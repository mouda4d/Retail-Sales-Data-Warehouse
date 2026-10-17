/* ==============================================================================
   FILE: 06_validation_queries.sql
   PURPOSE: Source system performance baselines & DWH validation checks
============================================================================== */

-- ==============================================================================
-- PART 1: SOURCE SYSTEM OPTIMIZATION & BASELINE
-- ==============================================================================
USE RetailOLTP;
GO

-- 1A. Create non-clustered indexes safely (Idempotent) to optimize source lookups
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_OrderLines_OrderID_Includes' AND object_id = OBJECT_ID(N'dbo.OrderLines'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_OrderLines_OrderID_Includes 
    ON dbo.OrderLines (OrderID) INCLUDE (Quantity, UnitPrice);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Orders_StoreID' AND object_id = OBJECT_ID(N'dbo.ORDERS'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_Orders_StoreID 
    ON dbo.ORDERS (StoreID);
END;
GO

-- 1B. Source Baseline: Revenue by Store (Optimized INNER JOIN)
SELECT 
	s.StoreName, 
	SUM(ol.Quantity * ol.UnitPrice) AS SourceGrossSalesAmount
FROM
	dbo.OrderLines ol
INNER JOIN
	dbo.ORDERS o ON ol.OrderID = o.OrderID
INNER JOIN
	dbo.Stores s ON o.StoreID = s.StoreID
WHERE 
    o.OrderStatus = 'Completed' -- Aligning with DWH business rules
GROUP BY 
	s.StoreName
ORDER BY 
	SourceGrossSalesAmount DESC;
GO


-- ==============================================================================
-- PART 2: DATA WAREHOUSE VALIDATION & REPORTING (LAB REQUIREMENTS)
-- ==============================================================================
USE RetailDWH;
GO

-- Q1. How many source orders have status 'Completed'? (Check against staging)
SELECT 
    COUNT(OrderID) AS CompletedOrdersCount
FROM 
    stg.Orders
WHERE 
    OrderStatus = 'Completed';
GO

-- Q2. What is the number of valid order lines after product lookup?
SELECT 
    COUNT(ol.OrderLineID) AS ValidOrderLinesCount
FROM 
    stg.OrderLines ol
INNER JOIN 
    stg.Orders o ON ol.OrderID = o.OrderID
LEFT JOIN 
    stg.ProductCatalog p ON ol.ProductID = p.ProductID
WHERE 
    o.OrderStatus = 'Completed' 
    AND p.ProductID IS NOT NULL;
GO

-- Q3. Does COUNT(DISTINCT SourceOrderLineID) equal the fact row count? (Grain Validation)
SELECT 
    COUNT(*) AS FactRowCount,
    COUNT(DISTINCT SourceOrderLineID) AS DistinctSourceLines,
    CASE 
        WHEN COUNT(*) = COUNT(DISTINCT SourceOrderLineID) THEN 'PASS: Grain is 1 row per order line'
        ELSE 'FAIL: Duplicate lines detected in fact table' 
    END AS GrainValidationResult
FROM 
    fact.FactSales;
GO

-- Q4. Can you calculate monthly revenue by brand and store? (Star Schema Test)
SELECT 
    d.YearNumber,
    d.MonthName,
    p.Brand,
    s.StoreName,
    SUM(f.GrossSales) AS TotalGrossSales,
    SUM(f.NetSales) AS TotalNetSales
FROM 
    fact.FactSales f
INNER JOIN 
    dim.DimDate d ON f.DateKey = d.DateKey
INNER JOIN 
    dim.DimProduct p ON f.ProductKey = p.ProductKey
INNER JOIN 
    dim.DimStore s ON f.StoreKey = s.StoreKey
GROUP BY 
    d.YearNumber,
    d.MonthNumber, -- Included to ensure chronological sorting
    d.MonthName,
    p.Brand,
    s.StoreName
ORDER BY 
    d.YearNumber,
    d.MonthNumber,
    s.StoreName,
    p.Brand;
GO
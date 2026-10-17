-- Create four dimension tables: date, customer, store, product.
USE RetailDWH;
GO

IF OBJECT_ID(N'dim.DimDate', N'U') IS NULL
BEGIN
	CREATE TABLE dim.DimDate (
        DateKey INT NOT NULL PRIMARY KEY,
        FullDate DATE NOT NULL UNIQUE,
        DayNumber INT NOT NULL,
        MonthNumber INT NOT NULL,
        MonthName NVARCHAR(20) NOT NULL,
        QuarterNumber INT NOT NULL,
        YearNumber INT NOT NULL,
	);
END
GO

IF OBJECT_ID(N'dim.DimCustomer', N'U') IS NULL
BEGIN
	CREATE TABLE dim.DimCustomer (
        CustomerKey INT IDENTITY(1,1) PRIMARY KEY,
        CustomerID INT NOT NULL UNIQUE,
        CustomerName NVARCHAR(100),
        City NVARCHAR(50),
        Region NVARCHAR(50),
        Email NVARCHAR(120),
        LoadedAt DATETIME2(3) NOT NULL DEFAULT SYSDATETIME(),
        UpdatedAt DATETIME2(3) NOT NULL DEFAULT SYSDATETIME(),
        SourceFile NVARCHAR(255)
	);
END
GO

IF OBJECT_ID(N'dim.DimStore', N'U') IS NULL
BEGIN
	CREATE TABLE dim.DimStore (
        StoreKey INT IDENTITY(1,1) PRIMARY KEY,
        StoreID INT NOT NULL UNIQUE,
        StoreName NVARCHAR(100),
        City NVARCHAR(50),
        Region NVARCHAR(50),
        LoadedAt DATETIME2(3) NOT NULL DEFAULT SYSDATETIME(),
        UpdatedAt DATETIME2(3) NOT NULL DEFAULT SYSDATETIME(),
        SourceFile NVARCHAR(255)
	);
END
GO

IF OBJECT_ID(N'dim.DimProduct', N'U') IS NULL
BEGIN
	CREATE TABLE dim.DimProduct (
        ProductKey INT IDENTITY(1,1) PRIMARY KEY,
        ProductID INT NOT NULL,
        SKU NVARCHAR(30),
        ProductName NVARCHAR(100),
        Category NVARCHAR(60),
        Brand NVARCHAR(60),
        UnitCost DECIMAL(12,2),
        IsActive CHAR(1),
        StartDate DATETIME2(3) NOT NULL DEFAULT '1900-01-01 00:00:00.000',
        EndDate DATETIME2(3) NOT NULL DEFAULT '9999-12-31 23:59:59.999',
        IsCurrent BIT NOT NULL DEFAULT 1,
        LoadedAt DATETIME2(3) NOT NULL DEFAULT SYSDATETIME(),
        UpdatedAt DATETIME2(3) NOT NULL DEFAULT SYSDATETIME(),
        SourceFile NVARCHAR(255)
	);
END
GO
/*
drop table dim.dimproduct;
drop table dim.dimstore;
drop table dim.dimcustomer;
drop table dim.dimdate;
*/
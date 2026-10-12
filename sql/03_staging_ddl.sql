
DROP TABLE IF EXISTS stg.Customers;
GO
CREATE TABLE stg.Customers (
	StagingRowID BIGINT Identity(1,1),
	CustomerID INT,
	CustomerName NVARCHAR(100),
	City NVARCHAR(50),
	Region NVARCHAR(50),
	Email NVARCHAR(120),
	LastModifiedAt DATETIME2(3),
	SourceFile NVARCHAR(255),
	LoadDate DATETIME2(3) DEFAULT SYSDATETIME()
);
GO

DROP TABLE IF EXISTS stg.Stores;
GO
CREATE TABLE stg.Stores (
	StagingRowID BIGINT Identity(1,1),
	StoreID INT,
	StoreName NVARCHAR(100),
	City NVARCHAR(50),
	Region NVARCHAR(50),
	LastModifiedAt DATETIME2(3),
	SourceFile NVARCHAR(255),
	LoadDate DATETIME2(3) DEFAULT SYSDATETIME()
);
GO

DROP TABLE IF EXISTS stg.Orders;
GO
CREATE TABLE stg.Orders (
	StagingRowID BIGINT Identity(1,1),
	OrderID INT,
	CustomerID INT,
	StoreID INT,
	OrderDate DATETIME2(0),
	OrderStatus VARCHAR(20),
	LastModifiedAt DATETIME2(3),
	SourceFile NVARCHAR(255),
	LoadDate DATETIME2(3) DEFAULT SYSDATETIME()
);
GO

DROP TABLE IF EXISTS stg.OrderLines;
GO
CREATE TABLE stg.OrderLines (
	StagingRowID BIGINT Identity(1,1),
	OrderLineID INT, 
	OrderID INT, 
	ProductID INT, 
	Quantity INT, 
	UnitPrice DECIMAL(12,2),
	DiscountAmount DECIMAL(12,2), 
	LastModifiedAt DATETIME2(3),
	SourceFile NVARCHAR(255),
	LoadDate DATETIME2(3) DEFAULT SYSDATETIME()
);
GO

DROP TABLE IF EXISTS stg.ProductCatalog;
GO
CREATE TABLE stg.ProductCatalog (
	StagingRowID BIGINT Identity(1,1),
	ProductID INT, 
	SKU NVARCHAR(30), 
	ProductName NVARCHAR(100), 
	Category NVARCHAR(60),
	Brand NVARCHAR(60), 
	UnitCost DECIMAL(12,2), 
	IsActive CHAR(1), 
	LastModifiedAt DATETIME2(3),
	SourceFile NVARCHAR(255),
	LoadDate DATETIME2(3) DEFAULT SYSDATETIME()
);
GO

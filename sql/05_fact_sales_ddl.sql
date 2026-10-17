-- Create fact table: sales.
USE RetailDWH;
GO
IF OBJECT_ID(N'fact.FactSales', N'U') IS NULL
BEGIN
    CREATE TABLE fact.FactSales (
        SalesKey BIGINT IDENTITY(1,1) PRIMARY KEY,
        SourceOrderLineID INT NOT NULL UNIQUE,
        OrderID INT NOT NULL,
        DateKey INT NOT NULL,
        CustomerKey INT NOT NULL,
        StoreKey INT NOT NULL,
        ProductKey INT NOT NULL,
        Quantity INT,
        UnitPrice DECIMAL(12,2),
        GrossSales DECIMAL(18,2),
        DiscountAmount DECIMAL(18,2),
        NetSales DECIMAL(18,2),
        LoadedAt DATETIME2(3) NOT NULL DEFAULT SYSDATETIME(),
        UpdatedAt DATETIME2(3) NOT NULL DEFAULT SYSDATETIME(),
        CONSTRAINT FK_FactSales_DimDate FOREIGN KEY (DateKey) REFERENCES dim.DimDate(DateKey),
        CONSTRAINT FK_FactSales_DimCustomer FOREIGN KEY (CustomerKey) REFERENCES dim.DimCustomer(CustomerKey),
        CONSTRAINT FK_FactSales_DimStore FOREIGN KEY (StoreKey) REFERENCES dim.DimStore(StoreKey),
        CONSTRAINT FK_FactSales_DimProduct FOREIGN KEY (ProductKey) REFERENCES dim.DimProduct(ProductKey)
    );
END;
GO
/*
drop table fact.FactSales;
*/
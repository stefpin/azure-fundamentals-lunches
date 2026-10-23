-- =============================================================================
-- Lab 28 · Nusantara Retail sample data: customers (with contact details) and orders
-- setup.sh runs this against the main server. Safe to run more than once.
-- Manual run:   azsql "$MAIN_FQDN" "$DB" -i orders-dr.sql
-- =============================================================================
SET NOCOUNT ON;

IF OBJECT_ID(N'dbo.Customers', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Customers
    (
        CustomerId INT IDENTITY(1, 1) NOT NULL CONSTRAINT PK_Customers PRIMARY KEY,
        FullName   NVARCHAR(100)      NOT NULL,
        Email      NVARCHAR(254)      NOT NULL,
        Phone      VARCHAR(20)        NOT NULL,
        City       NVARCHAR(50)       NOT NULL
    );
    PRINT 'Table dbo.Customers created.';
END
GO

IF OBJECT_ID(N'dbo.Orders', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Orders
    (
        OrderId    INT IDENTITY(1, 1) NOT NULL CONSTRAINT PK_Orders PRIMARY KEY,
        CustomerId INT                NOT NULL CONSTRAINT FK_Orders_Customers REFERENCES dbo.Customers (CustomerId),
        OrderDate  DATETIME2(0)       NOT NULL CONSTRAINT DF_Orders_OrderDate DEFAULT (SYSUTCDATETIME()),
        StoreCode  VARCHAR(10)        NOT NULL,
        TotalIdr   DECIMAL(14, 0)     NOT NULL,
        Status     VARCHAR(20)        NOT NULL CONSTRAINT DF_Orders_Status DEFAULT ('NEW')
    );
    PRINT 'Table dbo.Orders created.';
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Customers)
BEGIN
    INSERT INTO dbo.Customers (FullName, Email, Phone, City)
    VALUES
        (N'Andi Pratama',   N'andi.pratama@example.com',   '0812-1111-2201', N'Jakarta'),
        (N'Siti Rahmawati', N'siti.rahmawati@example.com', '0813-2222-3302', N'Surabaya'),
        (N'Yusuf Hakim',    N'yusuf.hakim@example.com',    '0811-3333-4403', N'Medan'),
        (N'Putri Lestari',  N'putri.lestari@example.com',  '0815-4444-5504', N'Jakarta'),
        (N'Made Wirawan',   N'made.wirawan@example.com',   '0817-5555-6605', N'Denpasar'),
        (N'Rina Kusuma',    N'rina.kusuma@example.com',    '0819-6666-7706', N'Bandung');
    PRINT 'Six sample customers inserted.';
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Orders)
BEGIN
    INSERT INTO dbo.Orders (CustomerId, OrderDate, StoreCode, TotalIdr, Status)
    VALUES
        (1, '2026-10-01T09:12:00', 'JKT-01',  349000, 'DELIVERED'),
        (2, '2026-10-01T10:40:00', 'SBY-01', 1250000, 'DELIVERED'),
        (3, '2026-10-02T13:05:00', 'MDN-01',   89000, 'DELIVERED'),
        (4, '2026-10-03T19:22:00', 'JKT-02', 2150000, 'SHIPPED'),
        (5, '2026-10-04T08:47:00', 'DPS-01',  475000, 'SHIPPED'),
        (6, '2026-10-05T16:30:00', 'BDG-01',  129000, 'PAID'),
        (2, '2026-10-06T11:15:00', 'SBY-01',  780000, 'PAID'),
        (2, '2026-10-07T14:02:00', 'SBY-01',  215000, 'NEW'),
        (1, '2026-10-08T18:45:00', 'JKT-01',  560000, 'NEW');
    PRINT 'Nine sample orders inserted (three from the Surabaya store SBY-01).';
END
GO

SELECT (SELECT COUNT(*) FROM dbo.Customers) AS customers,
       (SELECT COUNT(*) FROM dbo.Orders)    AS orders;
GO

-- =============================================================================
-- Lab 11 · Nusantara Retail orders table
-- Creates dbo.Orders and adds seven sample orders. Safe to run more than once.
-- Run it from the lab folder with:   azsql "$SQL_FQDN" "$DB" -i orders.sql
-- =============================================================================
SET NOCOUNT ON;

IF OBJECT_ID(N'dbo.Orders', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Orders
    (
        OrderId      INT IDENTITY(1, 1) NOT NULL CONSTRAINT PK_Orders PRIMARY KEY,
        OrderDate    DATETIME2(0)       NOT NULL CONSTRAINT DF_Orders_OrderDate DEFAULT (SYSUTCDATETIME()),
        StoreCode    VARCHAR(10)        NOT NULL,
        CustomerName NVARCHAR(100)      NOT NULL,
        TotalIdr     DECIMAL(14, 0)     NOT NULL CONSTRAINT CK_Orders_TotalIdr CHECK (TotalIdr >= 0),
        Status       VARCHAR(20)        NOT NULL CONSTRAINT DF_Orders_Status DEFAULT ('NEW')
    );
    PRINT 'Table dbo.Orders created.';
END
ELSE
    PRINT 'Table dbo.Orders already exists.';
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Orders)
BEGIN
    INSERT INTO dbo.Orders (OrderDate, StoreCode, CustomerName, TotalIdr, Status)
    VALUES
        ('2026-10-01T09:12:00', 'JKT-01', N'Andi Pratama',     349000, 'DELIVERED'),
        ('2026-10-01T10:40:00', 'SBY-01', N'Siti Rahmawati',  1250000, 'DELIVERED'),
        ('2026-10-02T13:05:00', 'MDN-01', N'Yusuf Hakim',       89000, 'DELIVERED'),
        ('2026-10-03T19:22:00', 'JKT-02', N'Putri Lestari',   2150000, 'SHIPPED'),
        ('2026-10-04T08:47:00', 'DPS-01', N'Made Wirawan',     475000, 'SHIPPED'),
        ('2026-10-05T16:30:00', 'BDG-01', N'Rina Kusuma',      129000, 'PAID'),
        ('2026-10-06T11:15:00', 'MKS-01', N'Ahmad Fauzi',      780000, 'NEW');
    PRINT 'Seven sample orders inserted.';
END
ELSE
    PRINT 'Sample orders already present; nothing inserted.';
GO

SELECT COUNT(*) AS order_count FROM dbo.Orders;
GO

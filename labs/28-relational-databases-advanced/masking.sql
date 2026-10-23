-- =============================================================================
-- Lab 28 · Task 2 · Dynamic data masking on customer contact details
-- Run it against the primary:   azsql "$MAIN_FQDN" "$DB" -i masking.sql
-- Safe to run more than once (adding a mask to a masked column just replaces it).
-- =============================================================================
SET NOCOUNT ON;

-- 1. E-mail addresses: show the first letter and a fixed .com suffix, e.g. aXXX@XXXX.com
ALTER TABLE dbo.Customers ALTER COLUMN Email ADD MASKED WITH (FUNCTION = 'email()');

-- 2. Phone numbers: hide everything except the last two digits, e.g. XXXX-XXXX-XX01
ALTER TABLE dbo.Customers ALTER COLUMN Phone ADD MASKED WITH (FUNCTION = 'partial(0,"XXXX-XXXX-XX",2)');
GO

-- 3. A low-privilege test user for the customer service team.
--    WITHOUT LOGIN means nobody can sign in as this user; you can only impersonate it
--    with EXECUTE AS, which is perfect for testing permissions.
IF USER_ID(N'support_agent') IS NULL
    CREATE USER support_agent WITHOUT LOGIN;
GRANT SELECT ON dbo.Customers TO support_agent;
GRANT SELECT ON dbo.Orders TO support_agent;
GO

-- 4. Which columns are masked, and how?
SELECT OBJECT_NAME(object_id) AS table_name, name AS column_name, masking_function
FROM sys.masked_columns
ORDER BY table_name, column_name;
GO

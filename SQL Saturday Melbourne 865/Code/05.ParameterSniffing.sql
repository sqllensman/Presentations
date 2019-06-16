-- Query Store
Use AdventureWorks2014
GO

--------Create a Customer Table------
CREATE TABLE dbo.Customer( 
 Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
 FirstName NVARCHAR(50), LastName NVARCHAR(50))
GO
--Populate 100,000 customers with unique FirstName 
INSERT INTO dbo.Customer (FirstName, LastName)
SELECT TOP 100000 NEWID(), NEWID()
FROM SYS.all_columns SC1 
    CROSS JOIN SYS.all_columns SC2
GO 
--Populate 15000 customers with FirstName as Basavaraj
INSERT INTO dbo.Customer (FirstName, LastName)
SELECT TOP 15000 'RadCad', NEWID()
FROM SYS.all_columns SC1
        CROSS JOIN SYS.all_columns SC2


-- Create non-clustered index on the FirstName column
CREATE INDEX IX_Customer_FirstName on dbo.Customer (FirstName)
GO
-- Create stored procedure to get customer details by FirstName
CREATE PROCEDURE dbo.GetCustomersByFirstName
(@FirstName AS NVARCHAR(50))
AS
BEGIN
    SELECT * FROM dbo.Customer 
    WHERE FirstName = @FirstName
END

-- Procedure
SET STATISTICS IO, TIME ON
GO
EXEC dbo.GetCustomersByFirstName @FirstName = N'9E29F10F-F22C-4846-B946-897DAC76358E'

-- Procedure
EXEC dbo.GetCustomersByFirstName @FirstName = N'RadCad'
-- Query Store
Use TestRole
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
--Populate 15000 customers with FirstName as RadCad
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
EXEC dbo.GetCustomersByFirstName @FirstName = N'0855E48C-B249-475D-8C8B-71D6B643AE41'

-- Procedure
EXEC dbo.GetCustomersByFirstName @FirstName = N'RadCad'
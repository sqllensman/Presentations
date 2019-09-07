USE AdventureWorks2017;
GO

-- Reads all 31465 rows
SELECT  soh.SalesOrderID
FROM    Sales.SalesOrderHeader AS soh;

-- Reads only 5 rows
SELECT  TOP (5) soh.SalesOrderID
FROM    Sales.SalesOrderHeader AS soh;

-- Reads 1862 rows to returns 5 rows
SELECT  TOP (5) soh.SalesOrderID
FROM    Sales.SalesOrderHeader AS soh
WHERE   soh.DueDate = '20120210'
GO

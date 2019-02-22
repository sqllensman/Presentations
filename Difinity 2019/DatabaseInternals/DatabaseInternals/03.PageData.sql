-- Get Information about pages in Database

-- Basic Command
DBCC PAGE('Northwind', 1,123,2) WITH TABLERESULTS


-- Get Header Information for all Pages
USE [CheckDB]
GO

DECLARE @RC int
DECLARE @DatabaseName nvarchar(128) = N'Sandbox'

EXECUTE @RC = [dbo].[Get_DatabasePageData] 
   @DatabaseName
GO

-- View Data
Select * FROM dbo.PageData
ORDER BY PageId

-- Copy to PowerBIInternals
TRUNCATE TABLE [PowerBIInternals].[dbo].[PageData]

INSERT INTO [PowerBIInternals].[dbo].[PageData]
SELECT * FROM dbo.PageData


Select * from [PowerBIInternals].[dbo].[PageData]
WHERE object_name = 'Customers'
Order by PageId


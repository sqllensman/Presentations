USE master
GO

/*
View Physical Structure of Available Indexes from sys.system_internals_partition_columns (undocumented) 
Source 

http://improve.dk/exploring-the-sys-system_internals_partition_columns-ti-field/
http://rusanu.com/2011/10/20/sql-server-table-columns-under-the-hood/

Can use sp_BlitzIndex from BrentOzar.com (https://www.brentozar.com/first-aid/sql-server-downloads/)
or sp_helpindex from SQL Skills for similar info (http://www.sqlskills.com/blogs/kimberly/category/sp_helpindex-rewrites/)

Requires a Copy of the CheckDB database (In Download (SQL Server 2016 Version))
*/

USE CorruptionChallenge1
GO

Select * from sys.system_internals_partition_columns
WHERE partition_id = 72057594040614912


EXECUTE CheckDB.[dbo].[Get_IndexStructure] 'CorruptionChallenge1', '[dbo].[Revenue]'


-- Use this procedure to find which columns in Clustered Index are available in Non Clustered Indexes
EXECUTE CheckDB.[dbo].[Get_IndexStructure] 'CorruptionChallenge1', '[dbo].[Revenue]', 1

-- All Columns seem to be available in redundant non-clustered indexes

SELECT *
FROM dbo.Revenue 
WHERE id = 31


-- View corrupted Data
SELECT
 ix2.id
,ix2.DepartmentID
,ix2.Revenue
,ix3.Year
,ix3.Notes
FROM dbo.Revenue ix2 WITH(INDEX(2))
JOIN dbo.Revenue ix3 WITH(INDEX(3)) ON ix3.id = ix2.id
WHERE ix2.id = 31

-- Can Try Updating Notes directly
UPDATE dbo.Revenue
SET Notes = 'E5DCAE9B-D8F0-4BA2-B198-215A2D4671F5This is some varchar data just to fil out some pages... data pages are only 8k, therefore the more we fill up in each page, the more pages this table will flow into, thus simulating a larger table for the corruption example'
WHERE id = 31


-- Fails due to Page corruption

-- All data is availiable so save into temporary table and rebuild table
SELECT
 ix2.id
,ix2.DepartmentID
,ix2.Revenue
,ix3.Year
,ix3.Notes
INTO Revenue_Copy
FROM dbo.Revenue ix2 WITH(INDEX(2))
JOIN dbo.Revenue ix3 WITH(INDEX(3)) ON ix3.id = ix2.id

-- Remove corrupt data after saving data from NC indexes
TRUNCATE TABLE dbo.Revenue

SET IDENTITY_INSERT dbo.Revenue ON;
go


INSERT INTO dbo.Revenue(id, DepartmentID, Revenue, Year, Notes )
SELECT id, DepartmentID, Revenue, Year, Notes
FROM Revenue_Copy

-- Done, switch the identity insert off again
SET IDENTITY_INSERT dbo.Revenue OFF;
GO

Select * from dbo.Revenue

-- Cleanup
DROP TABLE dbo.Revenue_Copy

-- Check Status
EXECUTE CheckDB.[dbo].[CheckDB_Extended] 
   @DatabaseName = 'CorruptionChallenge1'

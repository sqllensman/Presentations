-- 01.Setup
-- Restore NorthWind
-- Restore PowerBIInternals
-- Restore CheckDB
-- Requires SQL Server 2017

Use master
GO

Alter Database NorthWind SET SINGLE_USER WITH ROLLBACK IMMEDIATE 

Restore Database NorthWind
FROM Disk = 'C:\Lensman\Presentations\Difinity2019\Demo\Northwind.bak'
WITH STATS, CHECKSUM, REPLACE

-- Run Disk Usage Report

--Backup Database NorthWind
--TO Disk = 'C:\Lensman\Presentations\Difinity2019\Demo\Northwind_Diffinty.bak'
--WITH STATS, CHECKSUM, FORMAT




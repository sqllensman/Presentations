-- Read Data
SELECT *
  FROM AdventureWorksDW2014.[dbo].[FactInternetSales]
GO

SELECT TOP 10 *
  FROM AdventureWorksDW2014.[dbo].[FactResellerSales]
ORDER BY OrderDateKey
GO

EXECUTE CheckDB.[dbo].[CheckDB_Extended] 
   @DatabaseName = 'AdventureWorksDW2014'


-- View Page With Corruption
DBCC TRACEON(3604,-1)
DBCC PAGE(AdventureWorksDW2014, 1, 18460, 2)

EXECUTE CheckDB.[dbo].[prc_ReadPageData]
	   @DatabaseName = 'AdventureWorksDW2014'
	  ,@FileId = 1
	  ,@PageId = 18460




Use master
go

-- Online Page Restore

RESTORE DATABASE [AdventureWorksDW2014] 
PAGE='1:429, 1:18453, 1:18460, 1:18459'
FROM DISK = 'C:\SQLSaturday\DBFiles\Backup\AdventureWorksDW2014_Full.bak'
WITH NORECOVERY

RESTORE LOG [AdventureWorksDW2014] 
FROM DISK = 'C:\SQLSaturday\DBFiles\Backup\AdventureWorksDW2014_Log_1.trn'
WITH NORECOVERY

-- 
-- Take Additional Log Backup (Require Tail-of Log Backup to bring page to Transactionally Consistent state)
BACKUP LOG [AdventureWorksDW2014]
TO DISK = 'C:\SQLSaturday\DBFiles\Backup\AdventureWorksDW2014_Log_OL.bak'
WITH FORMAT, NO_TRUNCATE

RESTORE LOG [AdventureWorksDW2014] 
FROM DISK = 'C:\SQLSaturday\DBFiles\Backup\AdventureWorksDW2014_Log_OL.bak'
WITH RECOVERY

EXECUTE CheckDB.[dbo].[CheckDB_Extended] 
   @DatabaseName = 'AdventureWorksDW2014'




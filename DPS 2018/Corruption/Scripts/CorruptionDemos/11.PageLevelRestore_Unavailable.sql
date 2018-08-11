/*
Can all Pages be Page Repaired
The answer is no. 
The following page types cannot be restored using single-page restore: 
•File header pages  
http://www.sqlskills.com/blogs/paul/search-engine-qa-21-file-header-pages-and-file-header-corruption/
•Boot page  
http://www.sqlskills.com/blogs/paul/search-engine-qa-20-boot-pages-and-boot-page-corruption/
•GAM, SGAM, DIFF map, ML map pages
http://www.sqlskills.com/blogs/paul/inside-the-storage-engine-gam-sgam-pfs-and-other-allocation-maps/

What about other pages
*/

USE master
GO

SELECT DATABASEPROPERTYEX (N'AdventureWorksDW2014', N'STATUS');

EXECUTE CheckDB.[dbo].[CheckDB_Extended] 
   @DatabaseName = 'AdventureWorksDW2014'



-- Page 0 File Header Type 15
RESTORE DATABASE AdventureWorksDW2014 
PAGE = '1:0' FROM DISK = 'C:\DPS2018\DBFiles\Backup\AdventureWorksDW2014_Full.bak';
GO  

-- Page 1 PFS Type 15
RESTORE DATABASE AdventureWorksDW2014 
PAGE = '1:1' FROM DISK = 'C:\DPS2018\DBFiles\Backup\AdventureWorksDW2014_Full.bak';
GO  

-- Page 2 GAM Type 8
RESTORE DATABASE AdventureWorksDW2014 
PAGE = '1:2' FROM DISK = 'C:\DPS2018\DBFiles\Backup\AdventureWorksDW2014_Full.bak';
GO  

-- Page 3 SGAM Type 9
RESTORE DATABASE AdventureWorksDW2014 
PAGE = '1:3' FROM DISK = 'C:\DPS2018\DBFiles\Backup\AdventureWorksDW2014_Full.bak';
GO 

-- Page 4 Unknown
RESTORE DATABASE AdventureWorksDW2014 
PAGE = '1:4' FROM DISK = 'C:\DPS2018\DBFiles\Backup\AdventureWorksDW2014_Full.bak';
GO  

-- Page 5 Unknown
RESTORE DATABASE AdventureWorksDW2014 
PAGE = '1:5' FROM DISK = 'C:\DPS2018\DBFiles\Backup\AdventureWorksDW2014_Full.bak';
GO   

-- Page 6 Diff Map Type 16
RESTORE DATABASE AdventureWorksDW2014 
PAGE = '1:6' FROM DISK = 'C:\DPS2018\DBFiles\Backup\AdventureWorksDW2014_Full.bak';
GO 

-- Page 7 ML Map Type 17	
RESTORE DATABASE AdventureWorksDW2014 
PAGE = '1:7' FROM DISK = 'C:\DPS2018\DBFiles\Backup\AdventureWorksDW2014_Full.bak';
GO 
 
-- Page 9 Boot Type 13	
RESTORE DATABASE AdventureWorksDW2014 
PAGE = '1:9' FROM DISK = 'C:\DPS2018\DBFiles\Backup\AdventureWorksDW2014_Full.bak';
GO 

RESTORE DATABASE AdventureWorksDW2014 
PAGE = '1:8,1:10,1:11' FROM DISK = 'C:\DPS2018\DBFiles\Backup\AdventureWorksDW2014_Full.bak';
GO 

--sys.sysfiles1
RESTORE DATABASE AdventureWorksDW2014 
PAGE = '1:12' FROM DISK = 'C:\DPS2018\DBFiles\Backup\AdventureWorksDW2014_Full.bak' 
GO 

EXECUTE CheckDB.[dbo].[CheckDB_Extended] 
   @DatabaseName = 'AdventureWorksDW2014'


-- Run REPAIR_ALLOW_DATA_LOSS (must be in Single_USER state 
ALTER DATABASE [AdventureWorksDW2014] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO
DBCC CHECKDB (N'AdventureWorksDW2014', REPAIR_ALLOW_DATA_LOSS) WITH ALL_ERRORMSGS, NO_INFOMSGS;
GO
ALTER DATABASE [AdventureWorksDW2014] SET MULTI_USER;
GO

-- sys.sysrowsets
RESTORE DATABASE AdventureWorksDW2014 
PAGE = '1:17' FROM DISK = 'C:\DPS2018\DBFiles\Backup\AdventureWorksDW2014_Full.bak';
GO

-- sys.sysrscols
RESTORE DATABASE AdventureWorksDW2014 
PAGE = '1:19' FROM DISK = 'C:\DPS2018\DBFiles\Backup\AdventureWorksDW2014_Full.bak';
GO

-- sys.sysallocunits
RESTORE DATABASE AdventureWorksDW2014 
PAGE = '1:20' FROM DISK = 'C:\DPS2018\DBFiles\Backup\AdventureWorksDW2014_Full.bak';
GO




-- Offline Page Restore
-- Take Additional Log Backup (
BACKUP LOG [AdventureWorksDW2014]
TO DISK = 'C:\DPS2018\DBFiles\Backup\AdventureWorksDW2014_Log_OFFLine.bak'
WITH FORMAT, NORECOVERY

RESTORE LOG [AdventureWorksDW2014] 
FROM DISK = 'C:\DPS2018\DBFiles\Backup\AdventureWorksDW2014_Log_1.trn'
WITH NORECOVERY

RESTORE LOG [AdventureWorksDW2014] 
FROM DISK = 'C:\DPS2018\DBFiles\Backup\AdventureWorksDW2014_Log_OFFLine.bak'
WITH RECOVERY
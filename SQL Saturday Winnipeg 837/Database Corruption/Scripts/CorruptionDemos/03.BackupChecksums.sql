/*  
Setup Instructions
Requires a Copy of AdventureWorks2014

Requires a copy of broken database (availble for download)




*/
USE master

DBCC CHECKDB('AdventureWorks2014') WITH ALL_ERRORMSGS, NO_INFOMSGS

DBCC CHECKDB('broken') WITH ALL_ERRORMSGS, NO_INFOMSGS

BACKUP DATABASE [AdventureWorks2014]
TO DISK = 'C:\SQL_Data\Backup\AdventureWorks2014_Original.bak'
WITH FORMAT, STATS
GO


BACKUP DATABASE broken
TO DISK = 'C:\SQL_Data\Backup\broken.bak'
WITH FORMAT, STATS
GO


RESTORE VERIFYONLY
FROM DISK = N'C:\SQL_Data\Backup\AdventureWorks2014.bak' 

RESTORE VERIFYONLY
FROM DISK = N'C:\SQL_Data\Backup\broken.bak' 
 
/*
Use Hex Editor to adjust Backup File
Start at 6AD1250

*/
-- RESTORE VERIFYONLY
RESTORE VERIFYONLY
FROM DISK = N'C:\SQL_Data\Backup\AdventureWorks2014.bak' 

-- Test Restore
RESTORE DATABASE [AdventureWorks2014_SQLSaturday] 
FROM  DISK = N'C:\SQL_Data\Backup\AdventureWorks2014.bak' 
WITH  FILE = 1,  
	MOVE N'AdventureWorks2014_Data' TO N'C:\SQL_Data\Data\AdventureWorks2014_SQLSaturday614_Data.mdf',  
	MOVE N'AdventureWorks2014_Log' TO N'C:\SQL_Data\Log\AdventureWorks2014_SQLSaturday614_Log.ldf',  
	NOUNLOAD,  STATS = 5, REPLACE
GO

-- Test with CheckDB
DBCC CHECKDB('AdventureWorks2014_SQLSaturday') WITH ALL_ERRORMSGS, NO_INFOMSGS

/*
DBCC TRACEON(3604)
DBCC PAGE(AdventureWorks2014_SQLSaturday, 1, 13670, 2)
-- Search for SQLSaturday
DBCC TRACEOFF(3604)

*/
-- Use of Checksum
BACKUP DATABASE broken
TO DISK = 'C:\SQL_Data\Backup\broken.bak'
WITH STATS, CHECKSUM,CONTINUE_AFTER_ERROR										
GO

RESTORE VERIFYONLY
FROM DISK = N'C:\SQL_Data\Backup\broken.bak'
WITH FILE=2

-- Can't change the backups
DBCC TRACEON(3023)
GO

DBCC TRACESTATUS

USE master

BACKUP DATABASE broken
TO DISK = 'C:\SQL_Data\Backup\broken.bak'
WITH STATS, CONTINUE_AFTER_ERROR
GO


RESTORE HEADERONLY
FROM DISK = N'C:\SQL_Data\Backup\broken.bak' 
GO 


RESTORE VERIFYONLY
FROM DISK = N'C:\SQL_Data\Backup\broken.bak' 
WITH FILE = 3


DBCC TRACEOFF(3023)
GO
DBCC TRACESTATUS

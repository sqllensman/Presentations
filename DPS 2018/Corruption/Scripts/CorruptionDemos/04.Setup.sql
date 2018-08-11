-- Example 1 - Database Corruption
-- Created by Steve Stedman  http://SteveStedman.com
-- Twitter @sqlEmt
-- LinkedIn http://linkedin.com/in/stevestedman
-- Direct Link http://stevestedman.com/category/corruption/

/*

Download CorruptionChallenge1.bak from 
http://stevestedman.com/2015/04/sql-server-2008-downloads-for-the-database-corruption-challenge-dbcc-week-1/

*/

------------------------------------------------------------

USE [master]
GO

-- under SQLCMD Mode
:SETVAR BackupPath  "C:\DPS2018\DBFiles\SampleDB\CorruptionChallenge1"
:SETVAR RestorePath "C:\DPS2018\DBFiles"

RESTORE HEADERONLY FROM DISK = '$(BackupPath)\CorruptionChallenge1.bak'
RESTORE FILELISTONLY FROM DISK = '$(BackupPath)\CorruptionChallenge1.bak'

IF EXISTS(SELECT name
            FROM sys.databases
       WHERE name = 'CorruptionChallenge1')
BEGIN
    ALTER DATABASE [CorruptionChallenge1] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [CorruptionChallenge1];
END

-- start with a full restore of backup
RESTORE DATABASE [CorruptionChallenge1]
  FROM DISK = N'$(BackupPath)\CorruptionChallenge1.bak'
  WITH FILE = 1,
       MOVE N'CorruptionChallenge1' TO N'$(RestorePath)\Data\CorruptionChallenge1.mdf',
       MOVE N'CorruptionChallenge1_log' TO N'$(RestorePath)\Log\CorruptionChallenge1_log.ldf',
       REPLACE,
	   RECOVERY;

-- Switch to Database and Select from Revenue Table	  
USE [CorruptionChallenge1]
GO

SELECT id, DepartmentID, Revenue, [Year], Notes
FROM dbo.Revenue
-- Record 31 appears damaged

-- View the Actual Page and Record Location using undocumented sys.fn_PhysLocFormatter(%%physloc%%) function
SELECT 
%%physloc%%, sys.fn_PhysLocFormatter(%%physloc%%) AS 'File:Page:Slot', *
FROM dbo.Revenue

-- Check Status of Database 
DBCC CHECKDB('CorruptionChallenge1')

/*
Displays lots of unneeded info 
*/
-- Exclude Info Msgs
DBCC CHECKDB('CorruptionChallenge1') WITH NO_INFOMSGS, ALL_ERRORMSGS

-- Exclude Info Msgs but output results in TableResults
DBCC CHECKDB('CorruptionChallenge1') WITH NO_INFOMSGS, TABLERESULTS

-- Evalute Corruption using CheckDB_Extended procedure
-- Requires creation of the CheckDb Utility Data Base
EXECUTE CheckDB.[dbo].[CheckDB_Extended] 
   @DatabaseName = 'CorruptionChallenge1'

-- View Page With Corruption
DBCC TRACEON(3604,-1)
-- Try with Option 3 
DBCC PAGE(CorruptionChallenge1, 1, 280, 3)

-- Try with Option 1
DBCC PAGE(CorruptionChallenge1, 1, 280, 1)

-- Try with Option 2 (displays Hex only)
DBCC PAGE(CorruptionChallenge1, 1, 280, 2)

-- Try with Option 2 and TableResults
DBCC PAGE(CorruptionChallenge1, 1, 280, 2) WITH TABLERESULTS


USE [CorruptionChallenge1]
GO

-- Use Utility Function to analyse better
EXECUTE CheckDB.[dbo].[prc_ReadPageData]
	   @DatabaseName = 'CorruptionChallenge1'
	  ,@FileId = 1
	  ,@PageId = 280

-- Issues with NCol and VarLength data are obvious


-- Try Repair Options
ALTER DATABASE  CorruptionChallenge1 SET SINGLE_USER WITH ROLLBACK IMMEDIATE  

Use master

DBCC CHECKDB('CorruptionChallenge1', REPAIR_REBUILD) WITH ALL_ERRORMSGS, NO_INFOMSGS

DBCC CHECKDB('CorruptionChallenge1', REPAIR_ALLOW_DATA_LOSS) WITH ALL_ERRORMSGS, NO_INFOMSGS

ALTER DATABASE  CorruptionChallenge1 SET MULTI_USER WITH ROLLBACK IMMEDIATE  

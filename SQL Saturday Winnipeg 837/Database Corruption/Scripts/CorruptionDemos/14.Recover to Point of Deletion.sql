/*
During the following steps work was being performed on the database.
5:50PM a full backup was performed.
5:51PM transaction log backup.
5:52PM transaction log backup.
5:53PM transaction log backup.
5:54PM transaction log backup.
5:55PM transaction log backup.
5:56PM transaction log backup.
Around 5:57PM to 5:58pm data from the [OPEN_NFIRS].[Record1000]  users reported the table was no longer able to be queried, red error messages when selecting from [OPEN_NFIRS].[Record1000]. Soon thereafter that the data in the table was missing. Someone noticed that the table was empty, then turned off transaction log backups, and put the database in single user mode to prevent any more changes.
Around 5:59PM the database was detached, and the MDF, LDF, and NDF files were copied off.
Your goal if you choose to accept it is to get restore all the data in the [OPEN_NFIRS].[Record1000] table prior to its disappearance. 
Note: there may have been multiple DBA’s working on this system in several different time zones across the world.

*/

USE master;
GO
IF DB_ID ('CorruptionChallenge7') IS NOT NULL
BEGIN 
     ALTER DATABASE CorruptionChallenge7 SET SINGLE_USER WITH ROLLBACK IMMEDIATE
	 DROP DATABASE CorruptionChallenge7
END

---- Attached Supplied Files (Will upgrade database to current version)
---- May need run as Administrator to ensure no file permission errors
---- Original files in CorruptionChallenge7.zip
CREATE DATABASE [CorruptionChallenge7] ON 
( FILENAME = N'C:\SQLSaturday\DBFiles\SampleDB\CorruptionChallenge7\CorruptionChallenge7.mdf' ),
( FILENAME = N'C:\SQLSaturday\DBFiles\SampleDB\CorruptionChallenge7\CorruptionChallenge7_log.ldf' ),
( FILENAME = N'C:\SQLSaturday\DBFiles\SampleDB\CorruptionChallenge7\UserObjects.ndf' )
 FOR ATTACH
GO

Use CorruptionChallenge7
GO

-- Check Table
SELECT * FROM [OPEN_NFIRS].[Record1000]

/*
fn_dblog

https://www.sqlskills.com/blogs/paul/using-fn_dblog-fn_dump_dblog-and-restoring-with-stopbeforemark-to-an-lsn/

http://rusanu.com/2014/03/10/how-to-read-and-interpret-the-sql-server-log/

*/
-- Find Delete Operation
SELECT  
	[TRANSACTION ID] as TransactionID,
	[Begin Time] as BeginTime,
	[Current LSN] as LSN, *
FROM sys.fn_dblog(NULL, NULL) 
WHERE Context IN ('LCX_NULL') 
AND Operation in ('LOP_BEGIN_XACT')  
And [Transaction Name] In ('DELETE')
ORDER BY [Begin Time] Desc

/*
BeginTime	LSN
2015/05/31 17:57:56:287	00000025:00000270:0001
*/

-- Backup tail of the log
BACKUP LOG [CorruptionChallenge7] TO DISK = 'C:\SQLSaturday\DBFiles\SampleDB\CorruptionChallenge7\CorruptionChallenge7_tail_log.trn'
WITH NO_TRUNCATE, FORMAT

-- Restore Log to Point of Deletion
-- Restore the database and STOPAT the time of the last
USE master
  
IF EXISTS(SELECT name
            FROM sys.databases
       WHERE name = 'CorruptionChallenge7')
BEGIN
    ALTER DATABASE [CorruptionChallenge7] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [CorruptionChallenge7];
END
  
RESTORE DATABASE [CorruptionChallenge7]
FROM DISK='C:\SQLSaturday\DBFiles\SampleDB\CorruptionChallenge7\CorruptionChallenge7_1.bak'
WITH NORECOVERY, REPLACE, STATS=10
, MOVE 'CorruptionChallenge7' TO 'C:\SQLSaturday\DBFiles\Data\CorruptionChallenge7.mdf'
, MOVE 'UserObjects' TO 'C:\SQLSaturday\DBFiles\Data\UserObjects.ndf'
, MOVE 'CorruptionChallenge7_log' TO 'C:\SQLSaturday\DBFiles\Log\CorruptionChallenge7_log.ldf'
  
RESTORE LOG [CorruptionChallenge7]
FROM DISK='C:\SQLSaturday\DBFiles\SampleDB\CorruptionChallenge7\TransLog_CorruptionChallenge7_0.trn'
WITH NORECOVERY, REPLACE, STATS=10
  
RESTORE LOG [CorruptionChallenge7]
FROM DISK='C:\SQLSaturday\DBFiles\SampleDB\CorruptionChallenge7\TransLog_CorruptionChallenge7_1.trn'
WITH NORECOVERY, REPLACE, STATS=10
  
RESTORE LOG [CorruptionChallenge7]
FROM DISK='C:\SQLSaturday\DBFiles\SampleDB\CorruptionChallenge7\TransLog_CorruptionChallenge7_2.trn'
WITH NORECOVERY, REPLACE, STATS=10
  
RESTORE LOG [CorruptionChallenge7]
FROM DISK='C:\SQLSaturday\DBFiles\SampleDB\CorruptionChallenge7\TransLog_CorruptionChallenge7_3.trn'
WITH NORECOVERY, REPLACE, STATS=10
  
RESTORE LOG [CorruptionChallenge7]
FROM DISK='C:\SQLSaturday\DBFiles\SampleDB\CorruptionChallenge7\TransLog_CorruptionChallenge7_4.trn'
WITH NORECOVERY, REPLACE, STATS=10
  
RESTORE LOG [CorruptionChallenge7]
FROM DISK='C:\SQLSaturday\DBFiles\SampleDB\CorruptionChallenge7\TransLog_CorruptionChallenge7_5.trn'
WITH NORECOVERY, REPLACE, STATS=10
  
--==================================== IMPORTANT BIT ==================================
RESTORE LOG [CorruptionChallenge7]
FROM DISK='C:\SQLSaturday\DBFiles\SampleDB\CorruptionChallenge7\CorruptionChallenge7_tail_log.trn'
WITH NORECOVERY, REPLACE, STATS=10
, STOPATMARK = 'lsn:0x00000025:00000270:0001';

RESTORE DATABASE [CorruptionChallenge7] WITH RECOVERY

-- Check Table
Use CorruptionChallenge7
GO

SELECT Count(*) FROM [OPEN_NFIRS].[Record1000]

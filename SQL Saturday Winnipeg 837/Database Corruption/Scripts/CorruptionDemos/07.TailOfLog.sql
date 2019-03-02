/*

Download CorruptionChallenge3.files from  
http://stevestedman.com/2015/04/week-3-of-the-database-corruption-challenge/

Scenario:

Disk Failure
	Data Drive is lost

	Log file recovered

	Full Backup and 3 Log Backups are available



*/

Use master
GO

IF EXISTS(SELECT name
            FROM sys.databases
       WHERE name = 'CorruptionChallenge3')
BEGIN
    ALTER DATABASE [CorruptionChallenge3] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [CorruptionChallenge3];
END

-- start with a full restore of backup
RESTORE DATABASE [CorruptionChallenge3]
  FROM DISK = N'C:\SQLSaturday\DBFiles\Backup\CorruptionChallenge3_Full.bak'
  WITH FILE = 1,
       MOVE N'CorruptionChallenge3' TO N'C:\SQLSaturday\DBFiles\Data\CorruptionChallenge3.mdf',
       MOVE N'CorruptionChallenge3_log' TO N'C:\SQLSaturday\DBFiles\Log\CorruptionChallenge3_log.ldf',
       REPLACE,
	   RECOVERY;


SELECT [id]
      ,[event]
      ,[when]
FROM [CorruptionChallenge3].[dbo].[History]


-- Take Datbase Offline
USE master


ALTER DATABASE CorruptionChallenge3 SET OFFLINE

/* 
Replace logfile
Delete Datafile 
Use Powershell Script: Copy-Files.ps1
	Needs to be run as Administrator



*/
-- Try to Bring Online
ALTER DATABASE CorruptionChallenge3 SET ONLINE

-- Has Errors left in Recovery Pending State
Select name, state_desc
from sys.databases WHERE name = 'CorruptionChallenge3'

-- Take a Tail-of-Log Backup
BACKUP LOG CorruptionChallenge3 
TO Disk = 'C:\SQLSaturday\DBFiles\Backup\TransLog_CorruptionChallenge_Tail.trn'
WITH FORMAT , NO_TRUNCATE




-- start with a full restore of backup
RESTORE DATABASE [CorruptionChallenge3]
  FROM DISK = N'C:\SQLSaturday\DBFiles\Backup\CorruptionChallenge3_Full.bak'
  WITH FILE = 1,
       MOVE N'CorruptionChallenge3' TO N'C:\SQLSaturday\DBFiles\Data\CorruptionChallenge3.mdf',
       MOVE N'CorruptionChallenge3_log' TO N'C:\SQLSaturday\DBFiles\Log\CorruptionChallenge3_log.ldf',
       REPLACE,
	   NORECOVERY;

RESTORE LOG [CorruptionChallenge3]
	FROM DISK = N'C:\SQLSaturday\DBFiles\Backup\TransLog_CorruptionChallenge30.TRN'
	WITH NORECOVERY;

RESTORE LOG [CorruptionChallenge3]
	FROM DISK = N'C:\SQLSaturday\DBFiles\Backup\TransLog_CorruptionChallenge31.TRN'
	WITH NORECOVERY;

RESTORE LOG [CorruptionChallenge3]
	FROM DISK = N'C:\SQLSaturday\DBFiles\Backup\TransLog_CorruptionChallenge32.TRN'
	WITH NORECOVERY;

RESTORE LOG [CorruptionChallenge3]
	FROM DISK = N'C:\SQLSaturday\DBFiles\Backup\TransLog_CorruptionChallenge32.TRN'
	WITH NORECOVERY;

RESTORE LOG [CorruptionChallenge3]
	FROM DISK = N'C:\SQLSaturday\DBFiles\Backup\TransLog_CorruptionChallenge_Tail.trn'
	WITH NORECOVERY;

RESTORE DATABASE [CorruptionChallenge3]
	WITH RECOVERY

SELECT * FROM CorruptionChallenge3.[dbo].[History]

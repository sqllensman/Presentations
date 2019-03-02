USE [master]
GO

-- under SQLCMD Mode
:SETVAR BackupPath  "C:\SQLSaturday\DBFiles\Backup"
:SETVAR RestorePath "C:\SQLSaturday\DBFiles"

RESTORE HEADERONLY FROM DISK = '$(BackupPath)\broken.bak'
RESTORE FILELISTONLY FROM DISK = '$(BackupPath)\broken.bak'

IF EXISTS(SELECT name
            FROM sys.databases
       WHERE name = 'broken')
BEGIN
    ALTER DATABASE [broken] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [broken];
END

-- start with a full restore of backup
RESTORE DATABASE [broken]
  FROM DISK = N'$(BackupPath)\broken.bak'
  WITH FILE = 1,
       MOVE N'broken' TO N'$(RestorePath)\Data\broken.mdf',
       MOVE N'broken_log' TO N'$(RestorePath)\Log\broken_log',
       REPLACE,
	   RECOVERY;


BACKUP DATABASE [AdventureWorks2016]
TO DISK = 'C:\SQLSaturday\DBFiles\Backup\AdventureWorks2016.bak'
WITH FORMAT, STATS, CHECKSUM
GO
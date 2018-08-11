USE master
GO

:SETVAR BackupPath  "C:\DPS2018\DBFiles\SampleDB"
:SETVAR RestorePath "C:\DPS2018\DBFiles"
:SETVAR BackupFile  "AdventureWorksDW2014.bak"

IF EXISTS(SELECT name
            FROM sys.databases
       WHERE name = 'AdventureWorksDW2014')
BEGIN
    ALTER DATABASE [AdventureWorksDW2014] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [AdventureWorksDW2014];
END

RESTORE HEADERONLY FROM DISK = '$(BackupPath)\$(BackupFile)'
RESTORE FILELISTONLY FROM DISK = '$(BackupPath)\$(BackupFile)'

RESTORE DATABASE AdventureWorksDW2014
FROM DISK = '$(BackupPath)\$(BackupFile)'
WITH MOVE 'AdventureWorksDW2014_Data' TO '$(RestorePath)\Data\AdventureWorksDW2014_Data.mdf',
	MOVE 'AdventureWorksDW2014_Log' TO '$(RestorePath)\Log\AdventureWorksDW2014_Log.ldf',
	STATS, REPLACE;
	GO

-- Set to Full
ALTER DATABASE [AdventureWorksDW2014] SET RECOVERY FULL WITH NO_WAIT
GO
	


-- Take initial backup
BACKUP DATABASE [AdventureWorksDW2014]
TO DISK = 'C:\DPS2018\DBFiles\Backup\AdventureWorksDW2014_Full.bak'
WITH FORMAT, CHECKSUM, STATS=5

-- Take initial Log
BACKUP LOG [AdventureWorksDW2014]
TO DISK = 'C:\DPS2018\DBFiles\Backup\AdventureWorksDW2014_Log_1.trn'
WITH FORMAT, CHECKSUM, STATS=5

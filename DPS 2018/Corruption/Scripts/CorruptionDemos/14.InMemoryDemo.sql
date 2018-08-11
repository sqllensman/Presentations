USE [NoLock]
GO

-- set the database to full recovery.  
ALTER DATABASE [NoLock] SET RECOVERY FULL;
GO

Backup Database [NoLock] 
TO Disk = 'C:\SQL_Data\Backup\NoLock_Full_Init.bak' 
WITH CHECKSUM, FORMAT, INIT, STATS=5


Use [NoLock]
GO


--Add Data
SET NOCOUNT ON;
DECLARE @i INT = 1
WHILE ( @i < 50 )
    BEGIN
        INSERT  dbo.t_memopt
        VALUES  ( @i, 'a', REPLICATE('b', 8000) )

		INSERT NoLock.NoLock(NoLock, Data)
		VALUES  ( @i, REPLICATE('c', 1000) )
        SET @i += 1;
    END;
GO

Select * from dbo.t_memopt

Select NoLock From NoLock.NoLock WITH (NOLOCK)

DBCC CHECKDB([NOLOCK]) WITH ALL_ERRORMSGS

SELECT page_verify_option_desc FROM sys.databases WHERE Name = 'NOLOCK'

Backup Database [NoLock]
FILEGROUP = 'PRIMARY', FILEGROUP = 'NoLock_IM'
TO Disk = 'NUL'
WITH COPY_ONLY, NOFORMAT, NOINIT, CHECKSUM, STATS= 5

Select * from dbo.t_memopt
Select NoLock From NoLock.NoLock.NoLock WITH (NOLOCK)


/*Listing 6-13: Delete half the rows in the memory-optimized table.*/
SET NOCOUNT ON;
DECLARE @i INT = 0;
WHILE ( @i <= 50 )
    BEGIN
        DELETE  t_memopt
        WHERE   c1 = @i;
        SET @i += 2;
    END;
GO

Select * from dbo.t_memopt
Select NoLock From NoLock.NoLock.NoLock WITH (NOLOCK)


/*Examine the metadata for your checkpoint files.*/
SELECT  file_type_desc ,
        state_desc ,
        relative_file_path
FROM    sys.dm_db_xtp_checkpoint_files
ORDER BY file_type_desc
GO

-- Backup
Backup Log [NoLock] 
TO Disk = 'C:\SQL_Data\Backup\NoLock_Log1.TRN' 
WITH CHECKSUM, FORMAT, INIT, STATS=5


-- Failure of Filestream
Select * from dbo.t_memopt
Select NoLock From NoLock.NoLock.NoLock WITH (NOLOCK)




Use master
Go
Alter Database [NoLock] Set Offline

Alter Database [NoLock] Set Online
GO

Alter Database [NoLock] Set Emergency
GO

Alter Database [NoLock] modify file (name = 'NoLock_Container1',offline)
GO


Alter Database [NoLock] Set Online
GO

Use NoLock
Go

Select NoLock as NoLock From NoLock.NoLock.NoLock NoLock WITH (NOLOCK)

Select * from dbo.t_memopt


-- Restore Database
Use Master

Restore Database NoLock  FROM Disk = 'C:\SQL_Data\Backup\NoLock_Full_Init.bak' 
WITH FILE = 1, NORECOVERY, REPLACE

Restore Log NoLock FROM Disk = 'C:\SQL_Data\Backup\NoLock_Log1.TRN' 
WITH FILE = 1, NORECOVERY


Restore Database NoLock WITH RECOVERY

Use NoLock
GO

Select * from dbo.t_memopt

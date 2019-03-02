/* Create a new database for memory-optimized tables.*/
USE master
GO
IF DB_ID('NoLock') IS NOT NULL
    DROP DATABASE NoLock;
GO

CREATE DATABASE NoLock ON  
   PRIMARY (NAME = [NoLock_Primary], FILENAME = 'C:\SQL_Data\Data\NoLock_data.mdf'), 
   FILEGROUP [NoLock_IM] CONTAINS MEMORY_OPTIMIZED_DATA
      (NAME = [NoLock_Container1],
       FILENAME = 'E:\SAN\NoLock_Container1_container1')
 LOG ON (name = [NoLock_log], 
         Filename='C:\SQL_Data\Log\NoLock.ldf', size= 100 MB);
GO

ALTER DATABASE [NoLock] ADD FILEGROUP [NoLock]
GO
ALTER DATABASE [NoLock] ADD FILE ( NAME = N'NoLock_Data', FILENAME = N'C:\SQL_Data\Data\NoLock_Data.ndf' , SIZE = 8192KB , FILEGROWTH = 65536KB ) TO FILEGROUP [NoLock]
GO
IF NOT EXISTS (SELECT name FROM sys.filegroups WHERE is_default=1 AND name = N'NoLock') ALTER DATABASE [NoLock] MODIFY FILEGROUP [NoLock] DEFAULT
GO


Use NoLock
GO

CREATE SCHEMA [NoLock]
GO


/****** Object:  Table [dbo].[NoLock]    Script Date: 21/04/2017 3:44:23 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [NoLock].[NoLock](
	[NoLock] [smallint] NOT NULL,
	[Data] [varchar](1000) NULL,
 CONSTRAINT [PK_NoLock] PRIMARY KEY CLUSTERED 
(
	[NoLock] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [NoLock]
) ON [NoLock]

GO

-- create a memory-optimized table with each row of size > 8KB
CREATE TABLE dbo.t_memopt (
       c1 int NOT NULL,
       c2 char(40) NOT NULL,
       c3 char(8000) NOT NULL,
       CONSTRAINT [pk_t_memopt_c1] PRIMARY KEY NONCLUSTERED HASH (c1) 
        WITH (BUCKET_COUNT = 1000)
) WITH (MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA);
GO

Use master
Go



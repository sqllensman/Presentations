-- Example 4 - Database Corruption
-- Created by Steve Stedman  http://SteveStedman.

/*

Download Files at:
http://stevestedman.com/2015/04/sql-server-2008-downloads-for-the-database-corruption-challenge-dbcc-week-1/

*/

USE master;
GO

-- under SQLCMD Mode
:SETVAR BackupPath  "C:\DPS2018\DBFiles\SampleDB\CorruptionChallenge4"
:SETVAR RestorePath "C:\DPS2018\DBFiles"


RESTORE HEADERONLY FROM DISK = '$(BackupPath)\CorruptionChallenge4_Corrupt.bak'
RESTORE FILELISTONLY FROM DISK = '$(BackupPath)\CorruptionChallenge4_Corrupt.bak'

IF EXISTS(SELECT name
            FROM sys.databases
       WHERE name = 'CorruptionChallenge4')
BEGIN
    ALTER DATABASE [CorruptionChallenge4] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [CorruptionChallenge4];
END

RESTORE DATABASE [CorruptionChallenge4] 
   FROM DISK = N'$(BackupPath)\CorruptionChallenge4_Corrupt.bak' 
   WITH FILE = 1,
        MOVE N'CorruptionChallenge4' 
		  TO N'$(RestorePath)\Data\CorruptionChallenge4.mdf',  
        MOVE N'UserObjects' 
		  TO N'$(RestorePath)\Data\CorruptionChallenge4_UserObjects.ndf',  
        MOVE N'CorruptionChallenge4_log' 
		  TO N'$(RestorePath)\Log\CorruptionChallenge4_log.ldf',  
		REPLACE,
		STATS = 5;
GO

-- Step 2 Check Database
--DBCC CHECKDB('CorruptionChallenge4') WITH ALL_ERRORMSGS, NO_INFOMSGS
--commented out DBCC because it crashes after 15+ minutes
EXECUTE CheckDB.[dbo].[CheckDB_Extended] 
   @DatabaseName = 'CorruptionChallenge4'
-- Runs for 23 Minutes:
-- CHECKDB found 0 allocation errors and 518487 consistency errors in database 'CorruptionChallenge4'.
-- CHECKDB found 0 allocation errors and 4498 consistency errors in table 'Customers' (object ID 2105058535).

-- Step 3 Check Current User Objects - Before == 5
USE [CorruptionChallenge4]
GO


-- Step 4 Errors are related to Clustered Index 
-- Can use the Non clustered indexes to recorver all data except MiddleName
EXECUTE CheckDB.[dbo].[Get_IndexStructure] 'CorruptionChallenge4', '[dbo].[Customers]', 1

-- Require to disable Database Triggers
USE [CorruptionChallenge4]
GO

Select * from dbo.Customers
WHERE id in (510900, 510901)


DISABLE TRIGGER [noDropTables] ON DATABASE;
GO
DISABLE TRIGGER [noNewTables] ON DATABASE;
GO



-- Use Utility Function to analyse better
EXECUTE CheckDB.[dbo].[prc_ReadPageData]
	   @DatabaseName = 'CorruptionChallenge4'
	  ,@FileId = 3
	  ,@PageId = 2150

CREATE TABLE [dbo].[Customers_Copy](
	[id] [int] NOT NULL,
	[FirstName] [varchar](30) NULL,
	[MiddleName] [varchar](30) NULL,
	[LastName] [varchar](30) NULL,
 CONSTRAINT [PK_Customers_1] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [UserObjects]
) ON [UserObjects];

GO

-- GET what we can from the indexes.
INSERT INTO [dbo].[Customers_Copy](id, FirstName, MiddleName, LastName)
SELECT a.id, a.FirstName, '' as MiddleName, b.LastName
FROM 
(
	SELECT [id]
      ,[FirstName]
	FROM [CorruptionChallenge4].[dbo].[Customers]  
	WITH (INDEX(ncCustomerFirstname))
) a
INNER JOIN 
(
	SELECT [id]
      ,[LastName]
	FROM [CorruptionChallenge4].[dbo].[Customers] WITH (INDEX(ncCustomerLastname))
) b
ON a.id = b.id;
-- 511740 rows recovered

Select * from dbo.Customers_Copy
WHERE id in (510900, 510901)

-- Using DBCC Page data is intact in page but Allocation Data is incorrect
-- Can extract data via DBCC Page and Parse Data to obtain MiddleName


Use CorruptionChallenge4
GO

-- Create Table to store data from DBCC Page
CREATE TABLE [dbo].[Customers_Copy1](
	[id] [int] NOT NULL,
	[FirstName] [varchar](30) NULL,
	[MiddleName] [varchar](30) NULL,
	[LastName] [varchar](30) NULL,
 CONSTRAINT [PK_Customers_2] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [UserObjects]
) ON [UserObjects]

GO





DECLARE 
	@DBName VARCHAR(256) = 'CorruptionChallenge4', 
	@FileId INT = 3, 
	@PageId INT, 
	@DumpStyle int = 1;


CREATE TABLE #DBCCIND
(
  PageFID INT,
  PagePID INT,
  IAMFID INT,
  IAMPID INT,
  ObjectID INT,
  IndexID INT,
  PartitionNumber INT,
  PartitionID BIGINT,
  iam_chain_type VARCHAR(100),
  PageType INT,
  IndexLevel INT,
  NextPageFID INT,
  NextPagePID INT,
  PrevPageFID INT,
  PrevPagePID INT
);

/* create a temp table to hold dbcc page results */ 
CREATE TABLE #DBCC_Page 
( 
parentObject varchar(200), 
object varchar(200), 
field varchar(200), 
value varchar(200) 
) 

CREATE TABLE #DBCC_Data
(
	PageId int,
	parentObject varchar(200),
	value varchar(100), 
	I1 int,
	I2 int, 
	I3 int   
)

INSERT INTO #DBCCIND
  EXEC ('DBCC IND(''CorruptionChallenge4'', ''dbo.Customers'', 1)');
--SELECT * FROM #DBCCIND;

DECLARE @STR VARCHAR (2000) 

DECLARE db_cursor CURSOR FOR  
SELECT PagePID 
FROM #DBCCIND 
WHERE PageType = 1 

OPEN db_cursor   
FETCH NEXT FROM db_cursor INTO @PageId   

WHILE @@FETCH_STATUS = 0   
BEGIN   
	SET @STR='DBCC Page (' + @DBName + ',' + Cast(@FileId as varchar(3)) + ','+ 
		Cast(@PageId as varchar(100)) + ','+ 
		Cast(@DumpStyle as varchar(100)) + ') with tableresults'

	/* store the output of dbcc page into the temp table */ 
	insert into #DBCC_Page exec(@STR) 

	INSERT INTO #DBCC_Data(PageId, parentObject, value, I1, I2, I3)
	Select 
		@PageId as PageId,
		parentObject, 
		value, 
		CHARINDEX('Offset', parentObject, 1) as I1,
		CHARINDEX('Length', parentObject, 1) as I2, 
		CHARINDEX('DumpStyle', parentObject, 1) as I3   
	from #DBCC_Page
	WHERE object like 'Memory Dump %'

	DELETE FROM #DBCC_Page;

    FETCH NEXT FROM db_cursor INTO @PageId   
END   

CLOSE db_cursor   
DEALLOCATE db_cursor; 

SELECT top 100 *  
FROM #DBCC_Data;

WITH Translate as
(
SELECT 
	PageId,
	SUBSTRING(parentObject, 5, I1-7) as Slot,
	SUBSTRING(parentObject, I2+7, I3-I2-9) as Length,
	SUBSTRING(value,1,16) as LengthHex,
	SUBSTRING(value,20,45) as RawValues,
	SUBSTRING(value,67,20) as StringValues
FROM #DBCC_Data
), OrderedData as
(
	Select
		PageId,
		Slot,
		Length,
		LengthHex,
		RawValues,
		StringValues, 
		ROW_NUMBER() Over (Partition By PageId, Slot Order By LengthHex) as RowNum
	FROM Translate
) 
SELECT 
	a.PageId, 
	a.Slot, 
	a.Length, 
	a.RawValues + ' ' + b.RawValues as HexValues, 
	a.StringValues + b.StringValues as StringValues
INTO tmpCustomerData
FROM 
(
	Select PageId, Slot, Length, RawValues, StringValues, RowNum
	from OrderedData
	WHERE RowNum =1
) a
INNER JOIN
(
	Select PageId, Slot, Length, RawValues, StringValues, RowNum
	from OrderedData
	WHERE RowNum = 2
) b
ON a.Slot = b.Slot
AND a.PageId  = b.PageId
ORDER BY a.PageId, a.Slot;
GO

SELECT HexValues, * 
  FROM tmpCustomerData;

/*
30000800068f00000400000300160017001d0041766143485547484553
 
30 Status Bit A 1 Byte 
   Indicates bitmap, as well as a “variable columns” 
00 Status Bit B 1 Byte
0800 Total Length of Fixed Len Data including Status Bytes
	 2 Bytes
	 Little Endian so Byte Reversed
	 = 0008 in Hex
	 = 8 Bytes
	 => Fixed Len Data = 4 Bytes 
068f0000 Fixed Len Data (Id Field which is INT)
	4 Bytes
	Little Endian so Byte Reversed
	= 00008f06 in Hex
	= 36614
0400 Number Of Columns in NULL BitMap
	2 Bytes
	Little Endian so Byte Reversed
	= 0004 in Hex
	= 4
00  Null BitMap - 1 Bit Per Column
	1 Byte
0300 Number of Variable Length Columns
	 2 Bytes
	Little Endian so Byte Reversed
	= 0003 in Hex
	= 3
160017001d00 
	Variable Column Offset Array
	2 Bytes for each Variable Length Columns
	= 6 Bytes
	Little Endian so Byte Reversed
	Array in Hex = 0016, 0017, 001d
	Array = (22, 23, 29)
41766143485547484553  
	Variable Length Data
	Starts after Byte (1+1+2+4+2+1+2+6 = 19)
	First Column ends at 22 => Length = 3
	= 417661 in Hex
	= Char(65) + Char(118) + Char(97)
	= 'Ava'                   
	Second Column ends at 23 => Length = 1
	= 43 in Hex
	= CHAR(67)
	= 'C'
	Third Column ends at 29 => Length = 6
	= 485547484553 in Hex
	= Char(72) + Char(85) + Char(71) + Char(72) + Char(69) + Char(83)
	= 'HUGHES'
*/

-- Needs folllowing function
CREATE FUNCTION dbo.HexStrToVarBinary(@hexstr varchar(8000))
RETURNS varbinary(8000)
AS
BEGIN 
    DECLARE @hex char(1), @i int, @place bigint, @a bigint
    SET @i = LEN(@hexstr) 

    SET @place = convert(bigint,1)
    SET @a = convert(bigint, 0)

    WHILE (@i > 0 AND (SUBSTRING(@hexstr, @i, 1) like '[0-9A-Fa-f]')) 
    BEGIN 
        SET @hex = SUBSTRING(@hexstr, @i, 1) 
        SET @a = @a + 
    convert(bigint, CASE WHEN @hex LIKE '[0-9]' 
         THEN CAST(@hex as int) 
         ELSE CAST(ASCII(UPPER(@hex))-55 as int) end * @place)
		SET @place = @place * convert(bigint,16)
        SET @i = @i - 1
    END 
    RETURN convert(varbinary(8000),@a)
END;
GO 

WITH Data AS
(
	SELECT 
	PageId, Slot, Length, HexValues, StringValues,                     
	CAST(dbo.HexStrToVarBinary('0x' + SUBSTRING(HexValues, 17, 2) + SUBSTRING(HexValues, 15,2) + SUBSTRING(HexValues, 13,2) + SUBSTRING(HexValues, 11,2)) AS INT) as id,
	CAST(dbo.HexStrToVarBinary('0x' + SUBSTRING(HexValues, 33, 2) + SUBSTRING(HexValues, 31,2)) AS INT) as V1,
	CAST(dbo.HexStrToVarBinary('0x' + SUBSTRING(HexValues, 38, 2) + SUBSTRING(HexValues, 35,2)) AS INT) as V2
	FROM   tmpCustomerData
)
INSERT INTO [dbo].[Customers_Copy1](id, FirstName, MiddleName, LastName)
SELECT Data.id,
	   SUBSTRING(StringValues,20, V1-19),
	   SUBSTRING(StringValues,V1+1, V2-V1),
	   SUBSTRING(StringValues,V2+1, 50)
  FROM Data;
-- 511740 rows inserted

-- to take a look at Customers Copy 1.
SELECT Top 10 * 
  FROM Customers_Copy1;

Select *
FROM Customers_Copy1
WHERE id = 36614

-- Compare to data extracted from Non-Clustered
SELECT Count(*)
FROM Customers_Copy1 c1
INNER JOIN Customers_Copy c2
	ON c1.id = c2.id;
-- 511740 rows matching

-- All Names match
Select Count(*)
FROM Customers_Copy1 c1
INNER JOIN Customers_Copy c2
	ON c1.id = c2.id
WHERE c1.FirstName <> c2.FirstName
OR c2.LastName <> c2.LastName;



-- now to clean up....
-- Step1 Restore Data to original Table (need to disableFK)
USE [CorruptionChallenge4]
GO

ALTER TABLE [dbo].[Orders] DROP CONSTRAINT [FK_Orders_People]
GO

SET IDENTITY_INSERT Customers ON

TRUNCATE TABLE [dbo].[Customers]

INSERT INTO [dbo].[Customers](id, FirstName, MiddleName, LastName)
SELECT 
	id, FirstName, MiddleName, LastName
FROM [dbo].[Customers_Copy1];

SET IDENTITY_INSERT Customers OFF

-- Check Corruption fixed
DBCC CHECKDB('CorruptionChallenge4') WITH ALL_ERRORMSGS, NO_INFOMSGS


-- Clean UP 
-- (a) Restore FK
ALTER TABLE [dbo].[Orders]  WITH CHECK ADD  CONSTRAINT [FK_Orders_People] FOREIGN KEY([customerId])
REFERENCES [dbo].[Customers] ([id])
GO

ALTER TABLE [dbo].[Orders] CHECK CONSTRAINT [FK_Orders_People]
GO

-- (b) Drop Temporary objects
USE [CorruptionChallenge4];
GO

DROP TABLE [dbo].[Customers_Copy];
DROP TABLE [dbo].[Customers_Copy1];
DROP TABLE [dbo].[tmpCustomerData];
DROP FUNCTION [dbo].[HexStrToVarBinary];

DROP TABLE #DBCCIND;
DROP TABLE #DBCC_PAGE;
DROP TABLE #DBCC_Data;

GO

--(c) Restore Triggers
ENABLE TRIGGER [noDropTables] ON DATABASE;
ENABLE TRIGGER [noNewTables] ON DATABASE;


-- (e) Check Data
Select * from dbo.Customers
WHERE id in (510900, 510901)

--510900	Steve	M	Stedman
--510901	William	V	STARK
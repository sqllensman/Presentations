/*

Notes 
Requires a copy for the Corruption Challenge 7 Files From SteveStedman.com

http://stevestedman.com/2015/04/sql-server-2008-downloads-for-the-database-corruption-challenge-dbcc-week-1/

https://stevestedman.com/2015/06/database-corruption-challenge-week-7-alternate-solution/

*/


-- Step 1 Create database using supplied files
USE master;
GO
IF DB_ID ('CorruptionChallenge7') IS NOT NULL
BEGIN 
     ALTER DATABASE CorruptionChallenge7 SET SINGLE_USER WITH ROLLBACK IMMEDIATE
	 DROP DATABASE CorruptionChallenge7
END

---- Attached Supplied Files (Will upgrade database to current version)
--   Use Powershell Script: Copy-Files2.ps1 to copy files
--   Needs to be run as Administrator to ensure no file permission errors
---- Original files in CorruptionChallenge7.zip
CREATE DATABASE [CorruptionChallenge7] ON 
( FILENAME = N'C:\SQLSaturday\DBFiles\SampleDB\CorruptionChallenge7\ReadLog\CorruptionChallenge7.mdf' ),
( FILENAME = N'C:\SQLSaturday\DBFiles\SampleDB\CorruptionChallenge7\ReadLog\CorruptionChallenge7_log.ldf' ),
( FILENAME = N'C:\SQLSaturday\DBFiles\SampleDB\CorruptionChallenge7\ReadLog\UserObjects.ndf' )
 FOR ATTACH
GO


-- Step 2 Extract and Parse data from log file
Use CorruptionChallenge7
GO

Select * from [OPEN_NFIRS].[Record1000];

/*
fn_dblog

https://www.sqlskills.com/blogs/paul/using-fn_dblog-fn_dump_dblog-and-restoring-with-stopbeforemark-to-an-lsn/

http://rusanu.com/2014/03/10/how-to-read-and-interpret-the-sql-server-log/

*/ 
SELECT  
	[TRANSACTION ID] as TransactionID,
	[Begin Time] as BeginTime, *
FROM sys.fn_dblog(NULL, NULL) 
WHERE Context IN ('LCX_NULL') 
AND Operation in ('LOP_BEGIN_XACT')  
And [Transaction Name] In ('DELETE')
ORDER BY [Begin Time] Desc


Declare @TransactionID varchar(30); 
Declare @AllocUnitId BigInt;

Select @TransactionID = TransactionID from
( 
	SELECT  TOP 1 
		[TRANSACTION ID] as TransactionID,
		[Begin Time] as BeginTime 
	FROM sys.fn_dblog(NULL, NULL) 
	WHERE Context IN ('LCX_NULL') 
	AND Operation in ('LOP_BEGIN_XACT')  
	And [Transaction Name] In ('DELETE')
	ORDER BY [Begin Time] Desc
) a;

Select @TransactionID 

if object_id('tempdb..#RowData') is not NULL DROP table #RowData;

CREATE TABLE #RowData(
	[RowID] INT IDENTITY(1,1),
	[RowLogContents] [varbinary](8000) NULL,
	[AllocUnitID] [bigint] NULL,
	[TransactionID] [varchar](14) NOT NULL,
	[SlotId] [int] NULL,
	[FixedLengthData] [smallint] NULL,
	[TotalNoOfCols] [smallint],
	[NullBitMapLength] [smallint],
	[NullBytes]         VARBINARY(8000),
	[TotalNoofVarCols] [smallint],
	[ColumnOffsetArray] VARBINARY(8000),
	[VarColumnStart] [smallint],
	[NullBitMap] varchar(128)
); 


WITH RowData(RowLogContents, AllocUnitID, TransactionID, SlotId, FixedLengthData) AS 
(
	SELECT
		 [RowLog Contents 0] -- Contains deleted data
		,[AllocUnitID] 
		,[Transaction ID] 
		,[Slot ID]
		,CONVERT(SMALLINT,CONVERT(BINARY(2), REVERSE(SUBSTRING([RowLog Contents 0], 3, 2))))
	FROM sys.fn_dblog(NULL, NULL)
	WHERE SUBSTRING([RowLog Contents 0], 1, 1)In (0x10,0x30,0x70)
	AND [Transaction ID] = @TransactionID
)
INSERT INTO #RowData(RowLogContents, AllocUnitID, TransactionID, SlotId, FixedLengthData)  
Select 
	RowLogContents 
	,AllocUnitID 
	,TransactionID 
	,SlotId 
	,FixedLengthData
from RowData; 

-- Look at Data Extracted
SELECT * FROM #RowData

-- 
Select
	pc.partition_id,
	p.object_id, 
	o.schema_id,
	SCHEMA_NAME(o.schema_id) as SchemaName,
	o.name as ObjectName,
	pc.partition_column_id,
	c.name as ColumnName,
	pc.system_type_id,
	t.name,
	pc.max_length,
	pc.max_inrow_length,
	pc.precision,
	pc.is_nullable,
	pc.is_dropped,
	pc.leaf_offset,
	pc.leaf_null_bit
from sys.system_internals_partition_columns pc
INNER JOIN sys.partitions p
	on p.partition_id = pc.partition_id
INNER JOIN sys.objects o
	on o.object_id = p.object_id
INNER JOIN sys.types t
	on t.system_type_id = pc.system_type_id
LEFT JOIN sys.columns c
	on c.column_id = pc.partition_column_id
	AND c.object_id = p.object_id
WHERE pc.partition_id = 
(
	Select container_id from sys.allocation_units
	WHERE allocation_unit_id = (Select Top 1 AllocUnitID FROM #RowData)
)

-- Add additional data on Structure
Update #RowData
Set TotalNoOfCols = 
	CONVERT(INT, CONVERT(BINARY(2), REVERSE(SUBSTRING(RowLogContents, FixedLengthData + 1, 2))))
from #RowData

Update #RowData
Set NullBitMapLength = -- [NullBitMapLength]=ceiling([Total No of Columns] /8.0)
	CONVERT(INT, ceiling(TotalNoOfCols/8.0)) 
from #RowData;

Update #RowData
Set NullBytes = --[Null Bytes] = Substring (RowLog content 0, Status Bit A+ Status Bit B + [Fixed Length Data] +1, [NullBitMapLength] )
	SUBSTRING(RowLogContents, FixedLengthData + 3, NullBitMapLength),
	TotalNoofVarCols = --[TotalNoofVarCols] = Substring (RowLog content 0, Status Bit A+ Status Bit B + [Fixed Length Data] +1, [Null Bitmap length] + 2 )
	CASE 
		WHEN SUBSTRING(RowLogContents, 1, 1) In (0x10,0x30,0x70) 
			THEN CONVERT(INT, CONVERT(BINARY(2), REVERSE(SUBSTRING(RowLogContents, FixedLengthData + 3 + NullBitMapLength, 2))))  
		ELSE null  
	END
from #RowData;

Update #RowData
Set ColumnOffsetArray = --[ColumnOffsetArray]= Substring (RowLog content 0, Status Bit A+ Status Bit B + [Fixed Length Data] +1, [Null Bitmap length] + 2 , [TotalNoofVarCols]*2 )
	CASE 
		WHEN SUBSTRING(RowLogContents, 1, 1) In (0x10,0x30,0x70) 
		THEN SUBSTRING(RowLogContents, FixedLengthData + 3 + NullBitMapLength + 2, 
			(CASE 
				WHEN SUBSTRING(RowLogContents, 1, 1) In (0x10,0x30,0x70) 
				THEN CONVERT(INT, CONVERT(BINARY(2), REVERSE(SUBSTRING(RowLogContents, FixedLengthData + 3 + NullBitMapLength, 2))))  
				ELSE null  
			 END) * 2)  
		ELSE null  
	END,
	VarColumnStart = --  Variable column Start = Status Bit A+ Status Bit B + [Fixed Length Data] + [Null Bitmap length] + 2+([TotalNoofVarCols]*2)
	CASE
		WHEN SUBSTRING(RowLogContents, 1, 1)In (0x10,0x30,0x70)
		THEN  (FixedLengthData + 4 + NullBitMapLength 
		+ ((CASE WHEN SUBSTRING(RowLogContents, 1, 1) In (0x10,0x30,0x70) 
				 THEN CONVERT(INT, CONVERT(BINARY(2), REVERSE(SUBSTRING(RowLogContents, FixedLengthData + 3 + NullBitMapLength, 2))))  
				 ELSE null  
			END) * 2))
		ELSE null 
	End,
	NullBitMap = CheckDB.dbo.UDF_Convert_Hex_to_Binary(NullBytes)
from #RowData;

SELECT * FROM #RowData

/* 
Parse Table
*/

CREATE TABLE #ColumnNameAndData
(
 [RowID]           int,
 [Rowlogcontents]   varbinary(Max),
 [ColumnName]       sysname,
 [nullbit]          smallint,
 [leaf_offset]      smallint,
 [length]           smallint,
 [system_type_id]   tinyint,
 [bitpos]           tinyint,
 [xprec]            tinyint,
 [xscale]           tinyint,
 [is_null]          int,
 [ColumnValueSize]	int,
 [ColumnLength]		int,
 [hex_Value]        varbinary(max),
 [SlotID]          int,
 [Updated]           int
);
 
 
--Create common table expression and join it with the rowdata table
-- to get each column details
-- varlength data
With ColumnNameInfo(RowID, Rowlogcontents, ColumnName, nullbit, leaf_offset, length, system_type_id, bitpos, xprec, xscale, is_null, VarColOffsetEnd, VarColOffsetStart, VarColumnStart, SlotId) as
(
	SELECT
		[RowID],
		Rowlogcontents,
		[NAME] ,
		cols.leaf_null_bit AS nullbit,
		leaf_offset,
		ISNULL(syscolumns.length, cols.max_length) AS [length],
		cols.system_type_id,
		cols.leaf_bit_position AS bitpos,
		ISNULL(syscolumns.xprec, cols.precision) AS xprec,
		ISNULL(syscolumns.xscale, cols.scale) AS xscale,
		SUBSTRING([nullBitMap], cols.leaf_null_bit, 1) AS is_null,
		CONVERT(INT, CONVERT(BINARY(2), REVERSE (SUBSTRING ([ColumnOffsetArray], (2 * leaf_offset*-1) - 1, 2)))) as VarColOffsetEnd,
		CONVERT(INT, CONVERT(BINARY(2), REVERSE (SUBSTRING ([ColumnOffsetArray], (2 * ((leaf_offset*-1) - 1)) - 1, 2)))) as VarColOffsetStart,
		VarColumnStart,
		SlotId
	FROM #RowData A
	Inner Join sys.allocation_units allocunits 
		On A.[AllocUnitId]=allocunits.[Allocation_Unit_Id]
	INNER JOIN sys.partitions partitions 
		ON (allocunits.type IN (1, 3) AND partitions.hobt_id = allocunits.container_id) 
		OR (allocunits.type = 2 AND partitions.partition_id = allocunits.container_id)
	INNER JOIN sys.system_internals_partition_columns cols 
		ON cols.partition_id = partitions.partition_id
	LEFT OUTER JOIN syscolumns 
		ON syscolumns.id = partitions.object_id 
		AND syscolumns.colid = cols.partition_column_id
	WHERE leaf_offset<0
), VarLengthData as
(
	Select
	c.*,
	[Column value Size] =  
 		(CASE 
			WHEN leaf_offset<1 and is_null=0 
			THEN
				(Case 
					When    VarColOffsetEnd > 30000
					THEN	VarColOffsetEnd - POWER(2, 15)
					ELSE    VarColOffsetEnd
				END)
		 END),
	VarColOffsetStartAdj = ISNULL(NULLIF(VarColOffsetStart, 0), [VarColumnStart])
	from ColumnNameInfo c
), HexDataInfo as
(
	Select vd.*,
	 [Column Length] =
	 (CASE 
		WHEN leaf_offset<1 and is_null=0  
		THEN
			(Case
				When VarColOffsetEnd > 30000 And VarColOffsetStartAdj < 30000
				THEN  
					(Case 
						When [system_type_id] In (35,34,99) 
							Then 16 
							else 24  
					 end)
		When VarColOffsetEnd >30000 And VarColOffsetStartAdj>30000
			THEN  
			(Case 
				When [system_type_id] In (35,34,99) 
					Then 16 
					else 24  
			 end) --24 
		When VarColOffsetEnd <30000 And VarColOffsetStartAdj<30000
			THEN (VarColOffsetEnd - VarColOffsetStartAdj)
		When VarColOffsetEnd <30000 And VarColOffsetStartAdj>30000
			THEN POWER(2, 15) +VarColOffsetEnd - VarColOffsetStartAdj
		END)
	 END),
	[VarColStart] =
	(Case
		When VarColOffsetEnd > 30000
			THEN VarColOffsetEnd - POWER(2, 15)
		ELSE
			VarColOffsetEnd
	END) -
    (Case 
		When VarColOffsetEnd > 30000 And VarColOffsetStartAdj < 30000
			THEN  (Case When [system_type_id] In (35,34,99) Then 16 else 24  end) 
		When VarColOffsetEnd > 30000 And VarColOffsetStartAdj>30000
			THEN  (Case When [system_type_id] In (35,34,99) Then 16 else 24  end)
		When VarColOffsetEnd < 30000 And VarColOffsetStartAdj < 30000
			THEN VarColOffsetEnd - VarColOffsetStartAdj
		When VarColOffsetEnd < 30000 And VarColOffsetStartAdj > 30000
			THEN POWER(2, 15) +VarColOffsetEnd - VarColOffsetStartAdj
	END) + 1,
	VarDataLength =
	(Case 
		When VarColOffsetEnd > 30000 And VarColOffsetStartAdj < 30000
			THEN (Case When [system_type_id] In (35,34,99) Then 16 else 24  end) 
		When VarColOffsetEnd > 30000 And VarColOffsetStartAdj > 30000
			THEN (Case When [system_type_id] In (35,34,99) Then 16 else 24  end)  
		When VarColOffsetEnd < 30000 And VarColOffsetStartAdj < 30000
			THEN ABS(VarColOffsetEnd - VarColOffsetStartAdj)
		When VarColOffsetEnd < 30000 And VarColOffsetStartAdj > 30000
			THEN POWER(2, 15) + VarColOffsetEnd - VarColOffsetStartAdj
	END)
	FROM VarLengthData vd
)
INSERT INTO #ColumnNameAndData(RowID, Rowlogcontents, ColumnName, nullbit, leaf_offset, [length],system_type_id, bitpos, xprec, xscale, is_null, ColumnValueSize, ColumnLength, hex_Value, SlotID, Updated)
Select hd.RowID, hd.Rowlogcontents, hd.ColumnName, hd.nullbit, hd.leaf_offset, hd.[length], hd.system_type_id, hd.bitpos, hd.xprec, hd.xscale, hd.is_null, hd.[Column value Size], hd.[Column Length],
	hex_Value = 
	(CASE 
		WHEN is_null=1 AND VarDataLength = 0 THEN NULL 
		ELSE
			SUBSTRING(Rowlogcontents, VarColStart, VarDataLength) 
	END), 
	hd.SlotId, 
	0 as Updated	 
FROM HexDataInfo hd;

Select * from #ColumnNameAndData
ORDER BY RowID

INSERT INTO #ColumnNameAndData(RowID, Rowlogcontents, ColumnName, nullbit, leaf_offset, [length],system_type_id, bitpos, xprec, xscale, is_null, ColumnValueSize, ColumnLength, hex_Value, SlotID, Updated)
SELECT 
	[RowID],
	Rowlogcontents,
	[NAME] ,
	cols.leaf_null_bit AS nullbit,
	leaf_offset,
	ISNULL(syscolumns.length, cols.max_length) AS [length],
	cols.system_type_id,
	cols.leaf_bit_position AS bitpos,
	ISNULL(syscolumns.xprec, cols.precision) AS xprec,
	ISNULL(syscolumns.xscale, cols.scale) AS xscale,
	SUBSTRING([nullBitMap], cols.leaf_null_bit, 1) AS is_null,
	(
	 SELECT TOP 1 ISNULL(SUM(CASE WHEN C.leaf_offset >1 THEN max_length ELSE 0 END),0) 
	 FROM sys.system_internals_partition_columns C 
	 WHERE cols.partition_id =C.partition_id 
	 And C.leaf_null_bit<cols.leaf_null_bit
	 )+5 AS [Column value Size],
	syscolumns.length AS [Column Length]
	,CASE 
		WHEN SUBSTRING([nullBitMap], cols.leaf_null_bit, 1) =1 
			THEN NULL 
		ELSE
			SUBSTRING(Rowlogcontents,(SELECT TOP 1 ISNULL(SUM(CASE WHEN C.leaf_offset >1 And C.leaf_bit_position=0 THEN max_length ELSE 0 END),0) FROM
			sys.system_internals_partition_columns C where cols.partition_id =C.partition_id And C.leaf_null_bit<cols.leaf_null_bit)+5
			,syscolumns.length) END AS hex_Value
	,[SlotID]
	,0
FROM #RowData A
Inner Join sys.allocation_units allocunits ON A.[AllocUnitId]=allocunits.[Allocation_Unit_Id]
INNER JOIN sys.partitions partitions ON (allocunits.type IN (1, 3)
AND partitions.hobt_id = allocunits.container_id) OR (allocunits.type = 2 AND partitions.partition_id = allocunits.container_id)
INNER JOIN sys.system_internals_partition_columns cols ON cols.partition_id = partitions.partition_id
LEFT OUTER JOIN syscolumns ON syscolumns.id = partitions.object_id AND syscolumns.colid = cols.partition_column_id
WHERE leaf_offset>0;

SELECT * FROM #ColumnNameAndData
WHERE RowID =1

CREATE TABLE [#RecoverdData]
(
    [ColumnName]  VARCHAR(MAX),
	[ColOrder] SMALLINT,
    [FieldValue] NVARCHAR(MAX),
    [Rowlogcontents] VARBINARY(8000),
    [RowID] int
)
 
INSERT INTO #RecoverdData(ColumnName, ColOrder, FieldValue, Rowlogcontents, RowID) 
SELECT ColumnName,
nullbit,
CASE
 WHEN system_type_id IN (231, 239) THEN  LTRIM(RTRIM(CONVERT(NVARCHAR(max),hex_Value)))  --NVARCHAR ,NCHAR
 WHEN system_type_id IN (167,175) THEN  LTRIM(RTRIM(CONVERT(VARCHAR(max),hex_Value)))  --VARCHAR,CHAR
 WHEN system_type_id IN (35) THEN  LTRIM(RTRIM(CONVERT(VARCHAR(max),hex_Value))) --Text
 WHEN system_type_id IN (99) THEN  LTRIM(RTRIM(CONVERT(NVARCHAR(max),hex_Value))) --nText 
 WHEN system_type_id = 48 THEN CONVERT(VARCHAR(MAX), CONVERT(TINYINT, CONVERT(BINARY(1), REVERSE (hex_Value)))) --TINY INTEGER
 WHEN system_type_id = 52 THEN CONVERT(VARCHAR(MAX), CONVERT(SMALLINT, CONVERT(BINARY(2), REVERSE (hex_Value)))) --SMALL INTEGER
 WHEN system_type_id = 56 THEN CONVERT(VARCHAR(MAX), CONVERT(INT, CONVERT(BINARY(4), REVERSE(hex_Value)))) -- INTEGER
 WHEN system_type_id = 127 THEN CONVERT(VARCHAR(MAX), CONVERT(BIGINT, CONVERT(BINARY(8), REVERSE(hex_Value))))-- BIG INTEGER
 WHEN system_type_id = 61 Then CONVERT(VARCHAR(MAX),CONVERT(DATETIME,CONVERT(VARBINARY(8000),REVERSE (hex_Value))),100) --DATETIME
 WHEN system_type_id =58 Then CONVERT(VARCHAR(MAX),CONVERT(SMALLDATETIME,CONVERT(VARBINARY(8000),REVERSE(hex_Value))),100) --SMALL DATETIME
 WHEN system_type_id = 108 THEN CONVERT(VARCHAR(MAX),CONVERT(NUMERIC(38,20), CONVERT(VARBINARY,CONVERT(VARBINARY(1),xprec)+CONVERT(VARBINARY(1),xscale))+CONVERT(VARBINARY(1),0) + hex_Value)) --- NUMERIC
 WHEN system_type_id =106 THEN CONVERT(VARCHAR(MAX), CONVERT(DECIMAL(38,20), CONVERT(VARBINARY,Convert(VARBINARY(1),xprec)+CONVERT(VARBINARY(1),xscale))+CONVERT(VARBINARY(1),0) + hex_Value)) --- DECIMAL
 WHEN system_type_id In(60,122) THEN CONVERT(VARCHAR(MAX),Convert(MONEY,Convert(VARBINARY(8000),Reverse(hex_Value))),2) --MONEY,SMALLMONEY
 WHEN system_type_id = 104 THEN CONVERT(VARCHAR(MAX),CONVERT (BIT,CONVERT(BINARY(1), hex_Value)%2))  -- BIT
 WHEN system_type_id =62 THEN  RTRIM(LTRIM(STR(CONVERT(FLOAT,SIGN(CAST(CONVERT(VARBINARY(8000),Reverse(hex_Value)) AS BIGINT)) * (1.0 + (CAST(CONVERT(VARBINARY(8000),Reverse(hex_Value)) AS BIGINT) & 0x000FFFFFFFFFFFFF) * POWER(CAST(2 AS FLOAT), -52)) * POWER(CAST(2 AS FLOAT),((CAST(CONVERT(VARBINARY(8000),Reverse(hex_Value)) AS BIGINT) & 0x7ff0000000000000) / EXP(52 * LOG(2))-1023))),53,LEN(hex_Value)))) --- FLOAT
 When system_type_id =59 THEN  Left(LTRIM(STR(CAST(SIGN(CAST(Convert(VARBINARY(8000),REVERSE(hex_Value)) AS BIGINT))* (1.0 + (CAST(CONVERT(VARBINARY(8000),Reverse(hex_Value)) AS BIGINT) & 0x007FFFFF) * POWER(CAST(2 AS Real), -23)) * POWER(CAST(2 AS Real),(((CAST(CONVERT(VARBINARY(8000),Reverse(hex_Value)) AS INT) )& 0x7f800000)/ EXP(23 * LOG(2))-127))AS REAL),23,23)),8) --Real
 WHEN system_type_id In (165,173) THEN (CASE WHEN CHARINDEX(0x,cast('' AS XML).value('xs:hexBinary(sql:column("hex_Value"))', 'VARBINARY(8000)')) = 0 THEN '0x' ELSE '' END) +cast('' AS XML).value('xs:hexBinary(sql:column("hex_Value"))', 'varchar(max)') -- BINARY,VARBINARY
 WHEN system_type_id =34 THEN (CASE WHEN CHARINDEX(0x,cast('' AS XML).value('xs:hexBinary(sql:column("hex_Value"))', 'VARBINARY(8000)')) = 0 THEN '0x' ELSE '' END) +cast('' AS XML).value('xs:hexBinary(sql:column("hex_Value"))', 'varchar(max)')  --IMAGE
 WHEN system_type_id =36 THEN CONVERT(VARCHAR(MAX),CONVERT(UNIQUEIDENTIFIER,hex_Value)) --UNIQUEIDENTIFIER
 WHEN system_type_id =231 THEN CONVERT(VARCHAR(MAX),CONVERT(sysname,hex_Value)) --SYSNAME
 WHEN system_type_id =241 THEN CONVERT(VARCHAR(MAX),CONVERT(xml,hex_Value)) --XML
 
 WHEN system_type_id =189 THEN (CASE WHEN CHARINDEX(0x,cast('' AS XML).value('xs:hexBinary(sql:column("hex_Value"))', 'VARBINARY(8000)')) = 0 THEN '0x' ELSE '' END) +cast('' AS XML).value('xs:hexBinary(sql:column("hex_Value"))', 'varchar(max)') --TIMESTAMP
 WHEN system_type_id=98 THEN (CASE
 WHEN CONVERT(INT,SUBSTRING(hex_Value,1,1))=56 THEN CONVERT(VARCHAR(MAX), CONVERT(INT, CONVERT(BINARY(4), REVERSE(Substring(hex_Value,3,Len(hex_Value))))))  -- INTEGER
 WHEN CONVERT(INT,SUBSTRING(hex_Value,1,1))=108 THEN CONVERT(VARCHAR(MAX),CONVERT(numeric(38,20),CONVERT(VARBINARY(1),Substring(hex_Value,3,1)) +CONVERT(VARBINARY(1),Substring(hex_Value,4,1))+CONVERT(VARBINARY(1),0) + Substring(hex_Value,5,Len(hex_Value)))) --- NUMERIC
 WHEN CONVERT(INT,SUBSTRING(hex_Value,1,1))=167 THEN LTRIM(RTRIM(CONVERT(VARCHAR(max),Substring(hex_Value,9,Len(hex_Value))))) --VARCHAR,CHAR
 WHEN CONVERT(INT,SUBSTRING(hex_Value,1,1))=36 THEN CONVERT(VARCHAR(MAX),CONVERT(UNIQUEIDENTIFIER,Substring((hex_Value),3,20))) --UNIQUEIDENTIFIER
 WHEN CONVERT(INT,SUBSTRING(hex_Value,1,1))=61 THEN CONVERT(VARCHAR(MAX),CONVERT(DATETIME,CONVERT(VARBINARY(8000),REVERSE (Substring(hex_Value,3,LEN(hex_Value)) ))),100) --DATETIME
 WHEN CONVERT(INT,SUBSTRING(hex_Value,1,1))=165 THEN '0x'+ SUBSTRING((CASE WHEN CHARINDEX(0x,cast('' AS XML).value('xs:hexBinary(sql:column("hex_Value"))', 'VARBINARY(8000)')) = 0 THEN '0x' ELSE '' END) +cast('' AS XML).value('xs:hexBinary(sql:column("hex_Value"))', 'varchar(max)'),11,LEN(hex_Value)) -- BINARY,VARBINARY
 END)  
END AS FieldValue
,[Rowlogcontents]
,[RowID]
FROM #ColumnNameAndData 
ORDER BY RowID, nullbit

SELECT * FROM #RecoverdData
WHERE RowID = 1

-- Step 3 Insert data back into table
-- Insert into table
SET IDENTITY_INSERT [OPEN_NFIRS].[Record1000] ON;
GO

INSERT into [OPEN_NFIRS].[Record1000]([Record1000Id],[FireDeptID],[FireDeptState],[AlarmDate],[IncidentNumber],[ExposureNumberZeroBased],[RecordType],[TransactionType],[FireDepartmentStation])
SELECT [Record1000Id],[FireDeptID],[FireDeptState],[AlarmDate],[IncidentNumber],[ExposureNumberZeroBased],[RecordType],[TransactionType],[FireDepartmentStation]
FROM (
	Select 
		ColumnName,
		FieldValue,
		RowId
    FROM #RecoverdData
	) a
PIVOT (Min([FieldValue]) FOR ColumnName IN ([Record1000Id],[FireDeptID],[FireDeptState],[AlarmDate],[IncidentNumber],[ExposureNumberZeroBased],[RecordType],[TransactionType],[FireDepartmentStation])) AS pvt 

SET IDENTITY_INSERT [OPEN_NFIRS].[Record1000] OFF;

SElect * from [OPEN_NFIRS].[Record1000]
WHERE Record1000Id = -9223372036854775808

-- Step 4 Cleanup
Drop Table #RowData
Drop Table #ColumnNameAndData
DROP Table #RecoverdData

/*
Conversion of Raw Record

-- Hex Data for RowID = 1
RowLogContents
0x30000C000000000000000080090000FE0800270029003100380039003D003D004000574136323057413230313330373137313330303835393031303030303431

-- Remove 0x as added to indicate Hex Value 
30 Status Bits A 1 Byte
	-- null bitmap, as well as a “variable columns” 
00 Status Bit B 1 Byte
0C00 Total Length of Fixed Len Data including Status Bytes
	 2 Bytes
	 Little Endian so Byte Reversed
	 = 000C in Hex
	 = 12 Bytes
	 => Fixed Len Data = 8 Bytes

0000000000000080 
	Fixed Len Data (Record1000Id BigInt)
	8 Bytes
	Little Endian so Byte Reversed
	= 8000000000000000 in Hex
	= -9223372036854775808
0900 Number Of Columns in NULL BitMap
	2 Bytes
	Little Endian so Byte Reversed
	= 0009 in Hex
	= 9

00FE  Null BitMap - 1 Bit Per Column
	2 Bytes (9 Columns so needs 2 Bytes)
	= 11111110
	Indicates First Column Not Nullable
	Next 8 Columns nullable 
	Extra Values ignored (Read Right to Left)

0800 Number of Variable Length Columns
	2 Bytes
	Little Endian so Byte Reversed
	= 0008 in Hex
	= 8

270029003100380039003D003D004000
	Variable Column Offset Array
	2 Bytes for each Variable Length Columns
	= 16 Bytes
	Little Endian so Byte Reversed
	Array in Hex = 0027, 0029, 0031, 0038, 0039, 003D, 003D, 0040
	Array = (39, 41, 49, 56, 57, 61, 61, 64)

574136323057413230313330373137313330303835393031303030303431
	Variable Length Data
	Starts after Byte (1+1+2+8+2+2+2+16 = 34)
	First Column ends at 39 => Length = 5
	= 5741363230 in Hex
	= Select Char(0x57) + Char(0x41) + Char(0x36) + Char(0x32) + Char(0x33)
	= 'WA623'                   
	Second Column ends at 41 => Length = 2
	= 5741 in Hex
	= Char(0x57) + Char(0x41)
	= 'WA'
	Third Column ends at 49 => Length = 8
	= 3230313330373137 in Hex
	= Select Char(0x32) + Char(0x30) + Char(0x31) + Char(0x33) + Char(0x30) + Char(0x37) + Char(0x31) + Char(0x37)
	= '20130717'
	Fourth Column ends at 56 => Length = 7
	= 31333030383539 in Hex
	= Select Char(0x31) + Char(0x33) + Char(0x30) + Char(0x30) + Char(0x38) + Char(0x35) + Char(0x39)
	= '1300859'
	Fifth Column ends at 57 => Length = 1
	= 30 in Hex
	= Select Char(0x30)
	= '0'
	Sixth Column ends at 61 => Length = 4
	= 31303030 in Hex
	= Select Char(0x31) + Char(0x30) + Char(0x30) + Char(0x30)
	= '1000'
	7th Column ends at 61 => Length = 0
	=  in Hex
	= ''
	8th Column ends at 64 => Length = 3
	= 303431 in Hex
	= Select Char(0x30) + Char(0x34) + Char(0x31)
	= '041'
*/



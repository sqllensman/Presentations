/*

DBCC PAGE('Northwind', 1,616,2) WITH TABLERESULTS


Exec CheckDB.[dbo].[prc_ReadPageData] 'Northwind', 1,616

*/

Declare @DataBaseName varchar(100) = 'NorthWind'
Declare @FileID smallint = 1
Declare @PageId smallint = 552;

--Truncate Table [PowerBIInternals].[dbo].[IndexRecordData];

With PageRecords as
(
	Select *
	FROM [CheckDB].[dbo].[DBCC_Page_Records]
	WHERE DataBaseName = @DataBaseName
	AND FileID = @FileID
	AND PageId = @PageId
)
INSERT INTO [PowerBIInternals].[dbo].[IndexRecordData]
Select 
	pr.DatabaseName,
	pr.FileId,
	pr.PageId as PageNo,
	pr.SlotNo,
	SlotData.FieldNo,
	SlotData.FieldType,
	Case 
		WHEN SlotData.FieldNo = 1 THEN Cast(pr.DatabaseName as varchar(Max))
		WHEN SlotData.FieldNo = 2 THEN Cast(pr.FileId as varchar(10))
		WHEN SlotData.FieldNo = 3 THEN Cast(pr.PageId as varchar(10))
		WHEN SlotData.FieldNo = 4 THEN Cast(pr.SlotNo as varchar(10))
		WHEN SlotData.FieldNo = 5 THEN Cast(pr.TagA as varchar(10))
		WHEN SlotData.FieldNo = 6 THEN ''''+ Left(Cast(pr.FixedLenData as varchar(1000)), 8) + ''''
		WHEN SlotData.FieldNo = 7 THEN '''' + Cast(pr.NoColsHex as varchar(10)) + ''''
		WHEN SlotData.FieldNo = 8 THEN '''' + IsNull(pr.NullBitMapHex, '') + ''''
		WHEN SlotData.FieldNo = 9 THEN '''' + IsNull(pr.NoVarLenColsHex, '') + ''''
		WHEN SlotData.FieldNo = 10 THEN Left(pr.VarLenDataOffsetArray, 10)
		WHEN SlotData.FieldNo = 11 THEN Left(pr.VarLenData, 10)
		WHEN SlotData.FieldNo = 12 THEN IsNull(pr.VersioningTag, '')
		WHEN SlotData.FieldNo = 13 THEN Left(pr.RawRecord, 110)
		ELSE ''
	END as FieldValue
FROM PageRecords pr
CROSS APPLY 
(
	Select 1 as FieldNo, 'Database' as FieldType
	UNION ALL
	Select 2 as FieldNo, 'FileId' as FieldType
	UNION ALL
	Select 3 as FieldNo, 'PageId' as FieldType
	UNION ALL
	Select 4 as FieldNo, 'SlotId' as FieldType
	UNION ALL
	Select 5 as FieldNo, 'TagA' as FieldType
	UNION ALL
	Select 6 as FieldNo, 'FData' as FieldType
	UNION ALL
	Select 7 as FieldNo, 'Ncol' as FieldType
	UNION ALL
	Select 8 as FieldNo, 'Nullbits' as FieldType
	UNION ALL
	Select 9 as FieldNo, 'Varcount' as FieldType
	UNION ALL
	Select 10 as FieldNo, 'Varoffset' as FieldType
	UNION ALL
	Select 11 as FieldNo, 'Vardata' as FieldType
	UNION ALL
	Select 12 as FieldNo, 'VersionTag' as FieldType
	UNION ALL
	Select 13 as FieldNo, 'RawRecord' as FieldType
) SlotData;


Select * from [PowerBIInternals].[dbo].[IndexRecordData];
Use PowerBIInternals
GO

Declare @DataBaseName varchar(100) = 'NorthWind'
Declare @FileID smallint = 1
Declare @PageId smallint = 760

Declare @SlotCount smallint
Declare @FreeCnt smallint
Declare @FreeData smallint
Declare @SlotData varchar(120)

TRUNCATE TABLE dbo.PageStructureData

SELECT @SlotCount = Value
from [CheckDB].dbo.PageHeaderInfo pdi
WHERE DataBaseName = @DataBaseName
AND FileID = @FileID
AND PageId = @PageId
AND Field = 'm_slotCnt'

SELECT @FreeCnt = Value
from [CheckDB].dbo.PageHeaderInfo pdi
WHERE DataBaseName = @DataBaseName
AND FileID = @FileID
AND PageId = @PageId
AND Field = 'm_freeCnt'

SELECT @FreeData = Value
from [CheckDB].dbo.PageHeaderInfo pdi
WHERE DataBaseName = @DataBaseName
AND FileID = @FileID
AND PageId = @PageId
AND Field = 'm_freeData'

Select 
	@SlotData = Right([PageDataHex], @SlotCount*4)
from [CheckDB].dbo.PageDataInfo pdi
WHERE DataBaseName = @DataBaseName
AND FileID = @FileID
AND PageId = @PageId


INSERT INTO [dbo].[PageStructureData]
Select 
	pdi.DatabaseName,
	pdi.FileID,
	pdi.PageId as PageNo,
	-1 as SlotNo,
	'PageHeader' as Description,
	[PageHeaderHex] as RawRecord,
	Left([PageHeaderHex], 80) as DisplayRecord
from [CheckDB].dbo.PageDataInfo pdi
WHERE DataBaseName = @DataBaseName
AND FileID = @FileID
AND PageId = @PageId
UNION ALL
Select 
	pdi.DatabaseName,
	pdi.FileID,
	pdi.PageId as PageNo,
	pdi.SlotNo,
	'DataRow' + Cast(ROW_NUMBER() OVER(ORDER BY STARTPOS) as varchar(4)) as Description,
	pdi.RawRecord,
	'Slot ' + Cast(pdi.SlotNo as varchar(4)) + ': ' + Left(pdi.RawRecord, 70) as DisplayRecord
FROM [CheckDB].[dbo].[DBCC_Page_Records] pdi
WHERE DataBaseName = @DataBaseName
AND FileID = @FileID
AND PageId = @PageId
UNION ALL
Select 
	pdi.DatabaseName,
	pdi.FileID,
	pdi.PageId as PageNo,
	-2 as SlotNo,
	'FreeSpace' as Description,
	Substring([PageDataHex], @FreeData*2 + 1, @FreeCnt*2) as RawRecord,
	'Free Space: ' + Cast(@FreeCnt as varchar(10)) + ' Bytes' as DisplayRecord
from [CheckDB].dbo.PageDataInfo pdi
WHERE DataBaseName = @DataBaseName
AND FileID = @FileID
AND PageId = @PageId
UNION ALL
SELECT 
	@DataBaseName as DataBaseName,
	@FileID as FileID,
	@PageId as PageId,
	N-1 as SlotNo,
	'Slot' + Cast(N-1 as varchar(2)) as Description,
	SUBSTRING(@SlotData,(@SlotCount-N)*4+1,4) as RawRecord,
	'''' + SUBSTRING(@SlotData,(@SlotCount-N)*4+1,4) + '''' as DisplayRecord
FROM CheckDB.[dbo].[Numbers]
WHERE N <= @SlotCount;

-- PageRecordData
Truncate Table [PowerBIInternals].[dbo].[PageRecordData];

With PageRecords as
(
	Select *
	FROM [CheckDB].[dbo].[DBCC_Page_Records]
	WHERE DataBaseName = @DataBaseName
	AND FileID = @FileID
	AND PageId = @PageId
)
INSERT INTO [PowerBIInternals].[dbo].[PageRecordData]
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
		WHEN SlotData.FieldNo = 6 THEN ''''+ Cast(pr.TagB as varchar(10)) + ''''
		WHEN SlotData.FieldNo = 7 THEN Cast(pr.FSize as varchar(10))
		WHEN SlotData.FieldNo = 8 THEN Left(Cast(pr.FixedLenData as varchar(1000)), 8) 
		WHEN SlotData.FieldNo = 9 THEN Cast(pr.NoColsHex as varchar(10))
		WHEN SlotData.FieldNo = 10 THEN '''' + pr.NullBitMapHex + ''''
		WHEN SlotData.FieldNo = 11 THEN '''' + pr.NoVarLenColsHex + ''''
		WHEN SlotData.FieldNo = 12 THEN Left(pr.VarLenDataOffsetArray, 10)
		WHEN SlotData.FieldNo = 13 THEN Left(pr.VarLenData, 10)
		WHEN SlotData.FieldNo = 14 THEN IsNull(pr.VersioningTag, '')
		WHEN SlotData.FieldNo = 15 THEN Left(pr.RawRecord, 110)
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
	Select 6 as FieldNo, 'TagB' as FieldType
	UNION ALL
	Select 7 as FieldNo, 'Fsize' as FieldType
	UNION ALL
	Select 8 as FieldNo, 'FData' as FieldType
	UNION ALL
	Select 9 as FieldNo, 'Ncol' as FieldType
	UNION ALL
	Select 10 as FieldNo, 'Nullbits' as FieldType
	UNION ALL
	Select 11 as FieldNo, 'Varcount' as FieldType
	UNION ALL
	Select 12 as FieldNo, 'Varoffset' as FieldType
	UNION ALL
	Select 13 as FieldNo, 'Vardata' as FieldType
	UNION ALL
	Select 14 as FieldNo, 'VersionTag' as FieldType
	UNION ALL
	Select 15 as FieldNo, 'RawRecord' as FieldType
) SlotData;

-- Reverse Engineer
Use Northwind
GO

TRUNCATE TABLE [PowerBIInternals].dbo.Region
TRUNCATE TABLE [PowerBIInternals].dbo.ColumnInfo
TRUNCATE TABLE [PowerBIInternals].dbo.Region_ReverseEntry

INSERT INTO [PowerBIInternals].dbo.Region([RegionID], [RegionDescription])
Select [RegionID], [RegionDescription]
from [dbo].[Region]

INSERT INTO [PowerBIInternals].dbo.ColumnInfo([SchemaName], [TableName], [object_id], [partition_column_id], [ColumnName], [system_type_id], [DataType], [max_length], [precision], [scale], [leaf_offset])
Select 
	Schema_Name(o.schema_id) as SchemaName,
	o.name as TableName,
	o.object_id,
	ipc.partition_column_id,
	c.name as ColumnName,
	ipc.system_type_id,
	t.name as DataType,
	ipc.max_length,
	ipc.precision,
	ipc.scale,
	leaf_offset
from sys.system_internals_partition_columns ipc
INNER JOIN sys.partitions p
	ON p.partition_id = ipc.partition_id
INNER JOIN sys.objects o
	ON p.object_id = o.object_id
INNER JOIN sys.columns c
	ON c.object_id = o.object_id
	AND c.column_id = ipc.partition_column_id
INNER JOIN sys.types t
	on t.system_type_id = c.system_type_id
WHERE o.name = 'Region'
and p.index_id = 0

INSERT into [PowerBIInternals].dbo.Region_ReverseEntry([SlotNo], [FixedLenData], [RegionID], [RegionDescription])
Select SlotNo,
	FixedLenData, 
	RegionID.FieldValue as RegionID,
	RegionDescription.FieldValue as RegionDescription
from [CheckDB].dbo.DBCC_Page_Records
CROSS APPLY [CheckDB].[dbo].[HexString2Data](Left(FixedLenData, 8), 56, 4, 10) RegionID
CROSS APPLY [CheckDB].[dbo].[HexString2Data](Substring(FixedLenData, 9, 100), 239, 0, 0) RegionDescription
WHERE DatabaseName = 'NorthWind'
AND PageId = 544
ORDER BY PageId, SlotNo


/****** Script for SelectTopNRows command from SSMS  ******/
/*

*/

Declare @PageId int = 188;

With Data as
(
	Select 
		DatabaseName,
		FileId,
		PageId as PageNo,
		1 as FieldNo,
		'PageHeader' as FieldType,
		PageHeaderHex as FieldValue
	FROM [CheckDB].[dbo].[PageDataInfo]
	WHERE PageId = @PageId
	UNION ALL
	Select 
		DatabaseName,
		FileId,
		PageId as PageNo,
		2 as FieldNo,
		'AllocationBitMap' as FieldType,
		Substring(PageDataHex,190*2 + 1, (8182-190)*2) as FieldValue
	FROM [CheckDB].[dbo].[PageDataInfo]
	WHERE PageId = @PageId
	UNION ALL
	Select 
		DatabaseName,
		FileId,
		PageId as PageNo,
		3 as FieldNo,
		'Slot0' as FieldType,
		Right(PageDataHex, 4) as FieldValue
	FROM [CheckDB].[dbo].[PageDataInfo]
	WHERE PageId = @PageId	
	UNION ALL
	Select 
		DatabaseName,
		FileId,
		PageId as PageNo,
		4 as FieldNo,
		'Slot1' as FieldType,
		Left(Right(PageDataHex, 8), 4) as FieldValue
	FROM [CheckDB].[dbo].[PageDataInfo]
	WHERE PageId = @PageId
)
INSERT INTO [dbo].[AllocationPageStructureData](DatabaseName, FileId, PageNo, FieldNo, FieldType, FieldValue)
Select DatabaseName, FileId, PageNo, FieldNo, FieldType, Left(FieldValue, 100) as FieldValue
FROM Data

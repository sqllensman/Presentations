/****** Script for SelectTopNRows command from SSMS  ******/
/*
12
13
15
18
21
22
33
35
39
45
49
55
76
81
83
84
88
92
96
98
100
102
104
106
108
114
117
123
125
129
130
131
134
137
141
142
144
145
146
147
150
152
154
156
157
162
166
187
188
189
190
200
206
208
210
211
212
213
244
246
301
303
305
307



*/

Declare @PageId int = 307;

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



SELECT [DBName]
      ,[FileId]
      ,[PageId]
      ,[m_pageId]
      ,[m_type]
      ,[Page_Type]
      ,[Page_Description]
      ,[m_flagBits]
      ,[m_objId (AllocUnitId.idObj)]
      ,[m_indexId (AllocUnitId.idInd)]
      ,[Metadata: AllocUnitId]
      ,[Metadata: PartitionId]
      ,[allocation_unit_id]
      ,[object_id]
      ,[Schema_Name]
      ,[object_name]
      ,[index_id]
      ,[Index_Name]
      ,[Index_Type]
      ,[partition_number]
      ,[Object_Type]
      ,[Allocation_Unit_Type]
      ,[m_prevPage]
      ,[m_nextPage]
      ,[pminlen]
      ,[m_slotCnt]
      ,[m_freeCnt]
      ,[m_freeData]
      ,[m_lsn]
      ,[m_ghostRecCnt]
      ,[m_headerVersion]
      ,[m_level]
      ,[m_tornBits]
      ,[Allocation_GAM_Page]
      ,[Allocation_GAM_Status]
      ,[Allocation_SGAM_Page]
      ,[Allocation_SGAM_Status]
      ,[Allocation_PFS_Page]
      ,[Allocation_PFS_Status]
      ,[Allocation_DIFF_Page]
      ,[Allocation_DIFF_Status]
      ,[Allocation_ML_Page]
      ,[Allocation_ML_Status]
      ,[total_pages]
      ,[used_pages]
      ,[data_pages]
      ,[rows]
      ,[is_disabled]
  FROM [PowerBIInternals].[dbo].[PageData]
  WHERE m_type IN (8, 9, 10, 16, 17)
  ORDER BY PageId
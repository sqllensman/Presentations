Select name from Northwind.sys.objects
WHERE object_id = 757577737;

--Select 
--sys.dm_db_database_page_allocations(12,69,1,NULL,'DETAILED')
Declare @ObjectId bigint =  757577737;
Declare @IndexId smallint = 1;


With ObjectData as
(
SELECT pd.[DBName]
      ,pd.[FileId]
      ,pd.[object_id]
      ,pd.[Schema_Name]
      ,pd.[object_name]
      ,pd.[index_id]
      ,pd.[Index_Name]
      ,pd.[Index_Type]
	  ,Count(*) as Pages
FROM [CheckDB].[dbo].[PageData] pd
where pd.[object_id] IS NOT NULL
GROUP BY 
       pd.[DBName]
      ,pd.[FileId]
      ,pd.[object_id]
      ,pd.[Schema_Name]
      ,pd.[object_name]
      ,pd.[index_id]
      ,pd.[Index_Name]
      ,pd.[Index_Type]
      ,pd.[partition_number]
)
Select 
	pd.[Schema_Name], pd.[object_name], pd.[index_id], pd.[Index_Name], dpa.page_type, dpa.page_type_desc, dpa.allocated_page_page_id, dpa.allocated_page_iam_page_id,
	dpa.previous_page_page_id, dpa.next_page_page_id, dpa.extent_page_id, dpa.extent_page_id/8 + 1 as ExtentNo, dpa.is_mixed_page_allocation
INTO #AllocationData
FROM ObjectData pd
CROSS APPLY sys.dm_db_database_page_allocations(DB_ID(pd.DBName),pd.[object_id],pd.[index_id],NULL,'DETAILED') dpa
WHERE pd.[object_id] = @ObjectId;


--With SummaryData(PageType, PageTypeDesc, IndexId) as
--(
--	Select IsNull(page_type, 0), IsNull(page_type_desc, 'UNALLOCATED'), index_id
--	from #AllocationData
--)
--Select PageType, PageTypeDesc, IndexId, Count(*) as NoPages
--FROM SummaryData
--GROUP BY PageType, PageTypeDesc, IndexId
--ORDER BY IndexId, PageType;

--Select [Schema_Name] + '.' + object_name as Object, index_id, Index_Name, Count(*) as Pages
--from #AllocationData
--GROUP BY [Schema_Name] + '.' + object_name, index_id, Index_Name;

TRUNCATE TABLE [PowerBIInternals].dbo.BtreeStructure;

With DataPages(index_id, page_id, iam_page_id, previous_page_page_id, next_page_page_id, extent_page_id, ExtentNo, is_mixed_page_allocation, page_type, page_type_desc, level)
as
(
	Select index_id, allocated_page_page_id, allocated_page_iam_page_id, previous_page_page_id, next_page_page_id, extent_page_id, ExtentNo, is_mixed_page_allocation, page_type, page_type_desc, 2
	FROM #AllocationData
	WHERE page_type_desc IN ('DATA_PAGE', 'INDEX_PAGE')
	AND index_id = @IndexId
	AND previous_page_page_id IS NULL
	AND page_type = 1
	UNION ALL
	Select ad.index_id, ad.allocated_page_page_id, ad.allocated_page_iam_page_id, ad.previous_page_page_id, ad.next_page_page_id, ad.extent_page_id, ad.ExtentNo, ad.is_mixed_page_allocation, ad.page_type, ad.page_type_desc, DataPages.[level]+1
	FROM #AllocationData ad
	INNER JOIN DataPages 
		ON DataPages.page_id = ad.previous_page_page_id
	WHERE ad.page_type_desc IN ('DATA_PAGE', 'INDEX_PAGE')
	AND ad.index_id = @IndexId
	AND ad.page_type = 1
),
IAMPages(index_id, page_id, iam_page_id, previous_page_page_id, next_page_page_id, extent_page_id, ExtentNo, is_mixed_page_allocation, page_type, page_type_desc, level)
as
(
	Select index_id, allocated_page_page_id , allocated_page_iam_page_id, previous_page_page_id, next_page_page_id, extent_page_id, ExtentNo, is_mixed_page_allocation, page_type, page_type_desc, 0
	FROM #AllocationData ad
	WHERE index_id = @IndexId
	AND page_type = 10
),
IndexPages(index_id, page_id, iam_page_id, previous_page_page_id, next_page_page_id, extent_page_id, ExtentNo, is_mixed_page_allocation, page_type, page_type_desc, level)
as
(
	Select index_id, allocated_page_page_id , allocated_page_iam_page_id, previous_page_page_id, next_page_page_id, extent_page_id, ExtentNo, is_mixed_page_allocation, page_type, page_type_desc, 1
	FROM #AllocationData
	WHERE index_id = @IndexId
	AND page_type_desc IN ('INDEX_PAGE')
	AND page_type = 2
) 
INSERT INTO [PowerBIInternals].dbo.BtreeStructure
Select * 
FROM
(
	Select index_id, page_id, iam_page_id, previous_page_page_id, next_page_page_id, extent_page_id, ExtentNo, is_mixed_page_allocation, page_type, page_type_desc, level
	FROM DataPages
	UNION ALL
	Select index_id, page_id, iam_page_id, previous_page_page_id, next_page_page_id, extent_page_id, ExtentNo, is_mixed_page_allocation, page_type, page_type_desc, level
	FROM IAMPages
	UNION ALL
	Select index_id, page_id, iam_page_id, previous_page_page_id, next_page_page_id, extent_page_id, ExtentNo, is_mixed_page_allocation, page_type, page_type_desc, level
	FROM IndexPages
) bTree


Drop Table #AllocationData
Use AdventureWorks2014

Declare @DatabaseName NVARCHAR(128) = DB_Name()

-- No of Pages in Database
SELECT
	file_id,
	size AS NoPages
FROM sys.master_files
where type = 0
AND database_id = DB_ID(@DatabaseName)

Select
	@DatabaseName,
	DB_ID() as Database_Id,
	o.object_id,
	o.schema_id,
	i.index_id,
	pages.allocation_unit_id,
	sp.partition_id,
	-- hobt_id, container_id & rowset_id = partition_id
	--sp.hobt_id,
	--au.container_id, 
	--pages.rowset_id,
	sp.partition_number,
	au.filegroup_id,
	sp.filestream_filegroup_id,
	SCHEMA_NAME(o.schema_id) as SchemaName,
	o.name as ObjectName,
	o.type_desc as ObjectDescription,
	i.name as IndexName,
	i.type_desc as IndexDescription,
	o.is_ms_shipped,
	i.type,
	i.is_unique,
	i.is_unique_constraint,
	i.has_filter,
	pages.allocation_unit_type,
	pages.allocation_unit_type_desc,
	pages.allocated_page_file_id,
	pages.allocated_page_page_id,
	pages.extent_file_id,
	pages.extent_page_id,
	pages.allocated_page_iam_file_id,
	pages.allocated_page_iam_page_id,
	pages.is_allocated,
	pages.is_mixed_page_allocation,
	pages.is_iam_page,
	pages.page_type,
	pages.page_type_desc,
	pages.page_level,
	pages.next_page_file_id,
	pages.next_page_page_id,
	pages.previous_page_file_id,
	pages.previous_page_page_id,
	pages.is_page_compressed,
	pages.has_ghost_records,
	sp.rows,
	sp.data_compression,
	sp.data_compression_desc,
	au.total_pages,
	au.used_pages,
	'(' + CONVERT (VARCHAR (6),
		CONVERT (INT,
			SUBSTRING (au.[first_page], 6, 1) +
			SUBSTRING (au.[first_page], 5, 1))) +
	':' + CONVERT (VARCHAR (20),
		CONVERT (INT,
			SUBSTRING (au.[first_page], 4, 1) +
			SUBSTRING (au.[first_page], 3, 1) +
			SUBSTRING (au.[first_page], 2, 1) +
			SUBSTRING (au.[first_page], 1, 1))) +
	')' AS [First_Page],
	'(' + CONVERT (VARCHAR (6),
		CONVERT (INT,
			SUBSTRING (au.[root_page], 6, 1) +
			SUBSTRING (au.[root_page], 5, 1))) +
	':' + CONVERT (VARCHAR (20),
		CONVERT (INT,
			SUBSTRING (au.[root_page], 4, 1) +
			SUBSTRING (au.[root_page], 3, 1) +
			SUBSTRING (au.[root_page], 2, 1) +
			SUBSTRING (au.[root_page], 1, 1))) +
	')' AS [Root_Page],
	'(' + CONVERT (VARCHAR (6),
		CONVERT (INT,
			SUBSTRING (au.[first_iam_page], 6, 1) +
			SUBSTRING (au.[first_iam_page], 5, 1))) +
	':' + CONVERT (VARCHAR (20),
		CONVERT (INT,
			SUBSTRING (au.[first_iam_page], 4, 1) +
			SUBSTRING (au.[first_iam_page], 3, 1) +
			SUBSTRING (au.[first_iam_page], 2, 1) +
			SUBSTRING (au.[first_iam_page], 1, 1))) +
	')' AS [First_IAM_Page]
FROM sys.dm_db_database_page_allocations(db_id(@DatabaseName),NULL,NULL,NULL,'DETAILED') pages
INNER Join sys.system_internals_allocation_units au
	on au.allocation_unit_id = pages.allocation_unit_id
INNER JOIN sys.partitions AS [sp]
	ON [au].[container_id] = [sp].[partition_id]
INNER Join sys.objects o
	ON o.object_id = pages.object_id
Left Join sys.indexes i
	ON i.object_id = pages.object_id
	AND i.index_id = pages.index_id
--Where pages.rowset_id <> pages.allocation_unit_id
order by pages.allocated_page_page_id
--24325

/*
hobt_id	container_id	partition_id	rowset_id
281474980511744	281474980511744	281474980511744	281474980511744

	sp.hobt_id,
	au.container_id,
	sp.partition_id,
	pages.rowset_id,
--Select * 
--FROM sys.system_internals_partition_columns

*/

USE [CheckDB]
GO

/*
-- Insert data into dbo.PageData
DECLARE @RC int
DECLARE @DatabaseName nvarchar(128) = N'AdventureWorks2014'

EXECUTE @RC = [dbo].[Get_DatabasePageData] 
   @DatabaseName
*/ 

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
  FROM [CheckDB].[dbo].[PageData]
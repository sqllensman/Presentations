USE master
GO

EXECUTE CheckDB.[dbo].[Get_DatabasePageData] 
   @DatabaseName='AdventureWorksDW2014'
GO

EXECUTE CheckDB.[dbo].[prc_ReadPageData]
	   @DatabaseName = 'AdventureWorksDW2014'
	  ,@FileId = 1
	  ,@PageId = 16416

Select * FROM msdb.dbo.suspect_pages

Select 
	susp.database_id,
	DB_NAME(susp.database_id) DatabaseName,
	OBJECT_SCHEMA_NAME(ind.object_id, ind.database_id) ObjectSchemaName,
	OBJECT_NAME(ind.object_id, ind.database_id) ObjectName,
	*
FROM msdb.dbo.suspect_pages susp
CROSS APPLY sys.dm_db_database_page_allocations(susp.database_id, null, null, null, null) ind
WHERE allocated_page_file_id = susp.file_id
AND allocated_page_page_id = susp.page_id
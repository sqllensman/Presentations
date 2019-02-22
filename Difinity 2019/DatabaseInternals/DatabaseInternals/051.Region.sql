Select 
	SCHEMA_NAME(Schema_Id),
	Name,
	object_id
FROM Northwind.sys.tables


Select 
	[RegionID], 
	[RegionDescription], 
	sys.fn_PhysLocFormatter(%%physloc%%) as [Physical RID],
	file_id, 
	page_id, 
	slot_id
from Northwind.dbo.Region
CROSS APPLY sys.fn_PhysLocCracker(%%physloc%%)

Select 
	DBName,	
	FileId,	
	PageId,
	m_type,	
	object_id,	
	Schema_Name,	
	object_name,	
	index_id,	
	Index_Name,	
	Index_Type,	
	Allocation_GAM_Page,	
	Allocation_GAM_Status,	
	Allocation_SGAM_Page,	
	Allocation_SGAM_Status,	
	Allocation_PFS_Page,	
	Allocation_PFS_Status,
	[total_pages],
	[used_pages],
	[data_pages],
	rows 
from [PowerBIInternals].[dbo].[PageData]
WHERE object_id = 1621580815


Select 
	DBName,	
	FileId,	
	PageId,	
	m_type,
	object_id,	
	Schema_Name,	
	object_name,	
	index_id,	
	Index_Name,	
	Index_Type,	
	Allocation_GAM_Page,	
	Allocation_GAM_Status,	
	Allocation_SGAM_Page,	
	Allocation_SGAM_Status,	
	Allocation_PFS_Page,	
	Allocation_PFS_Status,
	rows 
from [PowerBIInternals].[dbo].[PageData]
WHERE PageId = 760


Select 
	[RegionID], 
	[RegionDescription], 
	sys.fn_PhysLocFormatter(%%physloc%%) as [Physical RID],
	file_id, 
	page_id, 
	slot_id
from Northwind.dbo.Region
CROSS APPLY sys.fn_PhysLocCracker(%%physloc%%)

SELECT f.*,
ROW_NUMBER() OVER(ORDER BY file_id, page_id, slot_id) AS Row
FROM flag f 
CROSS APPLY sys.fn_PhysLocCracker(%%physloc%%)
ORDER BY Row


DBCC TRACEON(3604)
DBCC PAGE('Northwind', 1,760,1) WITH TABLERESULTS
DBCC PAGE('Northwind', 1,760,3) WITH TABLERESULTS
DBCC PAGE('Northwind', 1,760,2) WITH TABLERESULTS

Exec CheckDB.[dbo].[prc_ReadPageData] 'Northwind', 1,760
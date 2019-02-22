-- Clustered v Non Clustered Index
USE [Northwind]
GO


Select *
from [dbo].[RegionCopy]

Select [RegionID], [RegionDescription], sys.fn_PhysLocFormatter(%%physloc%%) as [Physical RID]
from [dbo].[RegionCopy]

Exec CheckDB.[dbo].[prc_ReadPageData] 'Northwind', 1,544

Select [RegionID], [RegionDescription], sys.fn_PhysLocFormatter(%%physloc%%) as [Physical RID]
from [dbo].[RegionCopy] WITH(INDEX(2))







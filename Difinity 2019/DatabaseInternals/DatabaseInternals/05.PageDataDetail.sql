USE [CheckDB]
GO

/*

Delete FROM dbo.PageHeaderInfo WHERE DatabaseName = 'NorthWind'
Delete FROM dbo.PageDataInfo WHERE DatabaseName = 'NorthWind'
Delete FROM dbo.DBCC_Page_Records WHERE DatabaseName = 'NorthWind'

*/

DECLARE @RC int
DECLARE @DatabaseName nvarchar(128) = N'NorthWind'

EXECUTE @RC = [dbo].[Get_DatabasePageDataDetail] 
   @DatabaseName
GO


Select * from dbo.PageHeaderInfo
WHERE DatabaseName = 'NorthWind'
ORDER BY PageId

Select * from dbo.PageDataInfo
WHERE DatabaseName = 'NorthWind'
ORDER BY PageId

Select * from dbo.DBCC_Page_Records
WHERE DatabaseName = 'NorthWind'
AND PageId = 544
ORDER BY PageId, SlotNo


DBCC PAGE('NorthWind', 1, 544, 2) WITH TABLERESULTS



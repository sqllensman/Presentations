/*

Notes

Requires a copy of AdventureWorksDW2014

*/

USE [CheckDB]
GO

EXECUTE  CheckDB.[dbo].[Get_DBCCInd] 
   @DatabaseName = 'AdventureWorksDW2014'
  ,@TableName = '[dbo].[FactInternetSales]'
  ,@IndexId = -1

/*
http://www.sqlskills.com/blogs/paul/dbcc-writepage/




dbcc WRITEPAGE ({'dbname' | dbid}, fileid, pageid, offset, length, data [, directORbufferpool])
 

The parameters mean:
•‘dbname’ | dbid : self-explanatory
•fileid : file ID containing the page to change
•pageid : zero-based page number within that file
•offset : zero-based offset in bytes from the start of the page
•length : number of bytes to change, from 1 to 8
•data : the new data to insert (in hex, in the form ‘0xAABBCC’ – example three-byte string)
•directORbufferpool : whether to bypass the buffer pool or not (0/1)



*/  


DBCC WritePage(AdventureWorksDW2014, 1, 18453, 12, 3, 0x616161);
DBCC WritePage(AdventureWorksDW2014, 1, 18453, 198, 4, 0x20202020,0);
DBCC WritePage(AdventureWorksDW2014, 1, 18459, 16, 4, 0x61626162);
DBCC WritePage(AdventureWorksDW2014, 1, 18460, 12, 4, 0x61626162);
DBCC WritePage(AdventureWorksDW2014, 1, 18460, 16, 4, 0x61626162);




USE AdventureWorksDW2014
GO
-- Check Status
EXECUTE CheckDB.[dbo].[CheckDB_Extended] 
   @DatabaseName = 'AdventureWorksDW2014'

--Can Use REPAIR_REBUILD option 
--ALTER DATABASE  AdventureWorksDW2014 SET SINGLE_USER WITH ROLLBACK IMMEDIATE  
--DBCC CHECKDB('AdventureWorksDW2014', REPAIR_REBUILD)
--Requires SINGLE_USER mode so will create outage
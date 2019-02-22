Use PowerBIInternals
GO

-- Forwarding Pointers
-- https://www.sqlskills.com/blogs/paul/forwarding-and-forwarded-records-and-the-back-pointer-size/


Use PowerBIInternals;

CREATE TABLE DbccPageTest (intCol1  INT IDENTITY,  intCol2  INT, vcharCol VARCHAR (8000),  lobCol  VARCHAR (MAX));
GO 
INSERT INTO DbccPageTest VALUES (1, REPLICATE ('Row1', 600), REPLICATE ('Row1Lobs', 1000));
INSERT INTO DbccPageTest VALUES (2, REPLICATE ('Row2', 600), REPLICATE ('Row2Lobs', 1000));
GO


DBCC IND ('PowerBIInternals', 'DbccPageTest', -1)


SELECT [intCol1], [intCol2], [vcharCol], [lobCol], Len(vcharCol)
FROM [dbo].[DbccPageTest] as t
CROSS APPLY sys.fn_PhysLocCracker(t.%%physloc%%) fplc


Select * 
FROM  sys.dm_db_database_page_allocations(DB_ID(), OBJECT_ID('dbo.DbccPageTest'), NULL, NULL, 'DETAILED')
WHERE is_allocated = 1


EXECUTE CheckDB.[dbo].[prc_ReadPageData] @DatabaseName = N'PowerBIInternals', @FileId = 1, @PageId = 328

EXECUTE CheckDB.[dbo].[Get_IndexStructure] 'PowerBIInternals', 'dbo.DbccPageTest', 0

Select SlotNo , Substring(VarLenData, 1, 2400*2), SubString([VarLenData], 4801, 100), Len(SubString([VarLenData], 4801, 100))/2
from CheckDB.[dbo].[DBCC_Page_Records]
WHERE PageId = 328




UPDATE DbccPageTest SET vcharCol = REPLICATE ('LongRow2', 1000) WHERE intCol2 = 2;
GO

/*
Forwarding Pointer

2 bytes for the special column ID (1024) at the start of the back-pointer signifying that this is a back-pointer 
8 bytes for the record location (2-byte file ID, 4-byte page-in-file, 2-byte slot ID)

*/

DBCC PAGE('PowerBIInternals', 1,8424,3) WITH TABLERESULTS

--
EXECUTE CheckDB.[dbo].[prc_ReadPageData] @DatabaseName = N'PowerBIInternals', @FileId = 1, @PageId = 8424


-- Cleanup

DROP TABLE [dbo].[DbccPageTest]



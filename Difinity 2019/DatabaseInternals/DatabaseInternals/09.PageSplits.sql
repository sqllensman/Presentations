
USE PowerBIInternals
GO
 
CREATE TABLE [dbo].[TestTable]
(
    [id] [int] IDENTITY(1,1) NOT NULL,
    [FirstName] [NVARCHAR](3500) NOT NULL,
     CONSTRAINT [PK_Customers] PRIMARY KEY CLUSTERED ([id] ASC)
);



DBCC TRACEON(3604,-1)
DBCC IND(PowerBIInternals, 'TestTable', 1);
 
 
INSERT INTO [dbo].[TestTable] ([FirstName])
     VALUES (REPLICATE('X', 3500));
GO
 
-- 
DBCC IND(PowerBIInternals, 'TestTable', 1);

SELECT * 
FROM [dbo].[TestTable] as t
CROSS APPLY sys.fn_PhysLocCracker(t.%%physloc%%) fplc

-- insert a second row
INSERT INTO [dbo].[TestTable] ([FirstName])
     VALUES (REPLICATE('Y', 3500));


Select * 
FROM  sys.dm_db_database_page_allocations(DB_ID(), OBJECT_ID('dbo.TestTable'), 1, NULL, 'DETAILED')
WHERE is_allocated = 1

-- Insert a small row
INSERT INTO [dbo].[TestTable] ([FirstName])
     VALUES (REPLICATE('a', 25));


Select * 
FROM  sys.dm_db_database_page_allocations(DB_ID(), OBJECT_ID('dbo.TestTable'), 1, NULL, 'DETAILED')
WHERE is_allocated = 1


SELECT * 
FROM [dbo].[TestTable] as t
CROSS APPLY sys.fn_PhysLocCracker(t.%%physloc%%) fplc

-- Insert a more rows
INSERT INTO [dbo].[TestTable] ([FirstName])
     VALUES (REPLICATE('b', 25));
INSERT INTO [dbo].[TestTable] ([FirstName])
     VALUES (REPLICATE('c', 25));
INSERT INTO [dbo].[TestTable] ([FirstName])
     VALUES (REPLICATE('d', 25));
INSERT INTO [dbo].[TestTable] ([FirstName])
     VALUES (REPLICATE('e', 25));

SELECT * 
FROM [dbo].[TestTable] as t
CROSS APPLY sys.fn_PhysLocCracker(t.%%physloc%%) fplc


-- Update Record to cause page split
UPDATE [dbo].[TestTable]
   SET [FirstName] = REPLICATE('c', 3500)
   WHERE id = 5;

SELECT * 
FROM [dbo].[TestTable] as t
CROSS APPLY sys.fn_PhysLocCracker(t.%%physloc%%) fplc


SELECT * FROM sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID('dbo.TestTable'), NULL, NULL , 'DETAILED')

DROP TABLE [dbo].[TestTable]



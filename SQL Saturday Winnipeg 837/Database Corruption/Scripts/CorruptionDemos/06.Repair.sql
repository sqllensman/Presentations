USE master
GO

DBCC CHECKDB([AdventureWorksDW2014]) WITH ALL_ERRORMSGS, NO_INFOMSGS

ALTER DATABASE [AdventureWorksDW2014] SET SINGLE_USER WITH ROLLBACK IMMEDIATE

DBCC CHECKDB([AdventureWorksDW2014],REPAIR_REBUILD) WITH ALL_ERRORMSGS, NO_INFOMSGS

DBCC CHECKDB([AdventureWorksDW2014],REPAIR_ALLOW_DATA_LOSS) WITH ALL_ERRORMSGS, NO_INFOMSGS

ALTER DATABASE [AdventureWorksDW2014] SET MULTI_USER WITH ROLLBACK IMMEDIATE

Use PowerBIInternals
GO

-- Database
TRUNCATE TABLE [dbo].[InstanceInfo]

INSERT INTO [dbo].[InstanceInfo]([Id], [Parent], [Type], [Description], [AdditionalInfo])
select 
	Id = 0,
	Parent = NULL,
	Type = 'SQL Instance',
	Description = @@Servername COLLATE DATABASE_DEFAULT,
	AdditionalInfo = @@Version
UNION ALL
Select 
	Id = database_id,
	Parent = 0,
	Type = 'Database',
	Description = name COLLATE DATABASE_DEFAULT,
	AdditionalInfo = ''
from sys.databases d
where database_id = 24

/*

name	database_id
name	database_id
WideWorldImporters	5
WideWorldImportersDW	6
AdventureWorks2016	8
CheckDB	10
6Degrees	11
Northwind	12
pubs	13
PowerBIInternals	15
dbatools	18
Sandbox	24

*/

Use [msdb]
go

INSERT INTO [PowerBIInternals].[dbo].[InstanceInfo]([Id], [Parent], [Type], [Description], [AdditionalInfo])
Select [Id], [Parent], [Type], [Description], [AdditionalInfo] FROM
(
	select 
		id = (100000 * DB_ID()) + ds.data_space_id,
		Parent = DB_ID(), 
		Type = 'Data Space', 
		Description = ds.type_desc COLLATE DATABASE_DEFAULT,
		AdditionalInfo = ds.name COLLATE DATABASE_DEFAULT
	FROM sys.data_spaces ds
	UNION ALL
	Select
		id = 100000 * DB_ID(),
		Parent = DB_ID(), 
		Type = 'Data Space', 
		Description = 'LOG' COLLATE DATABASE_DEFAULT, 
		AdditionalInfo = 'TRANSACTION_LOG' COLLATE DATABASE_DEFAULT
) Level2;


With DataSpaces(database_id, id) as
(
	select 
		DB_ID() as database_id, 
		ds.data_space_id as id
	FROM sys.data_spaces ds
	UNION ALL
	Select
		DB_ID() as database_id, 
		0 as id
)
INSERT INTO [PowerBIInternals].[dbo].[InstanceInfo]([Id], [Parent], [Type], [Description], [AdditionalInfo])
Select Distinct [Id], [Parent], [Type], [Description], [AdditionalInfo] 
FROM
(
	Select 
		id = (10000000 * Cast(dbf.file_id as bigint)) + (100000 * DB_ID()) + ds.id,
		Parent = (100000 * DB_ID()) + ds.id,
		CASE ds.id
			WHEN 0 THEN 0
			ELSE 1
		END as Partition_Number,
		Type = 'Database File', 
		Description = dbf.name,
		AdditionalInfo = dbf.physical_name
	FROM DataSpaces ds
	INNER JOIN sys.database_files dbf
		ON dbf.data_space_id = ds.id 
	UNION ALL
	Select 
		id = (10000000 * Cast(dbf.file_id as bigint)) + (100000 * DB_ID()) + + ds.id,
		Parent = (100000 * DB_ID()) + ds.id,
		dds.destination_id as Partition_Number,
		Type = 'Database File', 
		Description = dbf.name,
		AdditionalInfo = dbf.physical_name
	FROM DataSpaces ds
	INNER JOIN sys.destination_data_spaces dds
		on ds.id = dds.partition_scheme_id
	INNER JOIN sys.database_files dbf
		ON dbf.data_space_id = dds.data_space_id
	INNER JOIN sys.partition_schemes as ps 
		ON dds.partition_scheme_id = ps.data_space_id
) Level3
Use Northwind
GO

declare @dbsize bigint
declare @logsize bigint
declare @database_size_mb float
declare @unallocated_space_mb float
declare @reserved_mb float
declare @data_mb float
declare @log_size_mb float
declare @index_mb float
declare @unused_mb float
declare @reservedpages bigint
declare @pages bigint
declare @usedpages bigint

declare @filestats_temp_table table(
	file_id int,
	file_group_id int,
    total_extents int,
    used_extents int,
    logical_file_name nvarchar(500) collate database_default,
    physical_file_name nvarchar(500) collate database_default
);

declare @tran_log_space_usage table
(
	database_name sysname,
    log_size_mb float,
    log_space_used float,
    status int
);

TRUNCATE TABLE [PowerBIInternals].dbo.FileStats
TRUNCATE TABLE [PowerBIInternals].dbo.LogSpaceUsage
TRUNCATE TABLE [PowerBIInternals].dbo.SpaceUsage

insert into @filestats_temp_table
exec ('DBCC SHOWFILESTATS');

INSERT INTO [PowerBIInternals].dbo.FileStats([l1], [file_group_name], [logical_file_name], [physical_file_name], [space_reserved], [space_reserved_unit], [space_used], [space_used_unit])
select  
	(row_number() over (order by t2.name))%2 as l1
	,t2.name as [file_group_name]
    ,t1.logical_file_name
    ,t1.physical_file_name
    ,cast(
		case 
			when (total_extents * 64) < 1024 then (total_extents * 64)
			when (total_extents * 64 / 1024.0) < 1024 then  (total_extents * 64 / 1024.0)
			else (total_extents * 64 / 1048576.0)
		end as decimal(10,2)
		) as space_reserved
    ,case 
		when (total_extents * 64) < 1024 then 'KB'
		when (total_extents * 64 / 1024.0) < 1024 then  'MB'
		else 'GB'
     end as space_reserved_unit
    ,cast(
		case 
			when (used_extents * 64) < 1024 then (used_extents * 64)
			when (used_extents * 64 / 1024.0) < 1024 then  (used_extents * 64 / 1024.0)
			else (used_extents * 64 / 1048576.0)
		end as decimal(10,2)
		) as space_used
    ,case 
		when (used_extents * 64) < 1024 then 'KB'
		when (used_extents * 64 / 1024.0) < 1024 then  'MB'
		else 'GB'
     end as space_used_unit
from @filestats_temp_table t1
inner join sys.data_spaces t2 
	on ( t1.file_group_id = t2.data_space_id );

insert into @tran_log_space_usage
exec('DBCC SQLPERF ( LOGSPACE )') ;


INSERT INTO [PowerBIInternals].dbo.LogSpaceUsage([l1], [l2], [LogSizeMB], [SpaceUsage], [UsageType])
Select *
FROM
(
	select 
		 1 as l1
		,1 as l2
		,log_size_mb as LogSizeMB
		,cast( convert(float,log_space_used) as decimal(10,1)) as SpaceUsage
		,'Used' as UsageType
	from @tran_log_space_usage
	where database_name = DB_NAME()
	UNION
	select 
		1 as l1
		,1 as l2
		,log_size_mb
		,cast(convert(float,(100-log_space_used)) as decimal(10,1)) as SpaceUsage
		,'Unused' as UsageType
	from @tran_log_space_usage
	where database_name = DB_NAME()
) a


select 
	 @dbsize = sum(convert(bigint,case when type = 0 then size else 0 end))
	,@logsize = sum(convert(bigint,case when type = 1 then size else 0 end))
from sys.database_files

select 
	 @reservedpages = sum(a.total_pages)
    ,@usedpages = sum(a.used_pages)
    ,@pages = sum
		(
		CASE
			WHEN it.internal_type IN (202,204) THEN 0
			WHEN a.type != 1 THEN a.used_pages
			WHEN p.index_id < 2 THEN a.data_pages
			ELSE 0
		END
		)
from sys.partitions p
INNER JOIN sys.allocation_units a 
	on p.partition_id = a.container_id
LEFT JOIN sys.internal_tables it 
	on p.object_id = it.object_id

select @database_size_mb = (convert(dec (19,2),@dbsize) + convert(dec(19,2),@logsize)) * 8192 / 1048576.0
select @unallocated_space_mb =
	(
		case
			when @dbsize >= @reservedpages then (convert (dec (19,2),@dbsize) - convert (dec (19,2),@reservedpages)) * 8192 / 1048576.0
			else 0
		end
	)

select  @reserved_mb = @reservedpages * 8192 / 1048576.0
select  @data_mb = @pages * 8192 / 1048576.0
select  @log_size_mb = convert(dec(19,2),@logsize) * 8192 / 1048576.0
select  @index_mb = (@usedpages - @pages) * 8192 / 1048576.0
select  @unused_mb = (@reservedpages - @usedpages) * 8192 / 1048576.0

INSERT INTO [PowerBIInternals].dbo.SpaceUsage([database_size_mb], [reserved_mb], [unallocated_space_mb], [data_size], [transaction_log_size], [unallocated], [reserved], [data], [index_1], [unused])
select
	 @database_size_mb as 'database_size_mb'
    ,@reserved_mb as 'reserved_mb'
    ,@unallocated_space_mb as 'unallocated_space_mb'
    ,(@reserved_mb + @unallocated_space_mb) as 'data_size'
    ,@log_size_mb as 'transaction_log_size'
    ,cast(@unallocated_space_mb*100.0/(@reserved_mb + @unallocated_space_mb) as decimal(10,2))as  'unallocated'
    ,cast(@reserved_mb*100/(@reserved_mb + @unallocated_space_mb) as decimal(10,2))as 'reserved'
    ,cast(@data_mb*100/(@reserved_mb + @unallocated_space_mb) as decimal(10,2))as 'data'
    ,cast(@index_mb*100/(@reserved_mb + @unallocated_space_mb) as decimal(10,2)) as 'index_1'
    ,cast(@unused_mb*100/(@reserved_mb + @unallocated_space_mb) as decimal(10,2))as 'unused'

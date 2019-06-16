Use master
GO

-- https://techcommunity.microsoft.com/t5/SQL-Server/Using-xEvents-to-capture-an-Actual-Execution-Plan/ba-p/392136
CREATE EVENT SESSION [PerfStats_Node] ON SERVER
ADD EVENT sqlserver.query_thread_profile(

ACTION(
	sqlos.scheduler_id,
	sqlserver.database_id,
	sqlserver.database_name, 
	sqlserver.is_system,
	sqlserver.plan_handle,
	sqlserver.query_hash_signed,
	sqlserver.query_plan_hash_signed,
	sqlserver.server_instance_name,
	sqlserver.session_id,
	sqlserver.session_nt_username,
	sqlserver.sql_text)
	WHERE (database_name ='AdventureWorks2014')
) 
ADD TARGET package0.event_file(SET filename=N'C:\Temp\PerfStats_Node.xel',max_file_size=(50),max_rollover_files=(2))
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF)
GO



-- Start the event session  

ALTER EVENT SESSION PerfStats_Node ON SERVER STATE = START;  
GO  

ALTER EVENT SESSION PerfStats_Node ON SERVER STATE = STOP;
GO

DROP EVENT SESSION [PerfStats_Node] ON SERVER 
GO

/*
-- sys.dm_exec_query_plan_stats

https://techcommunity.microsoft.com/t5/SQL-Server/What-if-the-Actual-Execution-Plan-was-always-available-for-any/ba-p/393387

https://www.brentozar.com/archive/2019/04/parameter-sniffing-in-sql-server-2019-air_quote_actual-plans/

*/



-- sp_whoIs Active
Exec sp_WhoIsActive
	@get_plans=1,
	@show_sleeping_spids = 2

-- https://github.com/amachanic/sp_whoisactive

/*
Get associated query plans for running tasks, if available
If @get_plans = 1, gets the plan based on the request's statement offset
If @get_plans = 2, gets the entire plan based on the request's plan_handle

*/

-- DMVS
Use AdventureWorks2016
GO

SELECT      decp.objtype,
            decp.usecounts,
            decp.refcounts,
            DB_NAME(dest.dbid)                       AS DatabaseName,
            OBJECT_NAME(dest.objectid, dest.dbid)    AS ObjectName,
            dest.text                                AS QueryText,
            deqp.query_plan
FROM        sys.dm_exec_cached_plans                 AS decp
CROSS APPLY sys.dm_exec_sql_text(decp.plan_handle)   AS dest
CROSS APPLY sys.dm_exec_query_plan(decp.plan_handle) AS deqp;
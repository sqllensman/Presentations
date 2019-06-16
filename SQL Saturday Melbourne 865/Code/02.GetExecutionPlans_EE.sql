CREATE EVENT SESSION [Capture Actual Plans] ON SERVER
ADD EVENT sqlserver.query_post_execution_showplan
(
 ACTION
 (
   sqlserver.sql_text
 )
)
ADD TARGET package0.event_file
(
  SET filename = N'C:\temp\CaptureActualPlans.xel'
)
WITH (EVENT_RETENTION_MODE = ALLOW_SINGLE_EVENT_LOSS);
GO

-- Start Session
ALTER EVENT SESSION [Capture Actual Plans] ON SERVER STATE = START;


-- Stop Session
ALTER EVENT SESSION [Capture Actual Plans] ON SERVER STATE = STOP;

SELECT event_data = CONVERT(XML, event_data)
INTO #tmp
FROM sys.fn_xe_file_target_read_file
(
  N'C:\temp\CaptureActualPlans*.xel',
  N'C:\temp\CaptureActualPlans*.xem', NULL, NULL);

-- All Data
SELECT event_time  = t.event_data.value(N'(/event/@timestamp)[1]', N'datetime'),
       sql_text    = t.event_data.value
                     (N'(/event/action[@name="sql_text"]/value)[1]', N'nvarchar(max)'),
       whole_xml   = t.event_data.query('.')
FROM #tmp AS t;

-- Show Plan
SELECT sql_text = t.event_data.value
   (N'(/event/action[@name="sql_text"]/value)[1]', N'nvarchar(max)'),
   actual_plan = z.xml_fragment.query('.')
FROM #tmp AS t
CROSS APPLY t.event_data.nodes(N'/event/data[@name="showplan_xml"]/value/*')
AS z(xml_fragment);


DECLARE @stmt NVARCHAR(MAX), @plan XML;

SELECT @stmt = t.event_data.value
               (N'(/event/action[@name="sql_text"]/value)[1]', N'nvarchar(max)'),
       @plan = z.xml_fragment.query('.')
FROM #tmp AS t
CROSS APPLY t.event_data.nodes(N'/event/data[@name="showplan_xml"]/value/ *')
AS z(xml_fragment);

-- "hide" the custom namespace via plain text replacement

SET @plan = CONVERT(XML, REPLACE(CONVERT(NVARCHAR(MAX), @plan),
  N'<ShowPlanXML xmlns="', N'<ShowPlanXML fakens="'));

-- add the StatementId attribute and set it to 1

SET @plan.modify(N'insert (attribute StatementId {"1"})
  into (//ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple)[1]');

-- make the top-most operator a SELECT operation, only because we *know* it is

SET @plan.modify(N'insert (attribute StatementType {"SELECT"})
  into (//ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple)[1]');

-- add the sql_text to the StatementText attribute

SET @plan.modify(N'insert (attribute StatementText {sql:variable("@stmt")})
  into (//ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple)[1]');

-- restore the custom namespace via plain text replacement

SET @plan = CONVERT(XML, REPLACE(CONVERT(NVARCHAR(MAX), @plan),
  N'<ShowPlanXML fakens="', N'<ShowPlanXML xmlns="'));

SELECT @plan;

/*
https://docs.microsoft.com/en-us/sql/relational-databases/extended-events/advanced-viewing-of-target-data-from-extended-events-in-sql-server?view=sql-server-2017

https://techcommunity.microsoft.com/t5/SQL-Server/Using-xEvents-to-capture-an-Actual-Execution-Plan/ba-p/392136

https://www.sqlservercentral.com/blogs/how-to-get-live-execution-plan-using-extended-events

https://sqlperformance.com/2013/03/sql-plan/showplan-impact

*/

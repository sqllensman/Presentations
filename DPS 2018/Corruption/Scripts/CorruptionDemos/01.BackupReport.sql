-- Snapshot of Backup Status for each database on Server
:CONNECT lensmansb

SET NOCOUNT ON
Use msdb
GO

Declare @RPO_FULL as smallint, @RPO_DIFF as smallint, @RPO_LOG as smallint;

SET @RPO_FULL = 1;	--Value in Hours:   Require full backups weekly
SET @RPO_DIFF = 1440;	--Value in Minutes: Require diff or full backups every day (1440 minutes)
SET @RPO_LOG = 120;		--Value in Minutes: Require log backups every 15 mins

WITH backup_history AS
(
SELECT
	ROW_NUMBER() OVER(PARTITION BY database_name, [type] ORDER BY database_name ASC, database_backup_lsn DESC) AS [Row Number]
	, database_name
	, backup_set_id
	, backup_finish_date
	, backup_start_date
	, [type]
	, [media_set_id]
	, [position]
	, [has_backup_checksums]
	,COUNT(*) OVER(PARTITION BY [media_set_id]) AS [BackupsInFile]
FROM msdb.dbo.[backupset]
WHERE [type] IN ('I', 'D', 'L')
AND is_copy_only = 0
AND server_name = SERVERPROPERTY('ServerName')
AND machine_name = SERVERPROPERTY('MachineName')
),
last_backup as
(
SELECT
	FB.database_name
  , FB.backup_set_id
FROM backup_history FB
WHERE FB.[Row Number] = 1
) 
SELECT  
	d.name,
	d.state_desc,
	d.recovery_model,
	d.recovery_model_desc,
	d.is_read_only,
	d.log_reuse_wait_desc, 
	d.page_verify_option_desc,
	bh.backup_finish_date,
	bh.backup_start_date,
	bh.type,
	b.backup_set_id,
	bh.media_set_id,
	bh.position,
	bh.BackupsInFile,
	bh.has_backup_checksums,
	rs.last_log_backup_lsn,
	d.create_date
into #BackupHistory
FROM  sys.databases d
INNER JOIN sys.database_recovery_status rs
	ON d.database_id = rs.database_id
LEFT OUTER JOIN last_backup b 
	ON d.name = b.database_name
LEFT OUTER JOIN backup_history bh 
	ON b.database_name = bh.database_name
	AND b.backup_set_id = bh.backup_set_id
WHERE d.name <> 'tempdb'
AND d.source_database_id is null;

DELETE FROM #BackupHistory
WHERE recovery_model = 3
AND type = 'L'

Select 'Backup Status Report for:' + @@Servername + ' at: ' + CONVERT(varchar(35),getdate(),109);

Select  	
	DBName,
	[Status],
	[ReadWrite],
	[Recovery model],
	[Log reuse wait],
	page_verify_option_desc,
	'FullBackup_checksum' =
		CASE 
			WHEN has_backup_checksums IS NULL THEN 'N/A'
			WHEN page_verify_option_desc = 'CHECKSUM' AND has_backup_checksums =1 THEN 'Yes' 
			ELSE 'No'
		END,
	'BackupPosition' =
		CASE 
			WHEN position IS NULL THEN 'No Backup'
			WHEN position = 1 AND BackupsInFile = 1 THEN 'Normal: 1 of 1'
			ELSE 'Warning: ' + CAST(position AS VARCHAR(10)) + ' of ' + CAST(BackupsInFile AS VARCHAR(10))
		END,
	'Last Full Backup' = Coalesce(Convert(varchar(26),[Full Backup],109), ''),
	'hoursSinceFull' = IsNull(Cast([hoursSinceFull] as varchar(10)),''),
	'Last Differential Backup' = Coalesce(Convert(varchar(26),[Differential Database],109), ''),
	'hoursSinceDiff' = IsNull(Cast([hoursSinceDiff] as varchar(10)),''),
	'Last Log Backup' = 
		CASE recovery_model 
			WHEN 3 THEN '' 
			ELSE  Coalesce(Convert(varchar(26),[Log],109), '') 
		END,
	'minutesSinceLog' = 
		CASE 
			WHEN Status = 'OFFLINE' THEN 0 
			WHEN Status = 'RESTORING' THEN 0
			WHEN ReadWrite = 'READ_ONLY' THEN 0
			ELSE IsNull(Cast([minutesSinceTLog] as varchar(10)),'') 
		END,
	'Potential_Data_Loss (mins)' = 
		CASE 
			WHEN Status = 'OFFLINE' THEN 0 
			WHEN Status= 'RESTORING' THEN 0
			WHEN ReadWrite = 'READ_ONLY' THEN 0 
			ELSE Coalesce([Potential_Data_Loss (mins)] , datediff(minute,create_date ,getdate())) 
		END,
	'Action Required' =
		CASE 
			WHEN Status = 'OFFLINE' THEN '' 
			WHEN Status = 'RESTORING' THEN ''
			WHEN ReadWrite = 'READ_ONLY' THEN ''
			WHEN ReadWrite = 'READ_WRITE' AND [Full Backup] IS NULL THEN  'Last Full Backup outside RPO'
			WHEN [Recovery model] = 'Full' AND [Potential_Data_Loss (mins)] > @RPO_LOG  THEN 'Log Backup outside RPO'
			WHEN [Recovery model] = 'SIMPLE' AND ([Differential Database] IS NULL OR [Differential Database] < [Full Backup]) 
				AND [Potential_Data_Loss (mins)] > @RPO_DIFF  THEN 'Last Full Backup outside RPO'
			WHEN [Recovery model] = 'SIMPLE' AND ([Differential Database] > [Full Backup]) 
				AND [hoursSinceFull] > @RPO_FULL  THEN 'Last Full Backup used as Base of Backup Chain outside RPO'
			WHEN [Recovery model] = 'SIMPLE' AND ([Differential Database] > [Full Backup]) 
				AND [Potential_Data_Loss (mins)] > @RPO_DIFF  THEN 'Last Diff Backup outside RPO'
			WHEN [Recovery model] = 'PSEUDO_FULL' AND ([Differential Database] IS NULL OR [Differential Database] < [Full Backup]) 
				AND [Potential_Data_Loss (mins)] > @RPO_DIFF  THEN 'Last Full Backup outside RPO'
			Else ''
		END
FROM
(Select
	DBName = b.name,
	Status = b.state_desc,
	b.recovery_model,
	b.page_verify_option_desc,
	ReadWrite =
	    Case
			WHEN b.is_read_only = 1 THEN 'READ_ONLY'
			ELSE 'READ_WRITE'
		End,
	'Recovery model' = 
		Case 
			WHEN (b.recovery_model < 3 AND b.last_log_backup_lsn IS NULL) THEN 'PSEUDO_' + b.recovery_model_desc
			ELSE b.recovery_model_desc
		END,			
	'Log reuse wait' = b.log_reuse_wait_desc,
	b.backup_finish_date,
	b1.[position],
	b1.[BackupsInFile],
	b1.[has_backup_checksums],
	b1.[hoursSinceFull],
	b2.[hoursSinceDiff],
	b3.[minutesSinceTLog],
	b4.[Potential_Data_Loss (mins)],	
	BackupType =
		Case b.type
			WHEN 'D' Then 'Full Backup'
			WHEN 'I' Then 'Differential Database' 
			WHEN 'L' THEN 'Log'
			WHEN 'F' THEN 'File/Filegroup'
			WHEN 'G' THEN 'Differential File'
			WHEN 'P' THEN 'Partial'  
			WHEN 'Q'THEN 'Differential partial' 
		End,
	b.create_date
 from #BackupHistory b
 OUTER APPLY (
				SELECT 
					position,
					BackupsInFile, 
					has_backup_checksums, 
					[hoursSinceFull] = datediff(hour,backup_finish_date,getdate())  
					FROM #BackupHistory b1
				WHERE b1.name = b.name AND b1.type = 'D'
			) b1
 OUTER APPLY (SELECT [hoursSinceDiff] = datediff(hour,backup_finish_date,getdate())  FROM #BackupHistory b1
			  WHERE b1.name = b.name AND b1.type = 'I') b2
 OUTER APPLY (SELECT [minutesSinceTLog] = datediff(minute,backup_finish_date,getdate())  FROM #BackupHistory b1
			  WHERE b1.name = b.name AND b1.type = 'L' and b1.recovery_model < 3) b3
 OUTER APPLY (Select [Potential_Data_Loss (mins)] = datediff(minute,Max(backup_finish_date) ,getdate()) from #BackupHistory b1
			  WHERE b1.name = b.name GROUP BY b1.name) b4
 ) As Source
PIVOT (
	MAX(backup_finish_date)
	FOR BackupType IN ([Full Backup], [Differential Database], [Log], [File/Filegroup], [Differential File], [Partial], [Differential partial] )
) As PivotTable
order by DBName;

DROP TABLE #BackupHistory




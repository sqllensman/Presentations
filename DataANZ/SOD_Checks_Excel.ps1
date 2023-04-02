# Write-SODToExcel.ps1
<#
 .SYNOPSIS
  Collect Start of Day Health Check Information and export to Excel.

 .DESCRIPTION
  Collects various Start day Information for Database Environment and saves into Excel
  This is used as Basis of Start of Day Health Checks

 .PARAMETER MonitorServer
  Name of the SQL Server Instance that collects and Stores SQL Server environment information

 .PARAMETER MonitorDB
  Name of the SQL Server Database that stores SQL Server environment information

 .PARAMETER ReportBasePath
  Network Path that holds the Excel Template and stores the output files

 
 .EXAMPLE
  PS C:\> Get-PCinformation -MonitorServer 'MASSPRDCL3-AG2L' -MonitorDB 'DBA_Reports' ReportBasePath '\\masflsprdc1-fs\bs\IT Operations\General\Completed Start of Day Sheets'
        Computer Name with Serial Number

 .NOTES
  Depends on Data Collection jobs that write data into the MonitorServer

#>

[CmdletBinding()]

PARAM ( 
    [string]$MonitorServer = 'Name_of_Inventory_Server',
    [string]$MonitorDB = 'DBA_Reports',
    [string]$ReportBasePath = 'Path to Template'
)
Begin {
    # Start of the BEGIN block.
    Import-Module -Name ImportExcel

    $DbaName = 'Name of User'

    $RunDate = (Get-Date).Date
    $ExcelTemplate = Join-Path -Path $ReportBasePath -ChildPath "Template_name.xlsx"
    $FilePath = $RunDate.Year.ToString() + "\" + $RunDate.ToString("MM MMMM") + "\" + "DBASOD_" + $RunDate.ToString("yyyyMMdd") + ".xlsx"
    $SODReportName = Join-Path -Path $ReportBasePath -ChildPath $FilePath

    try {
        $MonitoringServer = Connect-DbaInstance -SqlInstance $MonitorServer -Database $MonitorDB
    } catch {

    }

} # End Begin block

Process {
    # Start of PROCESS block.
    Write-Verbose -Message "Entering the PROCESS block [$($MyInvocation.MyCommand.CommandType): $($MyInvocation.MyCommand.Name)]."

    # Open Excel with Template File
    $SODReport = Open-ExcelPackage -Path $ExcelTemplate -KillExcel
    
    # Get Reference to Main Sheet
    $WorkSheet = $SODReport.Workbook.Worksheets["DAILY"].Cells
    
    # Add the Current Date
    $WorkSheet[1,5].Value = $RunDate
    # Add the User Date
    $WorkSheet[1,8].Value = $DbaName
    Close-ExcelPackage -ExcelPackage $SODReport -SaveAs $SODReportName 

    $SODReport = Open-ExcelPackage -Path $SODReportName

    ## Check status of Jobs on SSIS Server 
    $SqlInstance = 'Name of SSIS Server'

    $ExtractQuery = "
    SELECT EXECUTION_ID
          ,FOLDER_NAME
          ,PROJECT_NAME
          ,PACKAGE_NAME
          ,ENVIRONMENT_NAME
          ,[STATUS]
          ,CASE
		    WHEN [STATUS] = 2 then 'Running'
		    WHEN [STATUS] = 3 then 'Cancelled'
		    WHEN [STATUS] = 4 then 'Failed'
		    WHEN [STATUS] = 5 then 'Pending'
		    WHEN [STATUS] = 6 then 'Ended unexpectedly'
		    WHEN [STATUS] = 7 then 'Succeeded'
		    WHEN [STATUS] = 8 then 'Stopping'
		    WHEN [STATUS] = 9 then 'Completed'
		    ELSE CAST(STATUS AS VARCHAR(2))
	      END AS [STATUS_DESC]
         ,CAST(START_TIME AS NVARCHAR(25)) AS START_TIME
          ,CAST(END_TIME AS NVARCHAR(25)) AS END_TIME
          ,CALLER_NAME
          ,SERVER_NAME
          ,MACHINE_NAME
    FROM SSISDB.CATALOG.EXECUTIONS
    WHERE STATUS NOT IN (15)"

    $QueryData = Invoke-DbaQuery -SqlInstance $SqlInstance -Database SSISDB -Query $ExtractQuery -as DataTable
    Write-DbaDataTable -SqlInstance $MonitorServer -Database $MonitorDB -InputObject $QueryData -Schema 'dbinfo' -Table 'ssis_prod_status' -Truncate

    ## Check status of Jobs on an Instance based on Category
    # Get Data 
    $SqlInstance = 'Instance Name'
    $jobCategory = 'Job Category'
    $MaxAgeInHours = 18

    $JobsInCategory = Get-DbaAgentJob -SqlInstance $SqlInstance -Category $jobCategory -ExcludeDisabledJobs | Where-Object -Property HasSchedule -EQ $true

    $jobs = @()
    $Date = Get-Date

    foreach($job in $JobsInCategory) {
        $AgeSinceRun = ($Date - $job.LastRunDate).TotalHours
        If ($job.LastRunOutcome -ne 'Succeeded') {
            $status = 'Last Run Unsuccessful'
        } elseif ($AgeSinceRun -gt $MaxAgeInHours) {
            $status = "Last Run more than $MaxAgeInHours hours ago"
        } else {
            $status = 'Last Run OK'
        }
        
        $jobresult = [PSCustomObject]@{
            ComputerName = $job.ComputerName
            SqlInstance = $job.SqlInstance
            JobCategory = $job.Category
            Name = $job.Name 
            Category = $job.Category
            Enabled = $job.Enabled
            LastRunOutcome = $job.LastRunOutcome
            LastRunDate = $job.LastRunDate
            Age = $AgeSinceRun
            Status = $status
            OwnerLoginName = $job.OwnerLoginName
            OperatorToEmail = $job.OperatorToEmail
        }

        $jobs+= $jobresult
    }

    if ($jobs) {
        $SheetName =  'SheetName'
        $tableTitle =  'tableTitle'
        $tableName = 'tableName'

        $SODReport = Open-ExcelPackage -Path $SODReportName
        $jobs | Export-Excel -ExcelPackage $SODReport -WorksheetName $SheetName -TableName $tableName -AutoSize -FreezeTopRow -title $tableTitle -TitleBold -TableStyle Light20 
    } Else {

    }

    $DOW = (Get-Date).DayOfWeek
    if ($DOW -eq 'Monday') {

        # Get Data 
        $SqlInstance = 'Instance Name'
        $jobCategory = 'jobCategory'
        $MaxAgeInHours = 96

        $JobsInCategory = Get-DbaAgentJob -SqlInstance $SqlInstance -Category $jobCategory -ExcludeDisabledJobs

        $jobs = @()
        foreach($job in $JobsInCategory) {

            $AgeSinceRun = ($Date - $job.LastRunDate).TotalHours
            If ($job.LastRunOutcome -ne 'Succeeded') {
                $status = 'Last Run Unsuccessful'
            } elseif ($AgeSinceRun -gt $MaxAgeInHours) {
                $status = "Last Run more than $MaxAgeInHours hours ago"
            } else {
                $status = 'Last Run OK'
            }
        
            $jobresult = [PSCustomObject]@{
                ComputerName = $job.ComputerName
                SqlInstance = $job.SqlInstance
                JobCategory = $job.Category
                Name = $job.Name 
                Category = $job.Category
                Enabled = $job.Enabled
                LastRunOutcome = $job.LastRunOutcome
                LastRunDate = $job.LastRunDate
                Age = $AgeSinceRun
                Status = $status
                OwnerLoginName = $job.OwnerLoginName
                OperatorToEmail = $job.OperatorToEmail
            }

            $jobs+= $jobresult

        }

        if ($jobs) {
            $SheetName =  'SheetName2'
            $tableTitle =  'tableTitle2'
            $tableName = 'tableName2'
            $SODReport = Open-ExcelPackage -Path $SODReportName    
            $jobs | Export-Excel -ExcelPackage $SODReport -WorksheetName $SheetName -TableName $tableName -AutoSize -FreezeTopRow -title $tableTitle -TitleBold -TableStyle Light20 
        } else {

        }
    }

    # Prepare Daily Check Info

    # 1. Disk Space Warnings
    $SODReport = Open-ExcelPackage -Path $SODReportName
    $SheetName =  'Disk Warnings'
    $tableTitle =  'Disk Warnings - 90%'
    $tableName = 'DiskSpaceWarning'

    $ExtractQuery = "
    select 
	    [HostName]+' ' + [Name] AS [Record Id],
	    IIF([clusterName]='',[HOSTNAME],[ClusterNAme]) AS [Cluster/Server Name],
	    [HostName] as [Server Name],
	    [Name] as [Drive Name],
	    [Label] as [Drive Label],
	    [Size] as [Size (GB)],
	    [FreeSpace] as [FreeSpace (GB)],
	    [usedPct] as [Disk Used (%)],
	    [freePct] as [Disk Free (%)],
	    Notes
    FROM [DBA_Reports].[dbinfo].[sql_host_volumes] shv
    LEFT OUTER JOIN [DBA_Reports].[dbinfo].[sql_host_volumes_notes] shvn 
	    ON  [shvn].[ID] = REPLACE([HostName]+[Name],':','')
    WHERE usedPct >= 90.0
    AND REPLACE([HostName]+[Name],':','') NOT IN ('')"

    $QueryData = Invoke-DbaQuery -SqlInstance $MonitoringServer -Database $MonitorDB -Query $ExtractQuery -as DataTable
    if($QueryData.Rows.Count -gt 0) {
        $ExcelData = $QueryData | Select 'Record Id', 'Cluster/Server Name', 'Server Name', 'Drive Name', 'Drive Label', 'Size (GB)', 'FreeSpace (GB)', 'Disk Used (%)', 'Disk Free (%)', 'Notes'
        $ExcelData | Export-Excel -ExcelPackage $SODReport -WorksheetName $SheetName -TableName $tableName -AutoSize -FreezeTopRow -title $tableTitle -TitleBold -TableStyle Light20
    }


    # 2. Incomplete Refresh
    $SODReport = Open-ExcelPackage -Path $SODReportName
    $SheetName =  'Incomplete Refresh'
    $tableTitle =  'Incomplete Refresh - Running or failed'
    $tableName = 'tableName3'

    $ExtractQuery = "
    SELECT 
	    ROW_NUMBER() OVER ( ORDER BY [DBInstance]) as [Row ID],
	    [Request],
	    [Database_target] as [Target Database],
	    [DBInstance] as Instance,
	    [Urgency],
	    [Title],
	    [Message]
    FROM [DBA_Reports].[dbinfo].[vw_sod_refresh_incomplete]
    ORDER BY  [DBInstance]"

    $QueryData = Invoke-DbaQuery -SqlInstance $MonitoringServer -Database $MonitorDB -Query $ExtractQuery -as DataTable
    if($QueryData.Rows.Count -gt 0) {
        $ExcelData = $QueryData | Select 'Row ID', 'Request', 'Target Database', 'Instance', 'Urgency', 'Title', 'Message'
        $ExcelData | Export-Excel -ExcelPackage $SODReport -WorksheetName $SheetName -TableName $tableName -AutoSize -FreezeTopRow -title $tableTitle -TitleBold -TableStyle Light20
    }

    # 3. Log Utilisation
    $SODReport = Open-ExcelPackage -Path $SODReportName
    $SheetName =  'Log Utilisation'
    $tableTitle =  'High Database Log Utilisation'
    $tableName = 'LogUtilisation'

    $ExtractQuery = "
    SELECT 
	    ROW_NUMBER() OVER ( ORDER BY [HostName] ) as [Row ID],
	    [HostName] as [Server Name],
	    [FullInstanceName] as Instance,
	    [Database Name],
	    [Database ID],
	    [Log Size (MB)],
	    [Log Used (MB)],
	    [Log Free Space Left (MB)],
	    [Log space Used (%)],
	    [Recovery Model],
	    [Database State],
	    [Log Reuse Wait Description]
    FROM [dbinfo].[vw_sod_high_logutil]
    ORDER BY [HostName]"

    $QueryData = Invoke-DbaQuery -SqlInstance $MonitoringServer -Database $MonitorDB -Query $ExtractQuery -as DataTable
    if($QueryData.Rows.Count -gt 0) {
        $ExcelData = $QueryData | Select 'Row ID', 'Server Name','Instance', 'Database Name', 'Database ID','Log Size (MB)','Log Used (MB)','Log Free Space Left (MB)','Log space Used (%)','Recovery Model','Database State','Log Reuse Wait Description'
        $ExcelData | Export-Excel -ExcelPackage $SODReport -WorksheetName $SheetName -TableName $tableName -AutoSize -FreezeTopRow -title $tableTitle -TitleBold -TableStyle Light20
    }
} # End of PROCESS block.

End {
        # Start of END block.
        Write-Verbose -Message "Entering the END block [$($MyInvocation.MyCommand.CommandType): $($MyInvocation.MyCommand.Name)]."
        Close-ExcelPackage -show $SODReport
        # Add additional code here.

} # End of the END Block.


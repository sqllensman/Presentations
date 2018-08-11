Return 'This is a demo, don''t run the whole thing, fool!!'

#Task Based Demo
Import-Module -Name dbatools

#region Testing an upgrade
# What databases are available
Get-DbaDatabase -SqlInstance w2016base | Out-GridView
Get-DbaDatabase -SqlInstance w2016base\sql2017 | Out-GridView


# Step 1 Backup to Networkshare
$NetworkPath = "\\vmware-host\Shared Folders\SQL_DATA\Backup\W2016Base"
$BackupDirectory = "\\vmware-host\Shared Folders\SQL_DATA\Backup\W2016Base$2017" 

# Create Directory if Required
if(!(Test-Path -Path $BackupDirectory )){
    New-Item -ItemType directory -Path $BackupDirectory
}

if(!(Test-Path -Path $BackupDirectory )){
    New-Item -ItemType directory -Path $BackupDirectory
}

Backup-DbaDatabase -SqlInstance W2016BASE -BackupDirectory $NetworkPath -Database AdventureWorks2014, AdventureWorksDW2014, AdventureWorksLT2008 -Checksum

## Restore them to a different instance
Restore-DbaDatabase -SqlInstance w2016base\SQL2017 -Path $NetworkPath -DestinationDataDirectory C:\SQL_DATA\2017\Data -DestinationLogDirectory C:\SQL_DATA\2017\Log -WithReplace

# Upgrade to Latest Version
$Databases = Get-DbaDatabase -SqlInstance w2016base\sql2017 | Where Compatibility -ne 140 
$Databases  | Out-GridView

Foreach ($db in $Databases) {
    Invoke-DbaDatabaseUpgrade -SqlInstance w2016base\sql2017 -Database $db.Name
<#
Runs the below processes against the databases
-- Puts compatibility of database to level of SQL Instance
-- Runs CHECKDB DATA_PURITY
-- Runs DBCC UPDATESUSAGE
-- Updates all users statistics
-- Runs sp_refreshview against every view in the database

#>
}


## Backup new instances
Backup-DbaDatabase -SqlInstance W2016BASE\SQL2017 -BackupDirectory $BackupDirectory -ExcludeDatabase master,model,msdb -Checksum

## Test instances
Test-DbaLastBackup -SqlInstance W2016BASE\SQL2017  | Out-GridView


# Remove after testing
Remove-DbaDatabase -SqlInstance w2016base\SQL2017 -Databases AdventureWorks2014, AdventureWorksDW2014, AdventureWorksLT2008

#endregion

#region Script out all tables for all databases

$server = 'W2016Base'
$BasePath = 'C:\GIT\DatabaseScripts'

Invoke-Item $BasePath

# Run Code from ScriptDatabase.ps1

Invoke-Item $BasePath

git status

#endregion

#region Collect Performance Data Queries
# https://www.sqlskills.com/blogs/glenn/sql-server-diagnostic-information-queries-for-August-2018/
$OutputDir = 'C:\DPS2018\gb'
$Suffix = 'DPS2018_' + (Get-Date -Format yyyy-MM-dd_HH-mm-ss)
Invoke-DbaDiagnosticQuery -SqlInstance W2016BASE | Export-DbaDiagnosticQuery -Path $OutputDir -Suffix $Suffix
explorer $OutputDir


$InstanceList = @('SQLSERVER2008\SQL01', 
                'SQLSERVER2008\SQL02',
                'SQLSERVER2008\SQL03',
                'SQLSERVER2008\SQL04',
                'SQLSERVER2008\SQL05',
                'SQLSERVER2008\SQL2005',
                'WIN-2012-SQL01\SQL2008',
                'WIN-2012-SQL01\SQL2008R2',
                'WIN-2012-SQL01\SQL2012',
                'WIN-2012-SQL01\SQL2014',
                'W2016BASE',
                'W2016BASE\SQL2017'
                )

## Takes about 14 minutes
$OutputDir = 'C:\DPS2018\temp'
$Suffix = 'DPS2018_' + (Get-Date -Format yyyy-MM-dd_HH-mm-ss)
Invoke-DbaDiagnosticQuery -SqlInstance $InstanceList | Export-DbaDiagnosticQuery -Path C:\SQLSaturday\temp -Suffix $Suffix
# Saved to 
explorer 'C:\DPS2018\temp'

## Generated 7919 Files
#endregion




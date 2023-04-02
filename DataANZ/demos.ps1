# We're going to need dbatools
Import-Module dbatools

(Get-Command -Module dbatools).Count

#region Set up connection
$credential = Get-Credential -UserName sa

$SQL1 = '192.168.20.105:8681'
$SQL2 = '192.168.20.106:1433'

$mssql1 = Connect-DbaInstance -SqlInstance $SQL1 -SqlCredential $credential
$mssql2 = Connect-DbaInstance -SqlInstance $SQL2 -SqlCredential $credential

Invoke-DbaQuery -SqlInstance $mssql2 -Query "Select * FROM sys.databases" | Format-Table
Get-DbaAgentServer -SqlInstance $mssql1, $mssql2 | Export-Excel

Get-DbaDbBackupHistory -SqlInstance $mssql2 -LastFull | Format-Table


# Take some backups
$null = Backup-DbaDatabase -SqlInstance $mssql2 -ExcludeDatabase StackOverflow2013 -CompressBackup -CopyOnly

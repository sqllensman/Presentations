Remove-Module -Name dbatools
# Load local copy
Import-Module "C:\GitHub\dbatools\dbatools.psm1" -Force

Get-Module -Name dbatools


$SQLinstance = 'LensmanSB'
$database = 'Northwind01'

Get-DbaDbState -SqlInstance $SQLinstance -Database $database

Set-DbaDbState -SqlInstance $SQLinstance -Database $database -Online -ReadOnly -Force

Set-DbaDbState -SqlInstance $SQLinstance -Database $database -ReadWrite -Force
Set-DbaDbState -SqlInstance $SQLinstance -Database $database -Offline -Force

# $newstate = Get-DbState -databaseName $db.Name -dbStatuses $dbStatuses[$server]

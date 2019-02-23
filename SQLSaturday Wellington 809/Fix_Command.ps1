Remove-Module -Name dbatools
# Load local copy
Import-Module "C:\GitHub\dbatools\dbatools.psm1" -Force

Get-Module -Name dbatools

$SQLinstance = 'LensmanSB'

Invoke-DbaDbShrink -SqlInstance $SQLinstance -AllUserDatabases -WhatIf

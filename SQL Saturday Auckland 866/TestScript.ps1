Remove-Module -Name dbatools
# Load local copy
Import-Module "C:\GitHub\dbatools\dbatools.psm1" -Force

$Module = 'Export-DbaDBRole'
Invoke-DbatoolsFormatter -Path "C:\GitHub\dbatools\functions\$Module.ps1"
Invoke-DbatoolsFormatter -Path C:\GitHub\dbatools\tests\$Module.Tests.ps1

$Module = 'Export-DbaServerRole'
Invoke-DbatoolsFormatter -Path "C:\GitHub\dbatools\functions\$Module.ps1"
Invoke-DbatoolsFormatter -Path C:\GitHub\dbatools\tests\$Module.Tests.ps1

Invoke-Pester -Script  "C:\GitHub\dbatools\tests\Export-DbaServerRole.Tests.ps1" -Verbose
Invoke-Pester -Script  "C:\GitHub\dbatools\tests\Export-DbaDbRole.Tests.ps1" -Verbose









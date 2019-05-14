Remove-Module -Name dbatools
# Load local copy
Import-Module "C:\GitHub\dbatools\dbatools.psm1" -Force


$SQLinstance = 'LensmanSB'

Export-DbaCredential -SqlInstance $SQLinstance -Path 'C:\SQL_Data\Scripts\Creds.sql' -Identity 'LENSMANSB\Powershell'


Invoke-DbatoolsFormatter -Path C:\GitHub\dbatools\functions\Export-DbaCredential.ps1
Invoke-DbatoolsFormatter -Path C:\GitHub\dbatools\internal\functions\Get-DecryptedObject.ps1




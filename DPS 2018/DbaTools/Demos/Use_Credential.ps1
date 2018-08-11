# Testing Connection via SQLCredentials
$Credential = Import-Clixml -Path "C:\DPS2018\Credentials\DBUser_${env:USERNAME}_${env:COMPUTERNAME}.xml"
$Credential

Test-DbaDatabaseOwner -SqlInstance win-2012-sql01\sql2008 -SqlCredential $Credential | Out-GridView

# If I want to Fix
#Find-DbaCommand *Owner

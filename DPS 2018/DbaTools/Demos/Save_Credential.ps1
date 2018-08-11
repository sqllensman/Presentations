# Save Credential

$Credential = Get-Credential

$Credential | Export-Clixml -Path "C:\DPS2018\Credentials\DBUser_${env:USERNAME}_${env:COMPUTERNAME}.xml"


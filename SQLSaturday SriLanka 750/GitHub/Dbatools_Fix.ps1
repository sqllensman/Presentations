Remove-Module dbatools
Import-Module 'C:\GitHub\dbatools\dbatools.psd1'


Get-DbaAgentJob -SqlInstance LensmanSB | Export-DbaScript -path  "C:\Lensman\Output\script4.sql" -BatchSeparator "GO" -NoPrefix


Get-DbaAgentJob -SqlInstance LensmanSB | Export-DbaScript -Passthru | ForEach-Object { $_ } | Out-GridView #  Set-Content -Path "C:\Lensman\Output\script1.sql"


Get-Help -Name Export-DbaScript -ShowWindow

Get-Help -Name New-DbaScriptingOption -ShowWindow


$options = New-DbaScriptingOption

##$options | Get-Member | Out-GridView

$options.ScriptDrops = $true
$options.NoCommandTerminator  = $false

Get-DbaAgentJob -SqlInstance LensmanSB | Export-DbaScript -path  "C:\Lensman\Output\script3.sql" -ScriptingOptionsObject $options



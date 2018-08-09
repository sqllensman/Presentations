# The computername we will be testing
Set-DbcConfig -Name app.computername -Value 'WIN-2012-SQL01'                                                                                                                                                                                                         
# The Instances we want to test
Set-DbcConfig -Name app.sqlinstance -Value 'WIN-2012-SQL01\SQL2008' ,'WIN-2012-SQL01\SQL2008R2','WIN-2012-SQL01\SQL20012', 'WIN-2012-SQL01\SQL2014'                                                                                                                                            
# The database owner we expect
Set-DbcConfig -Name policy.validdbowner.name -Value 'dbachecksdemo\dbachecks'  
# the database owner we do NOT expect
Set-DbcConfig -Name policy.invaliddbowner.name -Value 'sa'      
# Should backups be compressed by default?
Set-DbcConfig -Name policy.backup.defaultbackupcompression -Value $true     
# Do we allow DAC connections?
Set-DbcConfig -Name policy.dacallowed -Value $true    
# What recovery model should we have?
Set-DbcConfig -Name policy.recoverymodel.type -value FULL     
# What should our database growth type be?
Set-DbcConfig -Name policy.database.filegrowthtype -Value kb   
# What authentication scheme are we expecting?                                                                                                            
Set-DbcConfig -Name policy.connection.authscheme -Value 'NTLM'
# Which Agent Operator should be defined?
Set-DbcConfig -Name agent.dbaoperatorname -Value 'DBA Team'
# Which Agent Operator email should be defined?
Set-DbcConfig -Name agent.dbaoperatoremail -Value 'DBATeam@TheBeard.Local'
# Which failsafe operator shoudl be defined?
Set-DbcConfig -Name agent.failsafeoperator -Value 'DBA Team'
# Where is the whoisactive stored procedure?
Set-DbcConfig -Name policy.whoisactive.database -Value DBAAdmin 
# What is the maximum time since I took a Full backup?
Set-DbcConfig -Name policy.backup.fullmaxdays -Value 7
# What is the maximum time since I took a DIFF backup (in hours) ?
Set-DbcConfig -Name policy.backup.diffmaxhours -Value 26
# What is the maximum time since I took a log backup (in minutes)?
Set-DbcConfig -Name policy.backup.logmaxminutes -Value 30 
# What is my domain name?
Set-DbcConfig -Name domain.name -Value 'WORKGROUP'
# Where is my Ola database?
Set-DbcConfig -Name policy.ola.database -Value DBAAdmin
# Which database should not be checked for recovery model
Set-DbcConfig -Name policy.recoverymodel.excludedb -Value 'master','msdb','tempdb'
# What is my SQL Credential
Set-DbcConfig -Name app.sqlcredential -Value $null
# Should I skip the check for temp files on c?
Set-DbcConfig -Name skip.tempdbfilesonc -Value $true
# Should I skip the check for temp files count?
Set-DbcConfig -Name skip.tempdbfilecount -Value $true
# Which Checks should be excluded?
Set-DbcConfig -Name command.invokedbccheck.excludecheck -Value LogShipping,ExtendedEvent, HADR, PseudoSimple,spn
# How many months before a build is unsupported do I want to fail the test?
Set-DbcConfig -Name policy.build.warningwindow -Value 6
Get-Dbcconfig | ogv



Export-DbcConfig -Path C:\SQLSaturday\Edmonton\Config\production_config.json


Reset-DbcConfig

Import-DbcConfig -Path C:\SQLSaturday\Edmonton\Config\production_config.json



Get-Help Invoke-DbcCheck -ShowWindow 

Update-DbcPowerBiDataSource -Environment Production


Invoke-DbcCheck -Show Fails -PassThru | Update-DbcPowerBiDataSource -Environment Production
# Open the PowerBi
Start-DbcPowerBi
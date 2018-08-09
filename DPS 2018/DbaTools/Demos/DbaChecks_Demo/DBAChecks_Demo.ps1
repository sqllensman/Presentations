Return 'This is a demo, don''t run the whole thing, fool!!'
<#
    Created June 2018
    Using dbchecks Version 1.1.138

#>

#region Module Information

Import-Module -Name dbachecks

# Check Versions of Dependant Modules
Get-Module -Name dbatools | Select Path, Version | Out-GridView
Get-Module -Name PSFramework | Select Path, Version | Out-GridView
Get-Module -Name Pester | Select Path, Version | Out-GridView

# Check Version and Location
Get-Module -Name dbachecks | Select Path, Version | Out-GridView

# List Available Commands (17)
Get-Command -Module dbachecks -CommandType Function | Out-GridView

#endregion


# Just Backups
$servers = 'WIN-2012-SQL01\SQL2008','WIN-2012-SQL01\SQL2008R2','WIN-2012-SQL01\SQL2012','WIN-2012-SQL01\SQL2014','W2016BASE','W2016BASE\SQL2017'
Invoke-DbcCheck -SqlInstance $servers -Checks LastBackup -Show Fails, Summary 

Get-DbcConfig -Name *backup*


#region List of Available Checks and Tags (look at Config  later)
# Get List of Checks
$Checks = Get-DbcCheck

#How Many (80 on first release) - 91 for 1.13
$Checks.Count

#View Available
$Checks  | Out-GridView

# Tags
$Tags = Get-DbcTagCollection
$Tags.Count

$Tags | Out-GridView

#endregion

#region Running With Invoke-DbcCheck	

# View Help for Invoke-DbcCheck
Get-Help Invoke-DbcCheck -ShowWindow


#  Run the Checks for Single Server and Particular Checks
$servers = 'W2016Base'
Invoke-DbcCheck -SqlInstance $servers -Checks SuspectPage, IdentityUsage, PseudoSimple 


#  Run the Checks for Single Server and Particular Checks - Only Output 
Invoke-DbcCheck -SqlInstance $servers  -Checks SuspectPage, IdentityUsage, PseudoSimple -Show Fails

Invoke-DbcCheck -ComputerName $servers  -Checks PowerPlan -Show Fails


# Run Checks with Tag Instance
Invoke-DbcCheck -SqlInstance $servers -Checks Instance 

# Run Checks with Tag Instance and Save output Does not display output
# Output written to 
Invoke-DbcCheck -SqlInstance $servers -Checks Instance -Show Fails, Summary


$Results = Invoke-DbcCheck -SqlInstance $servers -Checks Instance, Identity -Show Summary -PassThru 

$Results.GetType()

# View Output
$Results.FailedCount
$Results.InconclusiveCount
$Results.PassedCount
$Results.PendingCount
$ResultS.PassedCount
$ResultS.SkippedCount
$Results.TotalCount

$Results.ExcludeTagFilter
$Results.TagFilter
$Results.Time


$Results.TestNameFilter

$Results.TestResult | Select Describe, Context, Name, Passed, Result, FailureMessage, StackTrace, Time | Out-GridView

# Can filter to see skipped or failed tests

# Skipped Results - What where they
$Results.TestResult | Where Result -eq 'Skipped' | Out-GridView

# Why Skipped ?
Get-DbcConfigValue -Name skip.tempdbfilecount
#Set-DbcConfig -Name skip.tempdbfilecount -Value $false




# Save to JSON file needed by PowerBI
Clear-DbcPowerBiDataSource 
$Results | Update-DbcPowerBiDataSource -Environment LocalHostTest



#View report
Start-DbcPowerBi

<#

    Basically does this:
    $InputObject.TestResult | Select-Object -First 20 | ConvertTo-Json -Depth 3 | Out-File "$env:windir\temp\dbachecks.json"

    oUTPUT IN $env:windir\temp\dbachecks.json

    Get-Help Update-DbcPowerBiDataSource -ShowWindow
#>

#Can be run as:
Invoke-DbcCheck -SqlInstance $servers -Checks Instance, Identity -Show Summary -PassThru | Update-DbcPowerBiDataSource -Environment LocalHostTest
Start-DbcPowerBi


#endregion


#region Configuration

<#
dbachecks enables you to set configuration items at run-time or for your session 
Configurations can be exported and imported so you can create different configs for different use cases

Configurations are persisted via Registry Key

There are 150 (June 2018) configuration items at present. You can see the current configuration by running

#>

#Configurations
$Config = Get-DbcConfig

$Config.Count

$Config | Select Name , Description, Value | Out-GridView

# Set the servers you'll be working with
Set-DbcConfig -Name app.computername -Value WIN-2012-SQL01, W2016BASE
Set-DbcConfig -Name app.sqlinstance -Value W2016BASE\SQL2017, W2016BASE, WIN-2012-SQL01\SQL2014
Set-DbcConfig -Name policy.whoisactive.database -Value DBAAdmin 

Get-DbcConfigValue -Name app.computername
Get-DbcConfigValue -Name app.sqlinstance



# Invoke a few tests
Invoke-DbcCheck -Checks Instance, Server



# Check for WhoIsActive failed
# Check current configuration
Get-DbcConfigValue -Name policy.whoisactive.database 


Set-DbcConfig -Name policy.whoisactive.database -Value master

Invoke-DbcCheck -Checks WhoIsActiveInstalled

Export-DbcConfig -Path C:\SQLSaturday\Melbourne\Config\test_config.json

#Reset Configs to Default
Reset-DbcConfig

#Try running Check
Invoke-DbcCheck -Checks WhoIsActiveInstalled

#Import Config from File
Import-DbcConfig -Path C:\SQLSaturday\Melbourne\Config\test_config.json

#endregion

#region Using a Registered Server
# Clear PowerBi Data first
Clear-DbcPowerBiDataSource

$cmsServer = 'W2016Base'
$groupName = 'Production'
$sqlinstances = Get-DbaRegisteredServer -SqlInstance $cmsServer -Group $groupName

$sqlinstances | Out-GridView

$tags = 'AutoClose', 'AutoShrink', 'DAC', 'TempDbConfiguration', 'DatafileAutoGrowthType'

$tags | ForEach-Object {
    $tag = $PSItem
 
    $obj =  [pscustomobject]@{            
        ServerGroup = $groupName
        NumServers = $sqlinstances.Count
        Tag = $tag
        InvokeStartTime = Get-Date
        InvokeCompleteTime = $null
        WriteResultsTime = $null
        TestExecution = $null
        InvokeDuration = $null
        ResultsDuration = $null
        PassedCount       = $null
        FailedCount       = $null
        SkippedCount      = $null
        PendingCount      = $null
        InconclusiveCount = $null               
    }
             
    $results = Invoke-DbcCheck -SqlInstance $sqlinstances -tags $tag -PassThru -Show Fails
    $obj.TestExecution     = $results.time
    $obj.PassedCount       = $results.PassedCount      
    $obj.FailedCount       = $results.FailedCount      
    $obj.SkippedCount      = $results.SkippedCount     
    $obj.PendingCount      = $results.PendingCount     
    $obj.InconclusiveCount = $results.InconclusiveCount
 
    $obj.InvokeCompleteTime = Get-Date
 
    $results | Update-DbcPowerBiDataSource -Environment $groupName -Append
    $obj.WriteResultsTime = Get-Date      
 
    $obj.InvokeDuration = New-TimeSpan -Start $obj.InvokeStartTime -End $obj.InvokeCompleteTime
    $obj.ResultsDuration = New-TimeSpan -Start $obj.InvokeCompleteTime -End $obj.WriteResultsTime 
      
} # $tags | ForEach-Object 


Start-DbcPowerBi


#endregion              

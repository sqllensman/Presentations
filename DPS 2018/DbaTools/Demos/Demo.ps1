Return 'This is a demo, don''t run the whole thing, fool!!'

Import-Module -Name dbatools

# Module Path and Version
Get-Module -Name dbatools | Select Path, Version | Out-GridView

#region Finding Commands
## Lets look at the commands
Get-Command -Module dbatools -CommandType Function | Out-GridView

$Commands = Get-Command -Module dbatools -CommandType Function

## How many Commands?
$Commands.Count

$Commands | Out-GridView


## How do we find commands?
Get-Help Find-DbaCommand -ShowWindow


Find-DbaCommand -Tag Backup | Out-GridView
Find-DbaCommand -Tag Restore | Out-GridView
Find-DbaCommand -Tag Migration | Out-GridView
Find-DbaCommand -Tag AG | Out-GridView

Find-DbaCommand -Tag LogShipping | Out-GridView
Find-DbaCommand -Tag Memory | Out-GridView

Find-DbaCommand -Tag Snapshot | Out-GridView


Find-DbaCommand -Tag Perfmon | Format-Table


Find-DbaCommand -Pattern User | Out-GridView 
Find-DbaCommand -Pattern linked | Out-GridView

Find-DbaCommand -Pattern dbatools | Out-GridView

Find-DbaCommand -Pattern log | Out-GridView

# Save to a Table to allow querying
Find-DbaCommand * | Select CommandName, Synopsis, Description, Tags, Links | Write-DbaDataTable -SqlInstance W2016BASE\SQL2017 -Database dbareports -AutoCreateTable -Table DBACommands1

## How do we use commands?

## ALWAYS ALWAYS use Get-Help
Get-Help Test-DbaLinkedServerConnection

Get-Help Test-DbaLinkedServerConnection -Detailed

Get-Help Test-DbaLinkedServerConnection -Parameter SqlInstance

Get-Help Test-DbaLinkedServerConnection -Examples

Get-Help Test-DbaLinkedServerConnection -Full

Get-Help Test-DbaLinkedServerConnection -ShowWindow

Get-Help Test-DbaLinkedServerConnection -Parameter SqlInstance

## Here a neat trick

Find-DbaCommand -Pattern Index | Out-GridView -PassThru | Get-Help -ShowWindow 
#endregion

# Migrations
# Not running a migration here - Below are links to articles and videos
Start-Process 'https://dbatools.io/slides-videos/'
Start-Process 'https://dbatools.io/scheduling-a-migration/'
Start-Process 'https://dbatools.io/real-world-tde-database-migrations/'



# Get Information at Computer Level

Get-DbaComputerSystem -ComputerName W2016Base | Out-GridView
Get-DbaOperatingSystem -ComputerName W2016Base | Out-GridView
Get-DbaSqlService -ComputerName W2016Base | Out-GridView
Get-DbaPageFileSetting -ComputerName W2016Base | Out-GridView

Get-DbaDiskSpace -ComputerName W2016Base | Select * | Out-GridView


# Installed Features
Get-DbaSqlFeature -ComputerName W2016Base | Out-GridView


#region Backups and testing restores
## Everyone tests their restores correct?
## Lets back up those new databases to a Network Share
Backup-DbaDatabase -SqlInstance W2016BASE\SQL2017 -BackupDirectory "\\vmware-host\Shared Folders\SQL_DATA\SQLSaturday" -ExcludeDatabase master,model,msdb -Checksum


# and test ALL of our backups :-)
Test-DbaLastBackup -SqlInstance W2016BASE  | Out-GridView

## You 'could' just verify them
Test-DbaLastBackup -SqlInstance W2016BASE -Destination W2016base\SQL2017 -VerifyOnly | Out-GridView

# What databases are available
Get-DbaDatabase -SqlInstance w2016base\sql2017 | Out-GridView

## Restore them to a different instance
Restore-DbaDatabase -SqlInstance w2016base\SQL2017 -Path '\\vmware-host\Shared Folders\SQL_DATA\SQLSaturday' -DestinationDataDirectory C:\SQL_DATA\2017\Data -DestinationLogDirectory C:\SQL_DATA\2017\Log -WithReplace

# Cleanup
Remove-DbaDatabase -SqlInstance w2016base\SQL2017 -Databases AdventureWorks2014, AdventureWorksDW2014, AdventureWorksLT2008, DBA_Metrics, DBCC

# What databases are available
Get-DbaDatabase -SqlInstance w2016base\sql2017 | Out-GridView

## So you can see there are a lot of backup and restore and copy commands available. I urge you to explore them
## Use Find-DbaCommand
## Take a look at the community presentations 

Start-Process 'https://github.com/sqlcollaborative/community-presentations'

#endregion


#region Getting and testing
## Lets look at how easy it is to get information about one or many sql server instances from the command line with one line of code

## What are my default paths ?

$InstanceList = @(
                'WIN-2012-SQL01\SQL2008',
                'WIN-2012-SQL01\SQL2008R2',
                'WIN-2012-SQL01\SQL2012',
                'WIN-2012-SQL01\SQL2014',
                'W2016BASE',
                'W2016BASE\SQL2017'
                )


$ComputerList = @('WIN-2012-SQL01','W2016BASE')

Get-DbaSqlService -ComputerName $ComputerList | Out-GridView


Get-DbaDefaultPath -SqlInstance $InstanceList | Out-GridView

Get-DbaDiskSpace -ComputerName $ComputerList | Out-GridView


## I want to read my logs too

Get-DbaAgentLog -SqlInstance $InstanceList | Out-GridView

Get-DbaSqlLog -SqlInstance $InstanceList | Out-GridView


# Who Is Active
Find-DbaCommand -Pattern WhoIsActive | Out-GridView

Invoke-DbaWhoisActive -SqlInstance $InstanceList -ShowSleepingSpids 2  -FindBlockLeaders | Out-GridView

Install-DbaWhoIsActive -SqlInstance $InstanceList -LocalFile 'C:\SQLSaturday\Brisbane\who_is_active_v11_30.sql' -Database master

## Performance Statistics
Get-DbaWaitStatistic -SqlInstance $InstanceList | Out-GridView

Get-DbaTopResourceUsage -SqlInstance w2016base\SQL2017 -Type CPU | Out-GridView
Get-DbaTopResourceUsage -SqlInstance w2016base\SQL2017 -Type IO | Out-GridView

# Execution Plans
Get-DbaExecutionPlan -SqlInstance w2016base\SQL2017 | Out-GridView

# Open Transactions
Get-DbaOpenTransaction -SqlInstance w2016base\SQL2017 | Out-GridView



## My Favourite
## How do you get the last DBCC CheckDB date ? DBCC DBINFO([DBA-Admin]) WITH TABLERESULTS

## So How long to get the Last Known Good Check DB Date for many databases on many instances?

## This long for 6 instances and 32 databases :-)

Measure-Command {Get-DbaLastGoodCheckDb -SqlInstance $InstanceList | Out-GridView}



#region uber nerdy transaction log from Stuart Moore :-) 
#wanna read a transaction log - Live ??
Read-DbaTransactionLog -SqlInstance W2016Base\SQL2017 -Database dbareports |ogv

# Maintains list of Current Builds
Test-DbaSqlBuild -Build "13.0.5026" -Latest
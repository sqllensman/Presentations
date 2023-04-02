# SOD-Checks.ps1
<#
 .SYNOPSIS
  This PowerShell script is to collect data used for Start of Day (SOD) Checks.

 .DESCRIPTION
  Script to collectinformation required for Start of Day Health checks. Replace SSIS package that 

 .PARAMETER MonitorServer
  Computer name that hold configuration and monitoring information for Estate

 .PARAMETER MonitorDB
  Database name that hold configuration and monitoring information for Estate

 .PARAMETER LoggingPath
  Path used to write the log file

 .INPUTS
  System.String

 .OUTPUTS
  System.String

 .NOTES
  This collects data across the entire SQL Server estate
  Relies up
    dbatools
    PSFramework
    A database that contains a list of SQL Server hosts and SQL Server instances
    Requires running under an account that has access to eacjh machine
 
#>

[CmdletBinding()]

PARAM ( 
    [string]$MonitorServer = 'Servername',
    [string]$MonitorDB = 'DBA_Reports',
    [string]$LoggingPath = 'D:\PowerShell\Logs'
)

Begin {

    Import-Module dbatools
    Import-Module PSFramework

    $FilePath = Join-Path -Path $LoggingPath -ChildPath "SODChecks-%Date%.json"

    $paramSetPSFLoggingProvider = @{
        Name         = 'logfile'
        InstanceName = 'MyTask'
        FilePath     = $FilePath
        FileType     = 'Json'
        Headers      = 'ComputerName', 'Level', 'Line', 'Message', 'Tags', 'TargetObject', 'Timestamp','Username', 'Data'
        Enabled      = $true
    }
    Set-PSFLoggingProvider @paramSetPSFLoggingProvider

    try {
        $MonitoringServer = Connect-DbaInstance -SqlInstance $MonitorServer -Database $MonitorDB
    } catch {
        Write-PSFMessage -Level Error -Message "Unable to connect to $MonitorServer" -Target $ComputerName -Tag 'SOD Checks-Starting'        
    }

    $ReadingDate = Get-Date   
    
    $CollectWeeklyData = ($ReadingDate.DayOfWeek -eq 'Saturday')
     
} # End Begin block

Process {
    # Start of PROCESS block.
    Write-PSFMessage -Level InternalComment -Message "Entering the PROCESS block [$($MyInvocation.MyCommand.CommandType): $($MyInvocation.MyCommand.Name)]."

    #SQL Server - Host Level Information 
    Write-PSFMessage -Level InternalComment -Message "Processing SQL Server - Host Level Information"  
    $ServerListQuery = 'SELECT [ComputerName],[ServerType] FROM [DBA_Reports].[dbinfo].[vw_listActiveComputers]'
    $ServerList = Invoke-DbaQuery -SqlInstance $MonitorServer -Database $MonitorDB -Query $ServerListQuery -As DataTable
    
    $TruncateTable = $true
    foreach($Computer in $ServerList) {
        if(Test-Connection -ComputerName $computer.ComputerName -Count 1 -Quiet) {
            $ServiceInfo = Get-DbaService -ComputerName $computer.ComputerName -AdvancedProperties:$AdvancedProperties | Select @{Name="ReadingDate";expression={$ReadingDate}}, ComputerName, HostName, PSComputerName, InstanceName, ServiceName, ServiceType, StartMode, State, SQLServiceType, DisplayName, Description, StartName, BinaryPath, Version, SPLevel, SkuName, Clustered, VSName
            Write-DbaDataTable -SqlInstance  $MonitoringServer -Database $MonitorDB -InputObject $ServiceInfo -Schema 'Stage' -Table 'DbaService' -Truncate:$TruncateTable

            $DiskInfo = Get-DbaDiskSpace -ComputerName $computer.ComputerName | Select ComputerName, @{Name="ReadingDate";expression={$ReadingDate}}, Name, Label,SizeInGB, FreeInGB, PercentFree
            Write-DbaDataTable -SqlInstance  $MonitoringServer -Database $MonitorDB -InputObject $DiskInfo -Schema 'Stage' -Table 'DbaDiskSpace' -Truncate:$TruncateTable

        } else {
            $GetError = Test-NetConnection -ComputerName $computer.ComputerName | Select @{Name="ReadingDate";expression={$ReadingDate}}, ComputerName, RemoteAddress, PingSucceeded
            Write-DbaDataTable -SqlInstance  $MonitoringServer -Database $MonitorDB -InputObject $GetError -Schema 'Stage' -Table 'NetConnectionError'
        }

        if($CollectWeeklyData) {

            $ComputerSystemInfo = Get-DbaComputerSystem -ComputerName $computer.ComputerName
            $OperatingSystemInfo = Get-DbaOperatingSystem -ComputerName $computer.ComputerName -WarningAction SilentlyContinue

            $HostData = [PSCustomObject]@{
                ComputerName = $computer.ComputerName
                ReadingDate = $ReadingDate            
                Domain = $ComputerSystemInfo.Domain
                Manufacturer = $ComputerSystemInfo.Manufacturer
                Model = $ComputerSystemInfo.Model
                SystemType = $ComputerSystemInfo.SystemType
                NumberLogicalProcessors = $ComputerSystemInfo.NumberLogicalProcessors
                NumberProcessors = $ComputerSystemInfo.NumberProcessors
                IsHyperThreading = $ComputerSystemInfo.IsHyperThreading
                TotalPhysicalMemory = [math]::Round($ComputerSystemInfo.TotalPhysicalMemory.Gigabyte,0)
                IsDaylightSavingsTime = $ComputerSystemInfo.IsDaylightSavingsTime
                DaylightInEffect = $ComputerSystemInfo.DaylightInEffect
                DnsHostName = $ComputerSystemInfo.DnsHostName
                PendingReboot = $ComputerSystemInfo.PendingReboot
                OSManufacturer = $OperatingSystemInfo.Manufacturer 
                OSArchitecture = $OperatingSystemInfo.Architecture
                OSVersion = $OperatingSystemInfo.Version
                OSName = $OperatingSystemInfo.OSVersion 
                SPVersion = $OperatingSystemInfo.SPVersion
                InstallDate = $OperatingSystemInfo.InstallDate
                LastBootTime = $OperatingSystemInfo.LastBootTime
                LocalDateTime = $OperatingSystemInfo.LocalDateTime
                TimeZone = $OperatingSystemInfo.TimeZone
                TimeZoneStandard = $OperatingSystemInfo.TimeZoneStandard
                TimeZoneDaylight = $OperatingSystemInfo.TimeZoneDaylight
                TotalVisibleMemory = [math]::Round($OperatingSystemInfo.TotalVisibleMemory.Gigabyte,0)
                ActivePowerPlan = $OperatingSystemInfo.ActivePowerPlan
                CountryCode = $OperatingSystemInfo.CountryCode
                IsWsfc = $OperatingSystemInfo.IsWsfc
            }      
            Write-DbaDataTable -SqlInstance  $MonitorServer -Database $MonitorDB -InputObject $HostData -Schema 'Stage' -Table 'ComputerInfo' -Truncate:$TruncateTable


        }
        $TruncateTable = $false
    } #End Host Level

    #SQL Server - Instance Level Information 
    Write-PSFMessage -Level InternalComment -Message "Processing SQL Server - Instance Level Information"

    $MonitorQuery = 'SELECT [serverID], [hostName], [fullInstanceName],[IsProduction],[InstanceType] FROM [dbinfo].[vw_ActiveInstances]'
    $InstanceList = Invoke-DbaQuery -SqlInstance $MonitoringServer -Database $MonitorDB -Query $MonitorQuery -as DataTable
    $TruncateTable = $true

    foreach($sqlInstance in  $InstanceList) {
        $ServerId = $sqlInstance.serverID
        $HostName = $sqlInstance.HostName	
        $fullInstanceName = $sqlInstance.fullInstanceName

        #Test Connection
        $ConTestData = Test-DbaConnection -SqlInstance $sqlInstance.fullInstanceName
    
        #Skip if not found
        if($Null -eq $ConTestData) {
            $DbaConnectionData = [PSCustomObject]@{
                serverID = $sqlInstance.serverID
                ReadingDate = $ReadingDate            
                SqlInstance = $sqlInstance.fullInstanceName           
                SqlVersion = $Null
                ConnectingAsUser = $Null
                ConnectSuccess = 0
                AuthType = $Null
                AuthScheme = $Null
                TcpPort = $Null 
                IPAddress = $Null            
                NetBiosName = $Null
                IsPingable = $Null
            }                 
        } else {
           
            # Check for failed TCP Port Check
            if (($ConTestData.TcpPort.GetType()).Name -eq 'ErrorRecord') {
                $TcpPort = -1
            } else {
                $TcpPort = $ConTestData.TcpPort
            }    
            $DbaConnectionData = [PSCustomObject]@{
                serverID = $sqlInstance.serverID
                ReadingDate = $ReadingDate            
                SqlInstance = $ConTestData.SqlInstance            
                SqlVersion = $ConTestData.SqlVersion
                ConnectingAsUser = $ConTestData.ConnectingAsUser
                ConnectSuccess = $ConTestData.ConnectSuccess
                AuthType = $ConTestData.AuthType
                AuthScheme = $ConTestData.AuthScheme
                TcpPort = $TcpPort 
                IPAddress = $ConTestData.IPAddress            
                NetBiosName = $ConTestData.NetBiosName
                IsPingable = $ConTestData.IsPingable                                   
            }
        }
        Write-DbaDataTable -SqlInstance  $MonitorServer -Database $MonitorDB -InputObject $DbaConnectionData -Schema 'dbinfo' -Table 'sql_servers_Check' -Truncate:$TruncateTable

        #Skip if not found
        if($ConTestData.ConnectSuccess -eq 0) {Continue}

        # Get Instance level Information
        $Instance = Connect-DbaInstance -SqlInstance $sqlInstance.fullInstanceName -Database master -EncryptConnection -TrustServerCertificate

$SQLLogSpaceQuery = "
SELECT
    '$HostName' as HostName,
    '$fullInstanceName' as fullInstanceName,
	dbs.name AS [Database Name], 
	dbs.database_id AS [Database ID], CONVERT(DECIMAL(18, 2), dopc1.cntr_value / 1024.0) AS [Log Size (MB)], 
	CONVERT(DECIMAL(18, 2), dopc.cntr_value / 1024.0) AS [Log Used (MB)], 
    CONVERT(DECIMAL(18, 2), dopc1.cntr_value / 1024.0) - CONVERT(DECIMAL(18, 2), dopc.cntr_value / 1024.0) AS [Log Free Space Left (MB)], 
	CAST(CAST(dopc.cntr_value AS FLOAT) / CAST(dopc1.cntr_value AS FLOAT) AS DECIMAL(18, 2)) * 100 AS [Log space Used (%)], 
	dbs.recovery_model_desc AS [Recovery Model], 
	dbs.state_desc AS [Database State], 
	dbs.log_reuse_wait_desc AS [Log Reuse Wait Description]
FROM sys.databases AS dbs WITH (NOLOCK) 
INNER JOIN sys.dm_os_performance_counters AS dopc WITH (NOLOCK) 
	ON dbs.name = dopc.instance_name 
INNER JOIN sys.dm_os_performance_counters AS dopc1 WITH (NOLOCK) 
	ON dbs.name = dopc1.instance_name
WHERE (dopc.counter_name LIKE N'Log File(s) Used Size (KB)%') 
AND (dopc1.counter_name LIKE N'Log File(s) Size (KB)%') 
AND (dopc1.cntr_value > 0)"

        $SQLLogSpace = Invoke-DbaQuery -SqlInstance $Instance -Query $SQLLogSpaceQuery -As DataTable
        Write-DbaDataTable -SqlInstance  $MonitorServer -Database $MonitorDB -InputObject $SQLLogSpace -Schema 'dbinfo' -Table 'sql_log_space' -Truncate:$TruncateTable

        if($CollectWeeklyData) {
            $InstanceData = [PSCustomObject]@{
                serverID = $sqlInstance.serverID
                ReadingDate = $ReadingDate  
                Name = $sqlInstance.fullInstanceName 
                AffinityInfo = $Instance.AffinityInfo.AffinityType
                AuditLevel = $Instance.AuditLevel
                AvailabilityGroups = $Instance.AvailabilityGroups.Count
                BackupDirectory = $Instance.BackupDirectory
                BrowserServiceAccount = $Instance.BrowserServiceAccount
                BrowserStartMode = $Instance.BrowserStartMode
                ClusterName = $Instance.ClusterName
                ClusterQuorumState = $Instance.ClusterQuorumState
                ClusterQuorumType = $Instance.ClusterQuorumType
                Collation = $Instance.Collation
                ComputerName = $Instance.ComputerName
                ComputerNamePhysicalNetBIOS = $Instance.ComputerNamePhysicalNetBIOS        
                Credentials = $Instance.Credentials.Count
                DatabaseEngineEdition = $Instance.DatabaseEngineEdition
                DatabaseEngineType = $Instance.DatabaseEngineType
                Databases = $Instance.Databases.Count        
                DefaultAvailabilityGroupClusterType = $Instance.DefaultAvailabilityGroupClusterType
                DefaultFile = $Instance.DefaultFile
                DefaultLog = $Instance.DefaultLog
                Edition = $Instance.Edition
                Endpoints = $Instance.Endpoints.Count
                ErrorLogPath = $Instance.ErrorLogPath
                FilestreamLevel = $Instance.FilestreamLevel
                FilestreamShareName = $Instance.FilestreamShareName
                HadrManagerStatus = $Instance.HadrManagerStatus
                HostPlatform = $Instance.HostPlatform        
                InstallDataDirectory = $Instance.InstallDataDirectory
                InstallSharedDirectory = $Instance.InstallSharedDirectory
                InstanceName = $Instance.InstanceName
                IsAzure = $Instance.IsAzure
                IsCaseSensitive = $Instance.IsCaseSensitive
                IsClustered = $Instance.IsClustered
                IsFullTextInstalled = $Instance.IsFullTextInstalled
                IsHadrEnabled = $Instance.IsHadrEnabled
                IsMemberOfWsfcCluster = $Instance.IsMemberOfWsfcCluster
                IsPolyBaseInstalled = $Instance.IsPolyBaseInstalled
                IsSingleUser = $Instance.IsSingleUser
                Language = $Instance.Language
                LinkedServers = $Instance.LinkedServers.Count
                LoginMode = $Instance.LoginMode
                Logins = $Instance.Logins.Count
                MasterDBLogPath = $Instance.MasterDBLogPath
                MasterDBPath = $Instance.MasterDBPath
                NamedPipesEnabled = $Instance.NamedPipesEnabled
                PhysicalMemory = $Instance.PhysicalMemory
                Platform = $Instance.Platform
                Processors = $Instance.Processors
                ProductLevel = $Instance.ProductLevel
                ProductUpdateLevel = $Instance.ProductUpdateLevel
                ResourceVersion = $Instance.ResourceVersion
                RootDirectory = $Instance.RootDirectory
                ServerType = $Instance.ServerType
                ServerVersion = $Instance.ServerVersion
                ServiceAccount = $Instance.ServiceAccount
                ServiceName = $Instance.ServiceName
                ServiceStartMode = $Instance.ServiceStartMode
                Status = $Instance.Status        
                TcpEnabled = $Instance.TcpEnabled     
                Version = $Instance.Version                                                    
            }
            Write-DbaDataTable -SqlInstance  $MonitorServer -Database $MonitorDB -InputObject $InstanceData -Schema 'stage' -Table 'SqlInstanceInfo' -Truncate:$TruncateTable

            $InstanceConfig = [PSCustomObject]@{
                serverID = $sqlInstance.serverID
                ReadingDate = $ReadingDate  
                Name = $sqlInstance.fullInstanceName
                AdHocDistributedQueriesEnabled = $Instance.Configuration.AdHocDistributedQueriesEnabled.ConfigValue
                AgentXPsEnabled = $Instance.Configuration.AgentXPsEnabled.ConfigValue
                BlockedProcessThreshold = $Instance.Configuration.BlockedProcessThreshold.ConfigValue
                CrossDBOwnershipChaining = $Instance.Configuration.CrossDBOwnershipChaining.ConfigValue
                DatabaseMailEnabled = $Instance.Configuration.DatabaseMailEnabled.ConfigValue
                DefaultBackupChecksum = $Instance.Configuration.DefaultBackupChecksum.ConfigValue
                DefaultBackupCompression = $Instance.Configuration.DefaultBackupCompression.ConfigValue
                DefaultTraceEnabled = $Instance.Configuration.DefaultTraceEnabled.ConfigValue
                FilestreamAccessLevel = $Instance.Configuration.FilestreamAccessLevel.ConfigValue
                FillFactor = $Instance.Configuration.FillFactor.ConfigValue
                IsSqlClrEnabled = $Instance.Configuration.IsSqlClrEnabled.ConfigValue
                MaxServerMemory = $Instance.Configuration.MaxServerMemory.ConfigValue
                MinServerMemory = $Instance.Configuration.MinServerMemory.ConfigValue
                NestedTriggers = $Instance.Configuration.NestedTriggers.ConfigValue
                OptimizeAdhocWorkloads = $Instance.Configuration.OptimizeAdhocWorkloads.ConfigValue
                RemoteAccess = $Instance.Configuration.RemoteAccess.ConfigValue
                RemoteDacConnectionsEnabled = $Instance.Configuration.RemoteDacConnectionsEnabled.ConfigValue
                ReplicationXPsEnabled = $Instance.Configuration.ReplicationXPsEnabled.ConfigValue
                XPCmdShellEnabled = $Instance.Configuration.XPCmdShellEnabled.ConfigValue
            }
                
            Write-DbaDataTable -SqlInstance  $MonitorServer -Database $MonitorDB -InputObject $InstanceConfig -Schema 'stage' -Table 'SqlInstanceConfig' -Truncate:$TruncateTable

            # Get SQL Agent Information
            $AgentInfo = Get-DbaAgentServer -SqlInstance $Instance
        
            $agentData = [PSCustomObject]@{
                serverID = $sqlInstance.serverID
                ComputerName = $AgentInfo.ComputerName
                SqlInstance = $AgentInfo.SqlInstance
                ReadingDate = $ReadingDate
                AgentLogLevel = $AgentInfo.AgentLogLevel
                ErrorLogFile = $AgentInfo.ErrorLogFile
                MaximumHistoryRows = $AgentInfo.MaximumHistoryRows
                MaximumJobHistoryRows = $AgentInfo.MaximumJobHistoryRows
                ReplaceAlertTokensEnabled = $AgentInfo.ReplaceAlertTokensEnabled            
                ServiceAccount = $AgentInfo.ServiceAccount
                ServiceStartMode = $AgentInfo.ServiceStartMode
                SqlAgentAutoStart = $AgentInfo.SqlAgentAutoStart

                DatabaseMailEnabled = $AgentInfo.Parent.Configuration.DatabaseMailEnabled.RunValue
                AgentMailType = $AgentInfo.AgentMailType 
                DatabaseMailProfile = $AgentInfo.DatabaseMailProfile
                SaveInSentFolder = $AgentInfo.SaveInSentFolder

                FailSafeEmailAddress = $AgentInfo.AlertSystem.FailSafeEmailAddress
                FailSafeOperator = $AgentInfo.AlertSystem.FailSafeOperator
                FailSafePagerAddress = $AgentInfo.AlertSystem.FailSafePagerAddress
                NotificationMethod = $AgentInfo.AlertSystem.NotificationMethod

                Alerts = $AgentInfo.Alerts.Count
                Operators = $AgentInfo.Operators.Count
                Jobs = $AgentInfo.Jobs.Count
                ProxyAccounts = $AgentInfo.ProxyAccounts.Count                        
            }
            Write-DbaDataTable -SqlInstance  $MonitorServer -Database $MonitorDB -InputObject $agentData -Schema 'Stage' -Table 'DbaAgentServer' -Truncate:$TruncateTable
        }
    
        # Get Database Level Detail
        $dbDataArray = @()  
        $dbData = Get-DbaDatabase -SqlInstance $Instance 
    
        foreach($db in $dbData) {
   
            $databaseInfo = [PSCustomObject]@{
                serverID = $sqlInstance.serverID
                ReadingDate = $ReadingDate            
                SqlInstance = $db.SqlInstance
                Name = $db.Name
                CreateDate = $db.CreateDate
                Status = $db.Status
                DatabaseID = $db.ID
                IsAccessible = $db.IsAccessible
                RecoveryModel = $db.RecoveryModel
                Owner = $db.Owner
                LastFullBackup = $db.LastFullBackup
                LastDiffBackup = $db.LastDiffBackup
                LastLogBackup = $db.LastLogBackup
                LogReuseWaitStatus = $db.LogReuseWaitStatus
                SizeMB = $db.SizeMB
                SpaceAvailable = $db.SpaceAvailable
                LogFiles = $db.LogFiles.Count
                FileGroups = $db.FileGroups.Count
                PartitionSchemes = $db.PartitionSchemes.Count
                AcceleratedRecoveryEnabled = $db.AcceleratedRecoveryEnabled
                AutoClose = $db.AutoClose
                AutoCreateStatisticsEnabled = $db.AutoCreateStatisticsEnabled
                AutoShrink = $db.AutoShrink
                AutoUpdateStatisticsAsync = $db.AutoUpdateStatisticsAsync
                AutoUpdateStatisticsEnabled = $db.AutoUpdateStatisticsEnabled
                AvailabilityDatabaseSynchronizationState = $db.AvailabilityDatabaseSynchronizationState
                AvailabilityGroupName = $db.AvailabilityGroupName 
                BrokerEnabled = $db.BrokerEnabled
                CaseSensitive = $db.CaseSensitive
                ChangeTrackingEnabled = $db.ChangeTrackingEnabled
                Collation = $db.Collation            
                Compatibility = $db.Compatibility
                DatabaseSnapshotBaseName = $db.DatabaseSnapshotBaseName
                DelayedDurability = $db.DelayedDurability
                Encrypted = $db.Encrypted
                EncryptionEnabled = $db.EncryptionEnabled
                HasDatabaseEncryptionKey = $db.HasDatabaseEncryptionKey
                HasMemoryOptimizedObjects = $db.HasMemoryOptimizedObjects
                IsSystemObject = $db.IsSystemObject
                IsUpdateable = $db.IsUpdateable
                LastGoodCheckDbTime = $db.LastGoodCheckDbTime
                LegacyCardinalityEstimation = $db.LegacyCardinalityEstimation
                MaxDop = $db.MaxDop
                PageVerify = $db.PageVerify
                ParameterSniffing = $db.ParameterSniffing
                PrimaryFilePath = $db.PrimaryFilePath
                QueryStore_ActualState = $db.QueryStoreOptions.ActualState
                ReplicationOptions = $db.ReplicationOptions                                 
            }
            $dbDataArray+=$databaseInfo
        }
        Write-DbaDataTable -SqlInstance  $MonitorServer -Database $MonitorDB -InputObject $dbDataArray -Schema 'Stage' -Table 'DbaDatabase' -Truncate:$TruncateTable
    
        $Instance = $Null
        $TruncateTable = $false
    } #End Instance Loop

    #SQL Server - Availability Group Information   
    Write-PSFMessage -Level InternalComment -Message "Processing SQL Server - Availability Group Information"

    $AGListQuery = 'SELECT serverID, hostName, fullInstanceName, availabiltyGroup FROM dbinfo.vw_sod_list_avail_groups'
    $AGList = Invoke-DbaQuery -SqlInstance $MonitorServer -Database $MonitorDB -Query $AGListQuery -As DataTable
    $TruncateTable = $true

    foreach($ag in $AGList) {
       $agName = $ag.availabiltyGroup
       $serverID = $ag.serverID

        $AGLatenceyQuery = "
        Select $serverID as serverID,
               CURRENT_TIMESTAMP CaptureTime,
	           DB_NAME(dbrs.database_id) DatabaseName,
	           ag.name  AGName,
	           ar.replica_server_name ReplicaName,
               dbrs.is_local isLocal,
               dbrs.is_primary_replica isPrimary,
               dbrs.synchronization_state_desc synchronization_state,
               dbrs.is_commit_participant IsCommitParticipant,
               dbrs.synchronization_health_desc SynchronizationHealth,
               dbrs.database_state_desc DatabaseState,
               dbrs.is_suspended IsSuspended,
               dbrs.suspend_reason_desc SuspendReason,
               dbrs.recovery_lsn RecoveryLSN,
               dbrs.truncation_lsn TruncationLSN,
               dbrs.last_sent_lsn LastSentLSN,
               dbrs.last_sent_time LastSentTime,
               dbrs.last_received_lsn LastReceivedLSN,
               dbrs.last_received_time LastReceivedTime,
               dbrs.last_hardened_lsn LastHardenedLSN,
               dbrs.last_redone_lsn LastRedoneLSN,
               dbrs.last_redone_time LastRedoneTime,
               dbrs.last_commit_lsn LastCommitLSN,
               dbrs.last_commit_time LastCommitTime,
	           DATEDIFF(SECOND,dbrs.last_commit_time,CURRENT_TIMESTAMP) CommitDelay,
               dbrs.end_of_log_lsn EndOfLogLSN,
               dbrs.log_send_queue_size LogSendQueueSize,
               dbrs.log_send_rate LogSendRate,
               dbrs.redo_queue_size RedoQueueSize,
               dbrs.redo_rate RedoRate,
               dbrs.filestream_send_rate FileStreamSendRate,
               dbrs.low_water_mark_for_ghosts LowWatermarkForGhosts,
               lfu.cntr_value LogKBytesUsed,
	           lft.cntr_value LogKBytesTotal
        From sys.dm_hadr_database_replica_states dbrs
        INNER JOIN sys.availability_replicas ar
	        On ar.replica_id= dbrs.replica_id
        INNER JOIN sys.availability_groups ag
	        ON ag.group_id = dbrs.group_id
        Left Join sys.dm_os_performance_counters lfu 
	        On DB_NAME(database_id) = lfu.instance_name
	        And dbrs.is_local = 1
	        And lfu.counter_name = 'Log File(s) Used Size (KB)'
        Left Join sys.dm_os_performance_counters lft 
	        On lfu.instance_name = lft.instance_name
	        And lft.counter_name = 'Log File(s) Size (KB)'
        WHERE ag.name='$agName'"
           
        $AGLatency = Invoke-DbaQuery -SqlInstance $ag.fullInstanceName -Database 'master' -Query $AGLatenceyQuery  -As DataTable    
        Write-DbaDataTable -SqlInstance  $MonitorServer -Database $MonitorDB -InputObject $AGLatency -Schema 'Stage' -Table 'AGLatency' -Truncate:$TruncateTable

        if($CollectWeeklyData) {
            $Ag = Get-DbaAvailabilityGroup -SqlInstance $ag.fullInstanceName -AvailabilityGroup $agName
            $agObject = [PSCustomObject]@{
                AGName = $Ag.AvailabilityGroup
                AvailabilityGroupListeners = $Ag.AvailabilityGroupListeners[0]
                PrimaryReplica = $Ag.PrimaryReplica
                PrimaryReplicaServerName = $Ag.PrimaryReplicaServerName
                AutomatedBackupPreference = $Ag.AutomatedBackupPreference
                ClusterTypeWithDefault = $Ag.ClusterTypeWithDefault
                DatabaseHealthTrigger = $Ag.DatabaseHealthTrigger
                FailureConditionLevel = $Ag.FailureConditionLevel
                HealthCheckTimeout = $Ag.HealthCheckTimeout
                DtcSupportEnabled = $Ag.DtcSupportEnabled
                ReplicaCount = $Ag.AvailabilityReplicas.Count
            }
            Write-DbaDataTable -SqlInstance  $MonitorServer -Database $MonitorDB -InputObject $agObject -Schema 'Stage' -Table 'AGGroupData' -Truncate:$TruncateTable

            $agHostArray = @()
            foreach($agHost in $Ag.AvailabilityReplicas) {
                $agHostData = [PSCustomObject]@{
                    AGName = $Ag.AvailabilityGroup
                    ComputerName = $agHost.Name
                    AvailabilityMode = $agHost.AvailabilityMode
                    Role = $agHost.Role
                    ConnectionModeInPrimaryRole = $agHost.ConnectionModeInPrimaryRole
                    ConnectionModeInSecondaryRole = $agHost.ConnectionModeInSecondaryRole
                    ConnectionState = $agHost.ConnectionState
                    MemberState  = $agHost.MemberState 
                    BackupPriority = $agHost.BackupPriority
                    EndpointUrl = $agHost.EndpointUrl
                    FailoverMode = $agHost.FailoverMode
                    QuorumVoteCount = $agHost.QuorumVoteCount
                    ReadonlyRoutingConnectionUrl = $agHost.ReadonlyRoutingConnectionUrl
                    RollupSynchronizationState  = $agHost.RollupSynchronizationState
                    ServerVersion = $agHost.ServerVersion 
                    DatabaseEngineType = $agHost.DatabaseEngineType
                    DatabaseEngineEdition = $agHost.DatabaseEngineEdition
                }
                $agHostArray += $agHostData                                
            }
            Write-DbaDataTable -SqlInstance  $MonitorServer -Database $MonitorDB -InputObject $agHostArray -Schema 'Stage' -Table 'AGHostData' -Truncate:$TruncateTable
        }
        $TruncateTable = $false
    } #End AG Loop
}# End of PROCESS block.

End {
        # Start of END block.
        Write-PSFMessage -Level InternalComment -Message "Entering the END block [$($MyInvocation.MyCommand.CommandType): $($MyInvocation.MyCommand.Name)]."


        # Add additional code here.

} # End of the END Block.
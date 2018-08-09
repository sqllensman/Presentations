#Return 'This is a demo, don''t run the whole thing, fool!!'
#Remove-Module dbatools
Import-Module -Name 'C:\GitHub\dbatools\dbatools.psd1'


$server = 'LensmanSB'
$DatabaseName = 'pubs'
$BasePath = 'C:\Lensman\Output\DatabaseScripts'
$Dir = $BasePath +'\' + $server #+ $(get-date -f yyyy-MM-dd_HH_mm_ss)


# Create Directory if Required
if(!(Test-Path -Path $Dir )){
    New-Item -ItemType directory -Path $Dir
}

#Set Scripting Options
$options = New-DbaScriptingOption    
$options.ScriptSchema = $true
$options.IncludeDatabaseContext  = $true
$options.IncludeHeaders = $false
$Options.NoCommandTerminator = $false
$Options.ScriptBatchTerminator = $true 
$Options.AnsiFile = $true

$Databases = Get-DbaDatabase -SqlInstance $server -Database $DatabaseName   #-ExcludeDatabase master, model, msdb,tempdb

foreach ($db in $Databases) {
    $DirDatabase = $Dir + '\' + $db.Name
    #region Database Scripts
    
    # Build The Required Directories
    if(!(Test-Path -Path $DirDatabase)){
        # Create Directory for Database
        New-Item -ItemType directory -Path $DirDatabase
    }
    $FileName = $DirDatabase+ '\' + $db.Name + '.sql'

    # Generate Scripts    
    Export-DbaScript -InputObject $db -Path $FileName -Encoding UTF8 -ScriptingOptionsObject $options -NoPrefix
    #endregion

    #region Schema Creation
    $Schemas = ($db.Schemas | Where-Object {$_.IsSystemObject -eq $false})
    if ($Schemas.Count -gt 0) {
        #Scripting Options
        $options.IncludeDatabaseContext  = $true
        $Options.IncludeIfNotExists = $true

        $currentPath = $DirDatabase + '\Schemas'
        if(!(Test-Path -Path $currentPath)){
            # Create Directory for Database
            New-Item -ItemType directory -Path $currentPath
        }

        $FileName = $currentPath + '\' + $db.Name + '_Schema.sql'

        # Generate Scripts
        foreach($Schema in $Schemas) {       
            Export-DbaScript -InputObject $Schema -Path $FileName -ScriptingOptionsObject $options -Append -NoPrefix
        } 
    }
    #endregion

    #region Table Creation
    $Tables = $db.Tables
    if ($Tables.Count -gt 0) {
        #Scripting Options
        $options.ColumnStoreIndexes = $true
        $options.ConvertUserDefinedDataTypesToBaseType  = $true
        $options.DriAll  = $true
        $options.IncludeDatabaseContext  = $true
        $Options.IncludeIfNotExists = $false
        $options.Indexes  = $true
        $options.NoFileGroup = $false
        $options.NonClusteredIndexes  = $true
        $options.ScriptBatchTerminator  = $true
        $options.SpatialIndexes  = $true
        $options.XmlIndexes  = $true

        # Create Directory for Scripts
        $currentPath = $DirDatabase + '\Tables'
        if(!(Test-Path -Path $currentPath)){
            # Create Directory for Database
            New-Item -ItemType directory -Path $currentPath
        }
    
        # Generate Scripts
        foreach($Table in $Tables) {
            $FileName = $currentPath + '\' + $Table.Schema + '.' + $Table.Name + '.sql'
            Export-DbaScript -InputObject $Table -Path $FileName -ScriptingOptionsObject $options -NoPrefix
        }
    }
    #endregion

    #region View Creation
    $Views = ($db.Views | Where-Object {$_.IsSystemObject -eq $false})
    if ($Views.Count -gt 0) {
        #Scripting Options
        $options.IncludeDatabaseContext  = $true
        $Options.IncludeIfNotExists = $false
        $options.Indexes  = $true
        $options.NoFileGroup = $false

        # Create Directory for Scripts
        $currentPath = $DirDatabase + '\Views'
        if(!(Test-Path -Path $currentPath)){
            # Create Directory for Database
            New-Item -ItemType directory -Path $currentPath
        }

        # Generate Scripts
        foreach($View in $Views) {
            $FileName = $currentPath + '\' + $View.Schema +'.' + $View.Name + '.sql'
            Export-DbaScript -InputObject $View -Path $FileName -ScriptingOptionsObject $options -NoPrefix
        }
    }
    #endregion
    
    #region Stored Procedure Creation
    $StoredProcedures = ($db.StoredProcedures | Where-Object {$_.IsSystemObject -eq $false})
    if ($StoredProcedures.Count -gt 0) {
        #Scripting Options

        $Options.IncludeIfNotExists = $false


        # Create Directory for Scripts
        $currentPath = $DirDatabase + '\StoredProcedures'
        if(!(Test-Path -Path $currentPath)){
            # Create Directory for Database
            New-Item -ItemType directory -Path $currentPath
        }

        # Generate Scripts
        foreach($sp in $StoredProcedures) {
            $FileName = $currentPath + '\' + $sp.Schema +'.' + $sp.Name + '.sql'
            Export-DbaScript -InputObject $sp -Path $FileName -ScriptingOptionsObject $options -NoPrefix
        }
    }
    #endregion

    #region UserDefinedFunctions Creation
    $UserDefinedFunctions = ($db.UserDefinedFunctions | Where-Object {$_.IsSystemObject -eq $false})
    if ($UserDefinedFunctions.Count -gt 0) {
        #Scripting Options

        # Create Directory for Scripts
        $currentPath = $DirDatabase + '\UserDefinedFunctions'
        if(!(Test-Path -Path $currentPath)){
            # Create Directory for Database
            New-Item -ItemType directory -Path $currentPath
        }

        # Generate Scripts
        foreach($udf in $UserDefinedFunctions) {
            $FileName = $currentPath + '\' + $udf.Schema +'.' + $udf.Name + '.sql'
            Export-DbaScript -InputObject $udf -Path $FileName -ScriptingOptionsObject $options -NoPrefix
        }
    }
    #endregion

    #region UserDefinedDataTypes Creation
    $UserDefinedDataTypes = $db.UserDefinedDataTypes
    if ($UserDefinedDataTypes.Count -gt 0) {
        #Scripting Options
        $options.IncludeDatabaseContext  = $true


        # Create Directory for Scripts
        $currentPath = $DirDatabase + '\UserDefinedDataTypes'
        if(!(Test-Path -Path $currentPath)){
            # Create Directory for Database
            New-Item -ItemType directory -Path $currentPath
        }

        # Generate Scripts
        foreach($uddt in $UserDefinedDataTypes) {
            $FileName = $currentPath + '\' + $uddt.Schema +'.' + $uddt.Name + '.sql'
            Export-DbaScript -InputObject $uddt -Path $FileName -ScriptingOptionsObject $options -NoPrefix
        }
    }
    #endregion

    #region UserDefinedTableTypes Creation
    $UserDefinedTableTypes = $db.UserDefinedTableTypes
    if ($UserDefinedTableTypes.Count -gt 0) {
        #Scripting Options
        $options.IncludeDatabaseContext  = $true


        # Create Directory for Scripts
        $currentPath = $DirDatabase + '\UserDefinedTableTypes'
        if(!(Test-Path -Path $currentPath)){
            # Create Directory for Database
            New-Item -ItemType directory -Path $currentPath
        }

        # Generate Scripts
        foreach($udtt in $UserDefinedTableTypes) {
            $FileName = $currentPath + '\' + $udtt.Schema +'.' + $udtt.Name + '.sql'
            Export-DbaScript -InputObject $udtt -Path $FileName -ScriptingOptionsObject $options -NoPrefix
        }
    }
    #endregion

    #region PartitionFunctions Creation
    $PartitionFunctions = $db.PartitionFunctions
    if ($PartitionFunctions.Count -gt 0) {
        #Scripting Options
        $options.IncludeDatabaseContext  = $true


        # Create Directory for Scripts
        $currentPath = $DirDatabase + '\PartitionFunctions'
        if(!(Test-Path -Path $currentPath)){
            # Create Directory for Database
            New-Item -ItemType directory -Path $currentPath
        }

        # Generate Scripts
        foreach($PartitionFunction in $PartitionFunctions) {
            $FileName = $currentPath + '\' + $PartitionFunction.Schema +'.' + $PartitionFunction.Name + '.sql'
            Export-DbaScript -InputObject $PartitionFunction -Path $FileName -ScriptingOptionsObject $options -NoPrefix
        }
    }
    #endregion

    #region PartitionSchemes Creation
    $PartitionSchemes = $db.PartitionSchemes
    if ($PartitionSchemes.Count -gt 0) {
        #Scripting Options
        $options.IncludeDatabaseContext  = $true


        # Create Directory for Scripts
        $currentPath = $DirDatabase + '\PartitionSchemes'
        if(!(Test-Path -Path $currentPath)){
            # Create Directory for Database
            New-Item -ItemType directory -Path $currentPath
        }

        # Generate Scripts
        foreach($PartitionScheme in $PartitionSchemes) {
            $FileName = $currentPath + '\' + $PartitionScheme.Schema +'.' + $PartitionScheme.Name + '.sql'
            Export-DbaScript -InputObject $PartitionScheme -Path $FileName -ScriptingOptionsObject $options -NoPrefix
        }
    }
    #endregion

    #region Sequences Creation
    $Sequences = $db.Sequences
    if ($Sequences.Count -gt 0) {
        #Scripting Options
        $options.IncludeDatabaseContext  = $true

        # Create Directory for Scripts
        $currentPath = $DirDatabase + '\Sequences'
        if(!(Test-Path -Path $currentPath)){
            # Create Directory for Database
            New-Item -ItemType directory -Path $currentPath
        }

        # Generate Scripts
        foreach($Sequence in $Sequences) {
            $FileName = $currentPath + '\' + $Sequence.Schema +'.' + $Sequence.Name + '.sql'
            Export-DbaScript -InputObject $Sequence -Path $FileName -ScriptingOptionsObject $options -NoPrefix
        }
    }
    #endregion


    #region Assemblies Creation
    $Assemblies = ($db.Assemblies | Where-Object {$_.IsSystemObject -eq $false})
    if ($Assemblies.Count -gt 0) {
        #Scripting Options
        $options.IncludeDatabaseContext  = $true

        # Create Directory for Scripts
        $currentPath = $DirDatabase + '\Assemblies'
        if(!(Test-Path -Path $currentPath)){
            # Create Directory for Database
            New-Item -ItemType directory -Path $currentPath
        }

        # Generate Scripts
        foreach($Assembly in $Assemblies) {
            $FileName = $currentPath + '\' + $Assembly.Schema +'.' + $Assembly.Name + '.sql'
            Export-DbaScript -InputObject $Assembly -Path $FileName -ScriptingOptionsObject $options -NoPrefix
        }
    }
    #endregion

    #region Roles Creation
    $Roles = ($db.Roles | Where-Object {($_.IsFixedRole -eq $false -and $_.Name -ne 'public')})
    if ($Roles.Count -gt 0) {
        #Scripting Options
        $options.IncludeDatabaseContext  = $true
        $Options.IncludeIfNotExists = $true

        # Create Directory for Scripts
        $currentPath = $DirDatabase + '\Roles'
        if(!(Test-Path -Path $currentPath)){
            # Create Directory for Database
            New-Item -ItemType directory -Path $currentPath
        }

        # Generate Scripts
        foreach($Role in $Roles) {
            $FileName = $currentPath + '\' + $Role.Name + '.sql'
            Export-DbaScript -InputObject $Role -Path $FileName -ScriptingOptionsObject $options -NoPrefix
        }
    }
    #endregion

    #region Synonyms Creation
    $Synonyms = $db.Synonyms
    if ($Synonyms.Count -gt 0) {
        #Scripting Options
        $options.IncludeDatabaseContext  = $true

        # Create Directory for Scripts
        $currentPath = $DirDatabase + '\Synonyms'
        if(!(Test-Path -Path $currentPath)){
            # Create Directory for Database
            New-Item -ItemType directory -Path $currentPath
        }

        # Generate Scripts
        foreach($Synonym in $Synonyms) {
            $FileName = $currentPath + '\' + $Synonym.Schema +'.' + $Synonym.Name + '.sql'
            Export-DbaScript -InputObject $Synonym -Path $FileName -ScriptingOptionsObject $options -NoPrefix
        }
    }
    #endregion

    #region UserDefinedAggregates Creation
    $UserDefinedAggregates = $db.UserDefinedAggregates
    if ($UserDefinedAggregates.Count -gt 0) {
        #Scripting Options
        $options.IncludeDatabaseContext  = $true


        # Create Directory for Scripts
        $currentPath = $DirDatabase + '\UserDefinedAggregates'
        if(!(Test-Path -Path $currentPath)){
            # Create Directory for Database
            New-Item -ItemType directory -Path $currentPath
        }

        # Generate Scripts
        foreach($uda in $UserDefinedAggregates) {
            $FileName = $currentPath + '\' + $uda.Schema +'.' + $uda.Name + '.sql'
            Export-DbaScript -InputObject $uda -Path $FileName -ScriptingOptionsObject $options -NoPrefix
        }
    }
    #endregion

    #region UserDefinedTypes Creation
    $UserDefinedTypes = $db.UserDefinedTypes
    if ($UserDefinedTypes.Count -gt 0) {
        #Scripting Options
        $options.IncludeDatabaseContext  = $true


        # Create Directory for Scripts
        $currentPath = $DirDatabase + '\UserDefinedTypes'
        if(!(Test-Path -Path $currentPath)){
            # Create Directory for Database
            New-Item -ItemType directory -Path $currentPath
        }

        # Generate Scripts
        foreach($udt in $UserDefinedTypes) {
            $FileName = $currentPath + '\' + $udt.Schema +'.' + $udt.Name + '.sql'
            Export-DbaScript -InputObject $udt -Path $FileName -ScriptingOptionsObject $options -NoPrefix
        }
    }
    #endregion

    #region Users Creation
    $Users = ($db.Users | Where-Object {$_.IsSystemObject -eq $false})
    if ($Users.Count -gt 0) {
        #Scripting Options
        $options.IncludeDatabaseContext  = $true


        # Create Directory for Scripts
        $currentPath = $DirDatabase + '\Users'
        if(!(Test-Path -Path $currentPath)){
            # Create Directory for Database
            New-Item -ItemType directory -Path $currentPath
        }

        # Generate Scripts
        foreach($User in $Users) {
            $UserName = $User.Name -replace '[\\\/\:\.]','$'
            $FileName = $currentPath + '\' + $UserName + '.sql'

            Export-DbaScript -InputObject $User -Path $FileName -ScriptingOptionsObject $options -NoPrefix
        }
    }
    #endregion

    # Add files to git repository 
    set-location $BasePath
    if(!(Test-Path -Path $BasePath\.git)){
        git init    
    } 
    else {
        git status
    }

    git add .
    git commit -am "Add all Files to Git Repository"


}


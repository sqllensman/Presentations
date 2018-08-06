#Return 'This is a demo, don''t run the whole thing, fool!!'
#Remove-Module dbatools




$server = 'LensmanSB'
$BasePath = 'C:\Lensman\Output\DatabaseScripts'
$Dir = $BasePath +'\' + $server #+ $(get-date -f yyyy-MM-dd_HH_mm_ss)

# Create Directory if Required
if(!(Test-Path -Path $Dir )){
    New-Item -ItemType directory -Path $Dir
}

#Set Scripting Options
$options = New-DbaScriptingOption    
$options.ScriptSchema = $true

$Databases = Get-DbaDatabase -SqlInstance $server -Database WideWorldImporters   #-ExcludeDatabase master, model, msdb,tempdb

foreach ($db in $Databases) {
    #region Script out Database Create Scripts
    
    $DirDatabase = $Dir + '\' + $db.Name
    # Build The Required Directories
    if(!(Test-Path -Path $DirDatabase)){
        # Create Directory for Database
        New-Item -ItemType directory -Path $DirDatabase
    }

    # Create Database Scripts
    $FileName = $DirDatabase+ '\' + $db.Name + '.sql'
    Export-DbaScript -InputObject $db -Path $FileName -Encoding UTF8 -ScriptingOptionsObject $options
    #endregion

    #region Script out Schema Creation
    $Schemas = $db.Schemas
    $currentPath = $DirDatabase + '\Schemas'
    if(!(Test-Path -Path $currentPath)){
        # Create Directory for Database
        New-Item -ItemType directory -Path $currentPath
    }

    $FileName = $currentPath + '\' + $db.Name + '_Schema.sql'
    $options.IncludeDatabaseContext  = $true
    $Options.IncludeIfNotExists = $true

    
    foreach($Schema in $Schemas) {
        if (!$Schema.IsSystemObject) {         
            Export-DbaScript -InputObject $Schema -Path $FileName -ScriptingOptionsObject $options -Append
        }
    } 
    #endregion

    #region Script out Table Creation
    $Tables = $db.Tables

    #Table Scripting Options
    #$options.ClusteredIndexes = $true
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

    # Create Directory for Table Scripts
    $currentPath = $DirDatabase + '\tables'
    if(!(Test-Path -Path $currentPath)){
        # Create Directory for Database
        New-Item -ItemType directory -Path $currentPath
    }
    
    foreach($Table in $Tables) {
        $FileName = $currentPath + '\' + $Table.Schema + '.' + $Table.Name + '.sql'
        Export-DbaScript -InputObject $Table -Path $FileName -ScriptingOptionsObject $options
    }
    #endregion

    #region Script out View Creation
    $Views = $db.Views

    #Table Scripting Options
    $options.ClusteredIndexes = $true
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

    # Create Directory for Table Scripts
    $currentPath = $DirDatabase + '\views'
    if(!(Test-Path -Path $currentPath)){
        # Create Directory for Database
        New-Item -ItemType directory -Path $currentPath
    }
    
    foreach($View in $Views) {
        if (!$View.IsSystemObject) { 
            $FileName = $currentPath + '\' + $View.Schema +'.' + $View.Name + '.sql'
            Export-DbaScript -InputObject $View -Path $FileName -ScriptingOptionsObject $options
        }
    }
    #endregion
}





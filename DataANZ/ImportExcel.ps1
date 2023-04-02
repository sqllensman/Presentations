

Import-Module ImportExcel

Get-Command -Module ImportExcel | Select Name | Format-Table

# Import Data 
$xlsxPath = '/Volumes/Lensman500/Melbourne/Samples/Backups.xlsx'
$data = Import-Excel -Path $xlsxPath
$data | Select * | Format-List
$data | Out-GridHtml

$ExamplePath = '/Users/patrickflynn/Melbourne'
Remove-Item "$EXAMPLEPATH\hyperlink.xlsx" -ErrorAction SilentlyContinue

$(
    New-PSItem '=Hyperlink("https://github.com/dfinke/ImportExcel","Doug Finke Github")' @("Link")
    New-PSItem '=Hyperlink("http://blogs.msdn.com/b/powershell/","PowerShell Blog")'
    New-PSItem '=Hyperlink("https://4sysops.com/archives/export-and-import-to-and-from-excel-with-the-powershell-module-importexcel//","Examples")'

) | Export-Excel "$ExamplePath\hyperlink.xlsx" -AutoSize -Show

# remove our example file
$path = "$EXAMPLEPATH\Example1.xlsx"
Remove-Item -Path $path -ErrorAction SilentlyContinue

# Create some data
$data = @"
Name,ID,Quarter1,Quarter2,Quarter3,Quarter4
Greef Karga,0001,1100,1200,1300,1400
Kuiil,0002,1000,1000,1000,0
IG-11,0003,1200,1200,1400,1500
Cara Dune,0004,800,700,700,300
Mayfeld,0005,400,500,600,200
Din Djarin,0006,2000,2200,2100,500
"@ | ConvertFrom-Csv

# Create our various Excel parameters
$params = @{
    # Spreadsheet Properties
    Path                 = $path
    AutoSize             = $true
    AutoFilter           = $true
    BoldTopRow           = $true
    FreezeTopRow         = $true
    WorksheetName        = 'Data'
    PassThru             = $true
}        

# Create the Excel file
$ExcelPackage = $data | Export-Excel @params
$WorkSheet = $ExcelPackage.Data

# Apply some basic formatting
Set-ExcelRange -Worksheet $WorkSheet -Range "A1:F1" -BackgroundColor Black -FontColor White
Set-ExcelRange -Worksheet $WorkSheet -Range "B1:B7" -HorizontalAlignment Center
Set-ExcelRange -Worksheet $WorkSheet -Range "C2:F7" -NumberFormat 'Currency'

Close-ExcelPackage -ExcelPackage $ExcelPackage


# remove our example file
$path = "$EXAMPLEPATH\Example2.xlsx"
Remove-Item -Path $path -ErrorAction SilentlyContinue

# Create some data
$data = @"
Name,ID,Quarter1,Quarter2,Quarter3,Quarter4
Greef Karga,0001,1100,1200,1300,1400
Kuiil,0002,1000,1000,1000,0
IG-11,0003,1200,1200,1400,1500
Cara Dune,0004,800,700,700,300
Mayfeld,0005,400,500,600,200
Din Djarin,0006,2000,2200,2100,500
"@ | ConvertFrom-Csv

# Create our IconSet
$params = @{
    Range             = "G2:G7"
    ConditionalFormat = 'ThreeIconSet' 
    IconType          = 'Arrows'
}
$IconSet = New-ConditionalFormattingIconSet @params

# Create our various Excel parameters
$params = @{
    # Spreadsheet Properties
    Path                 = $path
    AutoSize             = $true
    AutoFilter           = $true
    BoldTopRow           = $true
    FreezeTopRow         = $true
    WorksheetName        = 'Data'
    ConditionalFormat    = $IconSet
    PassThru             = $true

}        

# Create the Excel file
$ExcelPackage = $data | Export-Excel @params
$WorkSheet = $ExcelPackage.Data

# Apply some basic formatting
Set-ExcelRange -Worksheet $WorkSheet -Range "A1:F1" -BackgroundColor Black -FontColor White
Set-ExcelRange -Worksheet $WorkSheet -Range "B1:B7" -HorizontalAlignment Center
Set-ExcelRange -Worksheet $WorkSheet -Range "C2:F7" -NumberFormat 'Currency'

# Let's add a "Total" column and format it
$params = @{
    Worksheet       = $WorkSheet
    Range           = "G1" 
    Value           = 'Total'
    Bold            = $true 
    BackgroundColor = 'Black'
    FontColor       = 'White'
}
Set-ExcelRange @params

# Fill the Total column
2..7 | ForEach-Object {
    $sum = "=SUM(C{0}:F{0})" -f $PSItem
    Set-ExcelRange -Worksheet $WorkSheet -Range "G$_" -Formula $sum 
}

# Format the new column as curraency
$params = @{
    Worksheet           = $WorkSheet
    Range               = "G:G"
    NumberFormat        = 'Currency'
    Width               = 15
    HorizontalAlignment = 'Center'
}
Set-ExcelRange @params 

# Add conditional formatting
$params = @{
    Worksheet       = $WorkSheet
    Address         = 'C2:F7'
    RuleType        = 'LessThan'
    ConditionValue  = 1000
    ForegroundColor = 'Red'
}
Add-ConditionalFormatting @params

$params = @{
    Worksheet       = $WorkSheet
    Address         = 'C2:F7'
    RuleType        = 'GreaterThanOrEqual'
    ConditionValue  = 1000
    ForegroundColor = 'Green'
}
Add-ConditionalFormatting @params 

Export-Excel -ExcelPackage $ExcelPackage -Show


#ChartDefinition cmdlet. Here is our example:
# remove our example file
$path = "$ExamplePath/Example3.xlsx"
Remove-Item -Path $path -ErrorAction SilentlyContinue

# Create some data
$data = @"
Name,ID,Quarter1,Quarter2,Quarter3,Quarter4
Greef Karga,0001,1100,1200,1300,1400
Kuiil,0002,1000,1000,1000,0
IG-11,0003,1200,1200,1400,1500
Cara Dune,0004,800,700,700,300
Mayfeld,0005,400,500,600,200
Din Djarin,0006,2000,2200,2100,500
"@ | ConvertFrom-Csv

# Create our IconSet
$params = @{
    Range             = "G2:G7"
    ConditionalFormat = 'ThreeIconSet' 
    IconType          = 'Arrows'
}
$IconSet = New-ConditionalFormattingIconSet @params

# Create our various Excel parameters
$params = @{
    # Spreadsheet Properties
    Path                 = $path
    AutoSize             = $true
    AutoFilter           = $true
    BoldTopRow           = $true
    FreezeTopRow         = $true
    WorksheetName        = 'Data'
    ConditionalFormat    = $IconSet
    PassThru             = $true

}        

# Create the Excel file
$ExcelPackage = $data | Export-Excel @params
$WorkSheet = $ExcelPackage.Data

# Apply some basic formatting
Set-ExcelRange -Worksheet $WorkSheet -Range "A1:F1" -BackgroundColor Black -FontColor White
Set-ExcelRange -Worksheet $WorkSheet -Range "B1:B7" -HorizontalAlignment Center
Set-ExcelRange -Worksheet $WorkSheet -Range "C2:F7" -NumberFormat 'Currency'

# Let's add a "Total" column and format it
$params = @{
    Worksheet       = $WorkSheet
    Range           = "G1" 
    Value           = 'Total'
    Bold            = $true 
    BackgroundColor = 'Black'
    FontColor       = 'White'
}
Set-ExcelRange @params

# Fill the Total column
2..7 | ForEach-Object {
    $sum = "=SUM(C{0}:F{0})" -f $PSItem
    Set-ExcelRange -Worksheet $WorkSheet -Range "G$_" -Formula $sum 
}

# Format the new column as curraency
$params = @{
    Worksheet           = $WorkSheet
    Range               = "G:G"
    NumberFormat        = 'Currency'
    Width               = 15
    HorizontalAlignment = 'Center'
}
Set-ExcelRange @params 

# Add conditional formatting
$params = @{
    Worksheet       = $WorkSheet
    Address         = 'C2:F7'
    RuleType        = 'LessThan'
    ConditionValue  = 1000
    ForegroundColor = 'Red'
}
Add-ConditionalFormatting @params

$params = @{
    Worksheet       = $WorkSheet
    Address         = 'C2:F7'
    RuleType        = 'GreaterThanOrEqual'
    ConditionValue  = 1000
    ForegroundColor = 'Green'
}
Add-ConditionalFormatting @params 

# Create our chart parameters
$chartDefinition = @{
    YRange   = 'Total'
    XRange   = 'Name'
    Title    = 'Character Sales'
    Column   = 0
    Row      = 8
    NoLegend = $true
    Height   = 225
}
$Chart = New-ExcelChartDefinition  @chartDefinition 

$params = @{
    ExcelPackage         = $ExcelPackage
    ExcelChartDefinition = $chart
    WorksheetName        = $WorkSheet
    AutoNameRange        = $true
    Show                 = $true 
}
Export-Excel @params
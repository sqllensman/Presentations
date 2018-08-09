DECLARE @ComputerName sysname = N'LENSMANSB'
DECLARE @PowerShell nvarchar(200) = N'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -noprofile '
DECLARE @cmd nvarchar(2000)
DECLARE @XML_as_String VARCHAR(MAX)
DECLARE @Result XML

SET NOCOUNT ON
SET @cmd = @PowerShell + '-Command "Get-DbaDiskSpace -ComputerName "' + @ComputerName + '" | ConvertTo-XML -As string"'

--create a table variable for the data to go into, preserving the order of insertion
DECLARE @XML TABLE (TheXML VARCHAR(2000), theOrder INT IDENTITY(1,1) PRIMARY KEY)
--insert the XML into the table, line by line
INSERT INTO @XML(TheXML)
exec xp_cmdshell @cmd

--now assemble the XML as a string in the correct order
SELECT @XML_as_String=COALESCE(@XML_as_String,'') + theXML 
  FROM @XML 
  WHERE theXML IS NOT NULL 
  ORDER BY theOrder 

SELECT @Result = Cast(@XML_as_String as XML);

Declare @GB as Decimal(20,2) = Power(2,30);

With XMLData(Attribute, Value, DataId)  as
(
SELECT --shred the XML into an EAV table along with the number of the object in the collection
	[property].value('@Name', 'Varchar(100)') AS [Attribute], 
	[property].value('(./text())[1]', 'Varchar(100)') AS [Value],
    DENSE_RANK() OVER (ORDER BY [object]) AS unique_object
FROM @Result.nodes('Objects/Object') AS b ([object])
CROSS APPLY b.object.nodes('./Property') AS c (property)
) 
Select 
	ComputerName, 
	Name,
	Label,
	Capacity, 
	Free, 
	PercentFree
from XMLData
pivot (Max (Value) for Attribute in ([ComputerName],[Name], [Label], [Capacity], [Free], [PercentFree])) as PivotValues
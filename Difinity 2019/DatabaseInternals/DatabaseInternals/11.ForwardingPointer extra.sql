USE Northwind
Go
CREATE SCHEMA [Example]
GO
Create table Example.HeapRebuildTest
(
	Id int,
	Name varchar(100),
	EmailId Varchar(200)
)
Go
Create nonclustered index IDX_HeapRebuildTest_Name on Example.HeapRebuildTest(name)
GO
Create statistics st_HeapRebuildTest_name on Example.HeapRebuildTest(name)
GO

Declare @ID INT
Declare @Max INT
Declare @NAME VARCHAR(100)
 
Set @ID = 1
Set @Max = 500000
 
While(@ID <=@Max)
 
Begin
 
		Set @NAME = Cast(left(newid(),60) as varchar)
		Insert Example.HeapRebuildTest
		Select @Id, @NAME,@NAME+'@abc.com'
 
        	Set @ID = @ID+1
End

-- Update some rows, just to cause forward pointers to be created.
Update Example.HeapRebuildTest 
set 
   EmailId = Cast(left(newid(),60) as varchar)+left(Emailid, charindex('@',Emailid,0)) 
where ID between 1 and 100000


Select 
	Database_id, 
	Index_id,
	Object_name([object_id]) as TableName, 
	Case 
		when SI.name is null then 'HEAP' 
		else SI.name 
	End as IndexName,
	Index_type_desc, 
	Avg_fragmentation_in_percent,
    forwarded_record_count
From sys.dm_db_index_physical_stats(db_id(),object_id('Example.HeapRebuildTest'),null,null,'detailed') AS SDDIPS
Inner join sys.sysindexes AS SI 
	on SDDIPS.[object_id] = SI.id 
	AND SDDIPS.index_id = SI.indid
Where index_level = 0



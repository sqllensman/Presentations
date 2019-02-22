-- Connnect as Admin:Servername

Use Northwind
GO

SELECT [DBName]
      ,[FileId]
      ,[PageId]
      ,[m_type]
      ,[Page_Type]
      ,pd.[object_id]
      ,[Schema_Name]
      ,[object_name]
      ,[index_id]
      ,[Index_Name]
      ,[Index_Type]
  FROM [CheckDB].[dbo].[PageData] pd
  Left Join Northwind.sys.objects o
	ON o.object_id = pd.object_id
  WHERE o.type = 'S'
  --AND pd.object_id = 3
  order by Object_ID, PageId


SELECT DISTINCT
       pd.[object_id]
      ,[Schema_Name]
      ,[object_name]
      ,[index_id]
      ,[Index_Name]
      ,[Index_Type]
  FROM [CheckDB].[dbo].[PageData] pd
  Left Join Northwind.sys.objects o
	ON o.object_id = pd.object_id
  WHERE o.type = 'S'
  --AND pd.object_id = 3
  order by Object_ID;


  Select * from sys.sysrscols
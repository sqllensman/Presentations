USE AdventureWorks2014
GO


DECLARE @SO_num nvarchar(23) = 'SO78971';

SELECT SUM(SubTotal)
FROM   Sales.SalesOrderHeader
WHERE  SalesOrderNumber <= @SO_num
OPTION(OPTIMIZE FOR (@SO_num = 'SO75000'));

-- Tuning attempt
SELECT SUM(SubTotal)
FROM   Sales.SalesOrderHeader
WHERE  SalesOrderNumber <= @SO_num
OPTION(OPTIMIZE FOR (@SO_num = 'SO43650'));
GO




-- The "right" ways to tune a query
-- (a) Look at elapsed time and CPU time (warning: fluctuations in overall server pressure can affect this!)
-- (b) Look at logical reads (warning: sometimes incomplete; not relevant if query is not I/O bound)
-- But ... what if the query takes four hours to run?
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
-- Now re-execute the code above
GO

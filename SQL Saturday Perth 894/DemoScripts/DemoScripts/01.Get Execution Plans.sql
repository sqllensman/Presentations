Use AdventureWorks2014
GO

SET SHOWPLAN_TEXT ON
GO

Select SalesOrderDetailID, OrderQty
FROM Sales.SalesOrderDetail sod
WHERE ProductId = (Select Avg(ProductId)
FROM Sales.SalesOrderDetail sod1
WHERE sod.SalesOrderId = sod1.SalesOrderId
GROUP BY SalesOrderId)

SET SHOWPLAN_TEXT OFF
GO

SET SHOWPLAN_ALL ON
GO

Select SalesOrderDetailID, OrderQty
FROM Sales.SalesOrderDetail sod
WHERE ProductId = (Select Avg(ProductId)
FROM Sales.SalesOrderDetail sod1
WHERE sod.SalesOrderId = sod1.SalesOrderId
GROUP BY SalesOrderId)

SET SHOWPLAN_ALL OFF
GO


SET SHOWPLAN_XML ON
GO

Select SalesOrderDetailID, OrderQty
FROM Sales.SalesOrderDetail sod
WHERE ProductId = (Select Avg(ProductId)
FROM Sales.SalesOrderDetail sod1
WHERE sod.SalesOrderId = sod1.SalesOrderId
GROUP BY SalesOrderId)

SET SHOWPLAN_XML OFF
GO

SET STATISTICS XML ON

Select SalesOrderDetailID, OrderQty
FROM Sales.SalesOrderDetail sod
WHERE ProductId = (Select Avg(ProductId)
FROM Sales.SalesOrderDetail sod1
WHERE sod.SalesOrderId = sod1.SalesOrderId
GROUP BY SalesOrderId)

SET STATISTICS XML OFF


Select SalesOrderDetailID, OrderQty
FROM Sales.SalesOrderDetail sod
WHERE ProductId = (Select Avg(ProductId)
FROM Sales.SalesOrderDetail sod1
WHERE sod.SalesOrderId = sod1.SalesOrderId
GROUP BY SalesOrderId)
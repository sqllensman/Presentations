Set Statistics IO, Time On
Set Statistics XML ON
GO

Use AdventureWorks2014
GO

Select SalesOrderDetailID, OrderQty
FROM Sales.SalesOrderDetail sod
WHERE ProductId = (Select Avg(ProductId)
FROM Sales.SalesOrderDetail sod1
WHERE sod.SalesOrderId = sod1.SalesOrderId
GROUP BY SalesOrderId)




DROP INDEX [IX_FirstTry] ON [Sales].[SalesOrderDetail]
GO

CREATE NONCLUSTERED INDEX [IX_FirstTry] ON [Sales].[SalesOrderDetail]
(
	[SalesOrderID] ASC,
	[ProductID] ASC
)
INCLUDE ( 	[OrderQty]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

DROP INDEX [IX_SecondTry] ON [Sales].[SalesOrderDetail]
GO

CREATE NONCLUSTERED INDEX [IX_SecondTry] ON [Sales].[SalesOrderDetail]
(
	[SalesOrderID] ASC,
	[ProductID] ASC
)
INCLUDE ( 	[OrderQty],
	[SalesOrderDetailID]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

Set Statistics IO, Time OFF
Set Statistics XML OFF
GO
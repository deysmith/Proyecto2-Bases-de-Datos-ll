-- Si la base no es una de las del proyecto, no se ejecuta nada de este archivo
IF DB_NAME() NOT IN ('WWI_Corporativo', 'WWI_SanJose', 'WWI_Limon')
BEGIN
  PRINT 'ERROR: está en la base ' + DB_NAME() + '. Elija WWI_Corporativo, WWI_SanJose o WWI_Limon.'
  SET NOEXEC ON
END
GO

SELECT @@SERVERNAME AS servidor, DB_NAME() AS base_de_datos
GO

CREATE SYNONYM clientes FOR Sales.Customers
CREATE SYNONYM categorias_clientes FOR Sales.CustomerCategories
CREATE SYNONYM grupo_compra FOR Sales.BuyingGroups
CREATE SYNONYM transacciones_clientes FOR Sales.CustomerTransactions
CREATE SYNONYM ordenes_clientes FOR Sales.Orders
CREATE SYNONYM detalles_ordenes_clientes FOR Sales.OrderLines

CREATE SYNONYM metodos_entrega FOR Application.DeliveryMethods
CREATE SYNONYM ciudades FOR Application.Cities
CREATE SYNONYM personas FOR Application.People
CREATE SYNONYM tipos_transacciones FOR Application.TransactionTypes
CREATE SYNONYM provincias FOR Application.StateProvinces

CREATE SYNONYM proveedores FOR Purchasing.Suppliers
CREATE SYNONYM categorias_proveedores FOR Purchasing.SupplierCategories
CREATE SYNONYM ordenes FOR Purchasing.PurchaseOrders
CREATE SYNONYM detalle_ordenes FOR Purchasing.PurchaseOrderLines
CREATE SYNONYM transacciones_proveedores FOR Purchasing.SupplierTransactions

CREATE SYNONYM productos FOR Warehouse.StockItems
CREATE SYNONYM inventario_productos FOR Warehouse.StockItemHoldings
CREATE SYNONYM nombre_grupo_producto FOR Warehouse.StockGroups
CREATE SYNONYM grupos_productos FOR Warehouse.StockItemStockGroups
CREATE SYNONYM colores_productos FOR Warehouse.Colors
CREATE SYNONYM tipos_paquetes_productos FOR Warehouse.PackageTypes
CREATE SYNONYM transacciones_productos FOR Warehouse.StockItemTransactions

CREATE SYNONYM facturas FOR Sales.Invoices
CREATE SYNONYM detalle_factura FOR Sales.InvoiceLines
CREATE SYNONYM ofertas FOR Sales.SpecialDeals
GO

-- Debe salir 26
SELECT COUNT(*) AS sinonimos FROM sys.synonyms
GO

-- Vuelve a la normalidad (por si se activó la validación de arriba)
SET NOEXEC OFF
GO
/*
   Script de la sucursal de San José
   Servidor: DESKTOP-8CTQSKC (Windows) | Base de datos: WWI_SanJose
*/

-- Confirmar que se está en la base de datos correcta
USE WWI_SanJose
GO

SELECT @@SERVERNAME AS servidor, DB_NAME() AS base_de_datos

-- Datos originales de WWI
SELECT
  (SELECT COUNT(*) FROM Sales.Invoices) AS facturas,
  (SELECT COUNT(*) FROM Sales.CustomerTransactions) AS transacciones_clientes,
  (SELECT COUNT(*) FROM Warehouse.StockItemTransactions) AS movimientos_inventario,
  (SELECT SUM(QuantityOnHand) FROM Warehouse.StockItemHoldings) AS unidades_inventario
GO

-- Modelo de recuperación simple. Para que el log no crezca demasiado con los DELETE grandes.
ALTER DATABASE WWI_SanJose SET RECOVERY SIMPLE
GO

/* 
    Quitar la seguridad por filas (RLS) que traía WWI. WWI filtraba clientes por territorio según el rol del usuario.
    Ahora eso lo va a hacer la fragmentación horizontal.
*/
DROP SECURITY POLICY IF EXISTS Application.FilterCustomersBySalesTerritoryRole
DROP FUNCTION IF EXISTS Application.DetermineCustomerAccess
GO

/*
    Quitar el versionado temporal de las tablas que se replican, según Microsoft Learn: 
    con tablas temporales la replicación transaccional solo soporta un suscriptor, y nosotros tenemos dos sucursales.
*/
ALTER TABLE Application.Cities SET (SYSTEM_VERSIONING = OFF)
ALTER TABLE Application.Cities DROP PERIOD FOR SYSTEM_TIME
ALTER TABLE Application.Countries SET (SYSTEM_VERSIONING = OFF)
ALTER TABLE Application.Countries DROP PERIOD FOR SYSTEM_TIME
ALTER TABLE Application.DeliveryMethods SET (SYSTEM_VERSIONING = OFF)
ALTER TABLE Application.DeliveryMethods DROP PERIOD FOR SYSTEM_TIME
ALTER TABLE Application.PaymentMethods SET (SYSTEM_VERSIONING = OFF)
ALTER TABLE Application.PaymentMethods DROP PERIOD FOR SYSTEM_TIME
ALTER TABLE Application.People SET (SYSTEM_VERSIONING = OFF)
ALTER TABLE Application.People DROP PERIOD FOR SYSTEM_TIME
ALTER TABLE Application.StateProvinces SET (SYSTEM_VERSIONING = OFF)
ALTER TABLE Application.StateProvinces DROP PERIOD FOR SYSTEM_TIME
ALTER TABLE Application.TransactionTypes SET (SYSTEM_VERSIONING = OFF)
ALTER TABLE Application.TransactionTypes DROP PERIOD FOR SYSTEM_TIME
ALTER TABLE Purchasing.SupplierCategories SET (SYSTEM_VERSIONING = OFF)
ALTER TABLE Purchasing.SupplierCategories DROP PERIOD FOR SYSTEM_TIME
ALTER TABLE Purchasing.Suppliers SET (SYSTEM_VERSIONING = OFF)
ALTER TABLE Purchasing.Suppliers DROP PERIOD FOR SYSTEM_TIME
ALTER TABLE Sales.BuyingGroups SET (SYSTEM_VERSIONING = OFF)
ALTER TABLE Sales.BuyingGroups DROP PERIOD FOR SYSTEM_TIME
ALTER TABLE Sales.CustomerCategories SET (SYSTEM_VERSIONING = OFF)
ALTER TABLE Sales.CustomerCategories DROP PERIOD FOR SYSTEM_TIME
ALTER TABLE Sales.Customers SET (SYSTEM_VERSIONING = OFF)
ALTER TABLE Sales.Customers DROP PERIOD FOR SYSTEM_TIME
ALTER TABLE Warehouse.Colors SET (SYSTEM_VERSIONING = OFF)
ALTER TABLE Warehouse.Colors DROP PERIOD FOR SYSTEM_TIME
ALTER TABLE Warehouse.PackageTypes SET (SYSTEM_VERSIONING = OFF)
ALTER TABLE Warehouse.PackageTypes DROP PERIOD FOR SYSTEM_TIME
ALTER TABLE Warehouse.StockGroups SET (SYSTEM_VERSIONING = OFF)
ALTER TABLE Warehouse.StockGroups DROP PERIOD FOR SYSTEM_TIME
ALTER TABLE Warehouse.StockItems SET (SYSTEM_VERSIONING = OFF)
ALTER TABLE Warehouse.StockItems DROP PERIOD FOR SYSTEM_TIME
GO

/*
    Valores por defecto para ValidFrom y ValidTo. Antes los llenaba SQL Server solo, ahora son columnas normales.
    Sin esto, los Inserts de los Store Procedures del Proyecto 1 fallarían.
*/
ALTER TABLE Application.Cities ADD CONSTRAINT DF_Cities_ValidFrom DEFAULT SYSUTCDATETIME() FOR ValidFrom, CONSTRAINT DF_Cities_ValidTo DEFAULT '9999-12-31 23:59:59.9999999' FOR ValidTo
ALTER TABLE Application.Countries ADD CONSTRAINT DF_Countries_ValidFrom DEFAULT SYSUTCDATETIME() FOR ValidFrom, CONSTRAINT DF_Countries_ValidTo DEFAULT '9999-12-31 23:59:59.9999999' FOR ValidTo
ALTER TABLE Application.DeliveryMethods ADD CONSTRAINT DF_DeliveryMethods_ValidFrom DEFAULT SYSUTCDATETIME() FOR ValidFrom, CONSTRAINT DF_DeliveryMethods_ValidTo DEFAULT '9999-12-31 23:59:59.9999999' FOR ValidTo
ALTER TABLE Application.PaymentMethods ADD CONSTRAINT DF_PaymentMethods_ValidFrom DEFAULT SYSUTCDATETIME() FOR ValidFrom, CONSTRAINT DF_PaymentMethods_ValidTo DEFAULT '9999-12-31 23:59:59.9999999' FOR ValidTo
ALTER TABLE Application.People ADD CONSTRAINT DF_People_ValidFrom DEFAULT SYSUTCDATETIME() FOR ValidFrom, CONSTRAINT DF_People_ValidTo DEFAULT '9999-12-31 23:59:59.9999999' FOR ValidTo
ALTER TABLE Application.StateProvinces ADD CONSTRAINT DF_StateProvinces_ValidFrom DEFAULT SYSUTCDATETIME() FOR ValidFrom, CONSTRAINT DF_StateProvinces_ValidTo DEFAULT '9999-12-31 23:59:59.9999999' FOR ValidTo
ALTER TABLE Application.TransactionTypes ADD CONSTRAINT DF_TransactionTypes_ValidFrom DEFAULT SYSUTCDATETIME() FOR ValidFrom, CONSTRAINT DF_TransactionTypes_ValidTo DEFAULT '9999-12-31 23:59:59.9999999' FOR ValidTo
ALTER TABLE Purchasing.SupplierCategories ADD CONSTRAINT DF_SupplierCategories_ValidFrom DEFAULT SYSUTCDATETIME() FOR ValidFrom, CONSTRAINT DF_SupplierCategories_ValidTo DEFAULT '9999-12-31 23:59:59.9999999' FOR ValidTo
ALTER TABLE Purchasing.Suppliers ADD CONSTRAINT DF_Suppliers_ValidFrom DEFAULT SYSUTCDATETIME() FOR ValidFrom, CONSTRAINT DF_Suppliers_ValidTo DEFAULT '9999-12-31 23:59:59.9999999' FOR ValidTo
ALTER TABLE Sales.BuyingGroups ADD CONSTRAINT DF_BuyingGroups_ValidFrom DEFAULT SYSUTCDATETIME() FOR ValidFrom, CONSTRAINT DF_BuyingGroups_ValidTo DEFAULT '9999-12-31 23:59:59.9999999' FOR ValidTo
ALTER TABLE Sales.CustomerCategories ADD CONSTRAINT DF_CustomerCategories_ValidFrom DEFAULT SYSUTCDATETIME() FOR ValidFrom, CONSTRAINT DF_CustomerCategories_ValidTo DEFAULT '9999-12-31 23:59:59.9999999' FOR ValidTo
ALTER TABLE Sales.Customers ADD CONSTRAINT DF_Customers_ValidFrom DEFAULT SYSUTCDATETIME() FOR ValidFrom, CONSTRAINT DF_Customers_ValidTo DEFAULT '9999-12-31 23:59:59.9999999' FOR ValidTo
ALTER TABLE Warehouse.Colors ADD CONSTRAINT DF_Colors_ValidFrom DEFAULT SYSUTCDATETIME() FOR ValidFrom, CONSTRAINT DF_Colors_ValidTo DEFAULT '9999-12-31 23:59:59.9999999' FOR ValidTo
ALTER TABLE Warehouse.PackageTypes ADD CONSTRAINT DF_PackageTypes_ValidFrom DEFAULT SYSUTCDATETIME() FOR ValidFrom, CONSTRAINT DF_PackageTypes_ValidTo DEFAULT '9999-12-31 23:59:59.9999999' FOR ValidTo
ALTER TABLE Warehouse.StockGroups ADD CONSTRAINT DF_StockGroups_ValidFrom DEFAULT SYSUTCDATETIME() FOR ValidFrom, CONSTRAINT DF_StockGroups_ValidTo DEFAULT '9999-12-31 23:59:59.9999999' FOR ValidTo
ALTER TABLE Warehouse.StockItems ADD CONSTRAINT DF_StockItems_ValidFrom DEFAULT SYSUTCDATETIME() FOR ValidFrom, CONSTRAINT DF_StockItems_ValidTo DEFAULT '9999-12-31 23:59:59.9999999' FOR ValidTo
GO

-- Debe salir solo ColdRoomTemperatures y su tabla _Archive
SELECT name AS tabla, temporal_type_desc
FROM sys.tables
WHERE temporal_type <> 0

-- Verificamos que las columnas temporales se hayan convertido a normales (debería salir solo ColdRoomTemperatures con 2 filas: ValidFrom y ValidTo)
SELECT OBJECT_NAME(object_id) AS tabla, name AS columna, generated_always_type_desc
FROM sys.columns
WHERE generated_always_type <> 0
GO

/* 
    Tabla de asignación: segun el territorio de ventas se le asigna una sucursal
    Es el criterio de la fragmentación horizontal, por lo tanto, a cada territorio se asigna a una sucursal específica.
*/
CREATE TABLE dbo.AsignacionSucursal (
  Territorio nvarchar(50) NOT NULL PRIMARY KEY,
  Sucursal nvarchar(20) NOT NULL
)

INSERT INTO dbo.AsignacionSucursal (Territorio, Sucursal) VALUES
  ('New England', 'Limon'),
  ('Mideast', 'Limon'),
  ('Southeast', 'Limon'),
  ('Great Lakes', 'Limon'),
  ('External', 'Limon'),
  ('Far West', 'SanJose'),
  ('Rocky Mountain', 'SanJose'),
  ('Southwest', 'SanJose'),
  ('Plains', 'SanJose')
GO

/*
  Se agrega la columna Sucursal a la tabla Sales.Customers y se asigna el valor 
  correspondiente según el territorio del cliente segun su ciudad de entrega.
*/
ALTER TABLE Sales.Customers ADD Sucursal nvarchar(20) NULL
GO

UPDATE c
SET c.Sucursal = a.Sucursal
FROM Sales.Customers c
INNER JOIN Application.Cities ci ON ci.CityID = c.DeliveryCityID
INNER JOIN Application.StateProvinces sp ON sp.StateProvinceID = ci.StateProvinceID
INNER JOIN dbo.AsignacionSucursal a ON a.Territorio = sp.SalesTerritory
GO

CREATE INDEX IX_Sales_Customers_Sucursal ON Sales.Customers (Sucursal)
GO

SELECT Sucursal, COUNT(*) AS clientes
FROM Sales.Customers
GROUP BY Sucursal
GO


/* 
   Fragmentación horizontal
   San José se queda solo con la facturación de sus clientes.
   Las compras a proveedores se van al Corporativo.
*/
BEGIN TRY
  BEGIN TRANSACTION

  -- Si ya no hay órdenes de compra, este paso ya se había corrido
  IF NOT EXISTS (SELECT 1 FROM Purchasing.PurchaseOrders)
  BEGIN
    THROW 50001, 'La fragmentación horizontal ya se aplicó en esta base', 1
  END

 -- Movimientos de inventario: los de facturas de Limón y los de compras a proveedores (sin cliente)
  DELETE FROM Warehouse.StockItemTransactions
  WHERE InvoiceID IN (SELECT i.InvoiceID
                      FROM Sales.Invoices i
                      INNER JOIN Sales.Customers c ON c.CustomerID = i.CustomerID
                      WHERE c.Sucursal <> 'SanJose')
     OR (InvoiceID IS NULL AND CustomerID IS NULL)
     OR (InvoiceID IS NULL AND CustomerID IN (SELECT CustomerID FROM Sales.Customers WHERE Sucursal <> 'SanJose'))

  -- Transacciones de clientes. Las de factura van con su factura; los pagos sueltos, con su cliente
  DELETE FROM Sales.CustomerTransactions
  WHERE InvoiceID IN (SELECT i.InvoiceID
                      FROM Sales.Invoices i
                      INNER JOIN Sales.Customers c ON c.CustomerID = i.CustomerID
                      WHERE c.Sucursal <> 'SanJose')
     OR (InvoiceID IS NULL AND CustomerID IN (SELECT CustomerID FROM Sales.Customers WHERE Sucursal <> 'SanJose'))

  -- Detalle de facturas de clientes de Limón
  DELETE FROM Sales.InvoiceLines
  WHERE InvoiceID IN (SELECT i.InvoiceID
                      FROM Sales.Invoices i
                      INNER JOIN Sales.Customers c ON c.CustomerID = i.CustomerID
                      WHERE c.Sucursal <> 'SanJose')

  -- Facturas de clientes de Limón
  DELETE FROM Sales.Invoices
  WHERE CustomerID IN (SELECT CustomerID FROM Sales.Customers WHERE Sucursal <> 'SanJose')

  -- Pedidos de clientes de Limón
  DELETE FROM Sales.OrderLines
  WHERE OrderID IN (SELECT o.OrderID
                    FROM Sales.Orders o
                    INNER JOIN Sales.Customers c ON c.CustomerID = o.CustomerID
                    WHERE c.Sucursal <> 'SanJose')

  -- Un pedido puede apuntar a otro pedido pendiente (BackorderOrderID), se quita esa referencia primero
  UPDATE Sales.Orders
  SET BackorderOrderID = NULL
  WHERE CustomerID IN (SELECT CustomerID FROM Sales.Customers WHERE Sucursal <> 'SanJose')

  DELETE FROM Sales.Orders
  WHERE CustomerID IN (SELECT CustomerID FROM Sales.Customers WHERE Sucursal <> 'SanJose')

  -- Compras a proveedores: centralizadas en el Corporativo
  DELETE FROM Purchasing.SupplierTransactions
  DELETE FROM Purchasing.PurchaseOrderLines
  DELETE FROM Purchasing.PurchaseOrders

  -- Inventario propio: San José se queda con la mitad (Limón con el resto)
  UPDATE Warehouse.StockItemHoldings
  SET QuantityOnHand = QuantityOnHand / 2,
      LastStocktakeQuantity = LastStocktakeQuantity / 2

  COMMIT TRANSACTION
  SELECT 'Fragmentación horizontal aplicada' AS Resultado
END TRY
BEGIN CATCH
  IF XACT_STATE() <> 0
    ROLLBACK TRANSACTION
  SELECT
    ERROR_NUMBER()  AS NumeroError,
    ERROR_MESSAGE() AS MensajeError,
    ERROR_LINE()    AS LineaError
END CATCH
GO


/* 
   Fragmentación vertical
   Los datos sensibles (privacidad / forma de contacto) quedan solo en el Corporativo. Aquí se eliminan esas columnas.
*/
BEGIN TRY
  BEGIN TRANSACTION

  -- Primero las llaves foráneas e índices que usan esas columnas
  ALTER TABLE Sales.Customers DROP CONSTRAINT FK_Sales_Customers_PrimaryContactPersonID_Application_People
  ALTER TABLE Sales.Customers DROP CONSTRAINT FK_Sales_Customers_AlternateContactPersonID_Application_People
  DROP INDEX FK_Sales_Customers_PrimaryContactPersonID ON Sales.Customers
  DROP INDEX FK_Sales_Customers_AlternateContactPersonID ON Sales.Customers
  DROP INDEX IX_Sales_Customers_Perf_20160301_06 ON Sales.Customers

  ALTER TABLE Sales.Customers DROP COLUMN
    PrimaryContactPersonID, AlternateContactPersonID,
    PhoneNumber, FaxNumber, WebsiteURL,
    DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode, DeliveryLocation,
    PostalAddressLine1, PostalAddressLine2, PostalPostalCode

  -- Proveedores: contacto, direcciones y datos bancarios
  ALTER TABLE Purchasing.Suppliers DROP CONSTRAINT FK_Purchasing_Suppliers_PrimaryContactPersonID_Application_People
  ALTER TABLE Purchasing.Suppliers DROP CONSTRAINT FK_Purchasing_Suppliers_AlternateContactPersonID_Application_People
  DROP INDEX FK_Purchasing_Suppliers_PrimaryContactPersonID   ON Purchasing.Suppliers
  DROP INDEX FK_Purchasing_Suppliers_AlternateContactPersonID ON Purchasing.Suppliers

  ALTER TABLE Purchasing.Suppliers DROP COLUMN
    PrimaryContactPersonID, AlternateContactPersonID,
    BankAccountName, BankAccountBranch, BankAccountCode, BankAccountNumber, BankInternationalCode,
    PhoneNumber, FaxNumber, WebsiteURL,
    DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode, DeliveryLocation,
    PostalAddressLine1, PostalAddressLine2, PostalPostalCode

  -- Personas: usuario, contraseña y forma de contacto
  DROP INDEX IX_Application_People_Perf_20160301_05 ON Application.People

  ALTER TABLE Application.People DROP COLUMN
    LogonName, HashedPassword, PhoneNumber, FaxNumber, EmailAddress, Photo, UserPreferences

  -- Tablas de historial (_Archive): tenían copias de los datos sensibles. El historial queda solo en el Corporativo.
  DROP TABLE Application.Cities_Archive, Application.Countries_Archive, Application.DeliveryMethods_Archive,
             Application.PaymentMethods_Archive, Application.People_Archive, Application.StateProvinces_Archive,
             Application.TransactionTypes_Archive, Purchasing.SupplierCategories_Archive, Purchasing.Suppliers_Archive,
             Sales.BuyingGroups_Archive, Sales.CustomerCategories_Archive, Sales.Customers_Archive,
             Warehouse.Colors_Archive, Warehouse.PackageTypes_Archive, Warehouse.StockGroups_Archive,
             Warehouse.StockItems_Archive

  COMMIT TRANSACTION
  SELECT 'Fragmentación vertical aplicada' AS Resultado
END TRY
BEGIN CATCH
  IF XACT_STATE() <> 0
    ROLLBACK TRANSACTION
  SELECT
    ERROR_NUMBER() AS NumeroError,
    ERROR_MESSAGE() AS MensajeError,
    ERROR_LINE() AS LineaError
END CATCH
GO

/*
   Rango de IDs propio de San José
   Las facturas nuevas de San José empiezan en 1 000 000 (Limón en 2 000 000)
   para que nunca se repitan cuando el Corporativo junte las dos sucursales.
*/
ALTER SEQUENCE Sequences.InvoiceID RESTART WITH 1000000
ALTER SEQUENCE Sequences.InvoiceLineID RESTART WITH 1000000
ALTER SEQUENCE Sequences.OrderID RESTART WITH 1000000
ALTER SEQUENCE Sequences.OrderLineID RESTART WITH 1000000
ALTER SEQUENCE Sequences.TransactionID RESTART WITH 1000000
GO

-- Liberar espacio en el log de transacciones
CHECKPOINT
DBCC SHRINKFILE (WWI_Log, 100)
GO

-- Verificación de la fragmentación horizontal y vertical
SELECT 'Clientes (catálogo completo)' AS dato, COUNT(*) AS cantidad FROM Sales.Customers
UNION ALL SELECT 'Clientes de San José', COUNT(*) FROM Sales.Customers WHERE Sucursal = 'SanJose'
UNION ALL SELECT 'Facturas', COUNT(*) FROM Sales.Invoices
UNION ALL SELECT 'Facturas de clientes de Limón (debe ser 0)', COUNT(*)
          FROM Sales.Invoices i
          INNER JOIN Sales.Customers c ON c.CustomerID = i.CustomerID
          WHERE c.Sucursal <> 'SanJose'
UNION ALL SELECT 'Transacciones de clientes', COUNT(*) FROM Sales.CustomerTransactions
UNION ALL SELECT 'Movimientos de inventario', COUNT(*) FROM Warehouse.StockItemTransactions
UNION ALL SELECT 'Ordenes de compra (debe ser 0)', COUNT(*) FROM Purchasing.PurchaseOrders
UNION ALL SELECT 'Productos en inventario', COUNT(*) FROM Warehouse.StockItemHoldings
UNION ALL SELECT 'Unidades en inventario', SUM(QuantityOnHand) FROM Warehouse.StockItemHoldings

-- Verificación de la fragmentación vertical: las columnas sensibles ya no existen en esta sucursal
SELECT COL_LENGTH('Sales.Customers', 'PhoneNumber') AS cliente_telefono,
       COL_LENGTH('Purchasing.Suppliers', 'BankAccountNumber') AS proveedor_cuenta,
       COL_LENGTH('Application.People', 'EmailAddress') AS persona_email
GO


---------- Seguridad y Cifrado de Contraseñas ----------


-- Confirmar en que BD vamos a trabajar
USE WWI_SanJose
GO
SELECT @@SERVERNAME AS servidor, DB_NAME() AS base_de_datos
GO

/* 
   Jerarquía de cifrado: master key -> certificado -> llave
   KEY_SOURCE e IDENTITY_VALUE son los "secretos compartidos": al usar
   los MISMOS en los 3 nodos, la llave simétrica queda Idéntica en todos
   y una contraseña cifrada en el Corporativo se puede descifrar en las
   sucursales. Según Microsoft Learn: Create identical symmetric keys on two servers.
*/
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'MasterKey_SanJose*2026'
GO

CREATE CERTIFICATE CertificadoUsuarios
WITH SUBJECT = 'Proteccion de contrasenas de usuarios'
GO

CREATE SYMMETRIC KEY LlaveUsuarios
WITH ALGORITHM = AES_256,
     KEY_SOURCE = 'WWI Proyecto 2 - fuente de la llave de usuarios',
     IDENTITY_VALUE = 'WWI Proyecto 2 - identidad de la llave de usuarios'
ENCRYPTION BY CERTIFICATE CertificadoUsuarios
GO

-- Tabla de usuarios (vacía, la llena la replicación)
CREATE SEQUENCE Sequences.UsuarioID AS int START WITH 1 INCREMENT BY 1
GO

CREATE TABLE dbo.Usuarios (
  iduser int NOT NULL CONSTRAINT DF_Usuarios_iduser DEFAULT (NEXT VALUE FOR Sequences.UsuarioID),
  username nvarchar(50) NOT NULL,
  password varbinary(256) NOT NULL,
  fullname nvarchar(100) NOT NULL,
  active bit NOT NULL CONSTRAINT DF_Usuarios_active DEFAULT 1,
  rol nvarchar(20) NOT NULL,
  email nvarchar(100) NULL,
  hiredate date NOT NULL,
  sucursal nvarchar(20) NULL,
  CONSTRAINT PK_Usuarios PRIMARY KEY (iduser),
  CONSTRAINT UQ_Usuarios_username UNIQUE (username),
  CONSTRAINT CK_Usuarios_rol CHECK (rol IN ('Administrador', 'Corporativo')),
  CONSTRAINT CK_Usuarios_sucursal CHECK (
       (rol = 'Administrador' AND sucursal IN ('SanJose', 'Limon'))
    OR (rol = 'Corporativo' AND sucursal IS NULL))
)
GO

/*
   ValidarUsuario: login de los administradores de San José
   Funciona aunque el Corporativo esté caído (los usuarios están replicados).
*/
CREATE OR ALTER PROCEDURE dbo.ValidarUsuario
  @username nvarchar(50),
  @password nvarchar(100)
WITH EXECUTE AS OWNER
AS
BEGIN
  OPEN SYMMETRIC KEY LlaveUsuarios DECRYPTION BY CERTIFICATE CertificadoUsuarios

  SELECT iduser, username, fullname, rol, email, sucursal
  FROM dbo.Usuarios
  WHERE username = @username
    AND CONVERT(nvarchar(100), DecryptByKey(password)) = @password COLLATE Latin1_General_100_CS_AS
    AND active = 1
    AND rol = 'Administrador'
    AND sucursal = 'SanJose'

  CLOSE SYMMETRIC KEY LlaveUsuarios
END
GO

--Login de la API para el rol Administrador de San José
CREATE LOGIN api_sanjose
WITH PASSWORD = 'ApiSanJose*2026', CHECK_POLICY = OFF, DEFAULT_DATABASE = WWI_SanJose
GO

CREATE USER api_sanjose FOR LOGIN api_sanjose
CREATE ROLE rol_administrador
ALTER ROLE rol_administrador ADD MEMBER api_sanjose
GRANT EXECUTE ON dbo.ValidarUsuario TO rol_administrador
GO

-- Prueba: descifrar el valor que se cifró en el Corporativo
SELECT name, key_guid FROM sys.symmetric_keys WHERE name = 'LlaveUsuarios'

OPEN SYMMETRIC KEY LlaveUsuarios DECRYPTION BY CERTIFICATE CertificadoUsuarios
SELECT CONVERT(nvarchar(100), DecryptByKey(0x001D9751BEF319ACB1F935B2AD724C8B020000001AD5DF3447F2BAFAD11F2A51D275EA947A148BC6B026C8E3234A074847E6DECCDE8E20B5DA9BD914D29B0F3A5CE5F000E4F5ED41527729F4816156BF64772BF8C83D44325966004F31AF0D4198833DE9)) AS valor_descifrado
CLOSE SYMMETRIC KEY LlaveUsuarios
GO

USE WWI_SanJose
GO
SELECT @@SERVERNAME AS servidor,
  (SELECT COUNT(*) FROM Application.Cities) AS ciudades,
  (SELECT COUNT(*) FROM Application.People) AS personas,
  (SELECT COUNT(*) FROM Sales.Customers) AS clientes,
  (SELECT COUNT(*) FROM Purchasing.Suppliers) AS proveedores,
  (SELECT COUNT(*) FROM Warehouse.StockItems) AS productos,
  (SELECT COUNT(*) FROM Warehouse.StockItemStockGroups) AS grupos_productos,
  (SELECT COUNT(*) FROM Sales.SpecialDeals) AS ofertas,
  (SELECT COUNT(*) FROM dbo.Usuarios) AS usuarios

-- Muestra de prueba #1
SELECT StockItemID, StockItemName, RecommendedRetailPrice
FROM Warehouse.StockItems WHERE StockItemID = 1

-- Muestra de prueba #2
USE WWI_SanJose
GO
-- Los 3 usuarios llegaron por replicación, con la contraseña cifrada
SELECT iduser, username, rol, sucursal, password FROM dbo.Usuarios

-- El admin de San José puede iniciar sesión aquí (1 fila)
EXEC dbo.ValidarUsuario 'admin_sanjose', 'SanJose*2026'

-- El admin de Limón NO puede iniciar sesión en San José (0 filas)
EXEC dbo.ValidarUsuario 'admin_limon', 'Limon*2026'


---------- Linked servers ----------


/*
   Login de solo lectura que usa el Corporativo (linked server SANJOSE)
   para consultar las ventas e inventario de San José.
*/
USE WWI_SanJose
GO
CREATE LOGIN lectura_corporativo
WITH PASSWORD = 'LecturaCorp*2026', CHECK_POLICY = OFF, DEFAULT_DATABASE = WWI_SanJose
GO
CREATE USER lectura_corporativo FOR LOGIN lectura_corporativo
ALTER ROLE db_datareader ADD MEMBER lectura_corporativo
GO

/*
   Linked server hacia el Corporativo, para leer los datos sensibles.
*/
USE master
GO
EXEC sp_addlinkedserver
  @server = N'CORPORATIVO',
  @srvproduct = N'',
  @provider = N'MSOLEDBSQL',
  @datasrc = N'localhost,1440'

EXEC sp_addlinkedsrvlogin
  @rmtsrvname = N'CORPORATIVO',
  @useself = N'False',
  @locallogin = NULL,
  @rmtuser = N'lectura_sucursal',
  @rmtpassword = N'LecturaSuc*2026'

EXEC sp_serveroption @server = N'CORPORATIVO', @optname = N'connect timeout', @optvalue = N'5'
GO

/*
   Prueba: Reconstruir la fragmentación vertical.
   El nombre del cliente está aquí; el teléfono y la dirección están en el Corporativo.
*/
USE WWI_SanJose
GO
SELECT TOP 5
  c.CustomerID,
  c.CustomerName, -- fragmento general (San José)
  p.FullName AS Contacto, -- fragmento general (San José)
  s.PhoneNumber, -- fragmento sensible (Corporativo)
  s.DeliveryAddressLine1, -- fragmento sensible (Corporativo)
  s.Latitud,
  s.Longitud
FROM Sales.Customers c
INNER JOIN CORPORATIVO.WWI_Corporativo.dbo.ClientesSensibles s ON s.CustomerID = c.CustomerID
LEFT JOIN Application.People p ON p.PersonID = s.PrimaryContactPersonID
WHERE c.Sucursal = 'SanJose'
GO

-- Prueba de seguridad: el login de lectura no puede ver otras tablas del Corporativo
SELECT TOP 1 * FROM CORPORATIVO.WWI_Corporativo.Purchasing.PurchaseOrders
GO

-- Comprobración PersonID
SELECT PersonID, FullName FROM Application.People WHERE FullName = 'PagWeb'


---------- Inventario propio de la sucursal ----------


USE WWI_SanJose
GO

/*
   Si el Corporativo elimina un producto, la replicación lo borra aquí.
   ON DELETE CASCADE borra también su registro de inventario de esta sucursal
   (si no, la llave foránea haría fallar la replicación).
*/
ALTER TABLE Warehouse.StockItemHoldings
DROP CONSTRAINT PKFK_Warehouse_StockItemHoldings_StockItemID_Warehouse_StockItems

ALTER TABLE Warehouse.StockItemHoldings
ADD CONSTRAINT PKFK_Warehouse_StockItemHoldings_StockItemID_Warehouse_StockItems
FOREIGN KEY (StockItemID) REFERENCES Warehouse.StockItems (StockItemID)
ON DELETE CASCADE
GO

/*
   Trigger: cuando llega un producto nuevo por replicación desde el Corporativo,
   se le crea su registro de inventario en esta sucursal con cantidad 0.
*/
CREATE OR ALTER TRIGGER Warehouse.trg_ProductoNuevo_Inventario
ON Warehouse.StockItems
AFTER INSERT
AS
BEGIN
  SET NOCOUNT ON

  INSERT INTO Warehouse.StockItemHoldings (
    StockItemID, QuantityOnHand, BinLocation, LastStocktakeQuantity,
    LastCostPrice, ReorderLevel, TargetStockLevel, LastEditedBy
  )
  SELECT i.StockItemID, 0, 'Sin asignar', 0, i.UnitPrice, 5, 20, i.LastEditedBy
  FROM inserted i
  WHERE NOT EXISTS (SELECT 1 FROM Warehouse.StockItemHoldings h WHERE h.StockItemID = i.StockItemID)
END
GO

/*
   ActualizarInventarioProducto: el administrador de la sucursal define la
   cantidad y la ubicación en bodega de un producto en su sucursal.
   El inventario no se replica: cada sucursal maneja el suyo.
*/
CREATE OR ALTER PROCEDURE dbo.ActualizarInventarioProducto
  @ID_Producto int,
  @QuantityOnHand int = NULL,
  @BinLocation nvarchar(20) = NULL
AS
BEGIN
  SET XACT_ABORT ON
  DECLARE @PersonaEncargadaID int
  BEGIN TRY
    BEGIN TRANSACTION

    IF @QuantityOnHand < 0
    BEGIN
      THROW 50042, 'La cantidad en inventario no puede ser negativa', 1
    END

    SELECT @PersonaEncargadaID = PersonID FROM personas WHERE FullName = 'PagWeb'

    UPDATE inventario_productos
    SET QuantityOnHand = ISNULL(@QuantityOnHand, QuantityOnHand),
        BinLocation = ISNULL(@BinLocation, BinLocation),
        LastEditedBy = @PersonaEncargadaID,
        LastEditedWhen = SYSDATETIME()
    WHERE StockItemID = @ID_Producto

    IF @@ROWCOUNT = 0
    BEGIN
      THROW 50041, 'El producto no tiene inventario en esta sucursal (si es nuevo, espere unos segundos a que llegue por replicación)', 1
    END

    COMMIT TRANSACTION
    SELECT StockItemID, QuantityOnHand, BinLocation
    FROM inventario_productos WHERE StockItemID = @ID_Producto
  END TRY
  BEGIN CATCH
    IF XACT_STATE() <> 0
      ROLLBACK TRANSACTION
    SELECT
      ERROR_NUMBER() AS NumeroError,
      ERROR_MESSAGE() AS MensajeError,
      ERROR_LINE() AS LineaError
  END CATCH
END
GO

-- Prueba #1: Crear un producto y ver que llega con inventario en 0
SELECT p.StockItemID, p.StockItemName, h.QuantityOnHand, h.BinLocation
FROM Warehouse.StockItems p
LEFT JOIN Warehouse.StockItemHoldings h ON h.StockItemID = p.StockItemID
WHERE p.StockItemName = 'Producto Prueba P2'

-- Inventario Propio de San José
DECLARE @id int = (SELECT StockItemID FROM Warehouse.StockItems WHERE StockItemName = 'Producto Prueba P2')
EXEC dbo.ActualizarInventarioProducto @ID_Producto = @id, @QuantityOnHand = 10, @BinLocation = 'A-01'

-- Modificar inventario para que el Corporativo pueda eliminar
DECLARE @id int = (SELECT StockItemID FROM Warehouse.StockItems WHERE StockItemName = 'Producto Prueba P2')
EXEC dbo.ActualizarInventarioProducto @ID_Producto = @id, @QuantityOnHand = 0

-- Prueba #1 fragmentación reconstruida: Detalle completo de un cliente
USE WWI_SanJose
GO
DECLARE @id int = (SELECT TOP 1 CustomerID FROM Sales.Customers WHERE Sucursal = 'SanJose' ORDER BY CustomerID)
EXEC ObtenerDatosProveedor @ID_Proveedor = 1

-- Prueba #2: La versión del producto
EXEC ObtenerDatosProducto @ID_Producto = 1
/*
   Script del corporativo (Plaza Roble, Escazú)
   Servidor: sqlcorporativo (Docker, Ubuntu) | Base de datos: WWI_Corporativo
*/

-- Confirmar dónde estoy y anotar los datos originales
USE WWI_Corporativo
GO

SELECT @@SERVERNAME AS servidor, DB_NAME() AS base_de_datos

SELECT
  (SELECT COUNT(*) FROM Sales.Invoices) AS facturas,
  (SELECT COUNT(*) FROM Sales.CustomerTransactions) AS transacciones_clientes,
  (SELECT COUNT(*) FROM Warehouse.StockItemTransactions) AS movimientos_inventario,
  (SELECT SUM(QuantityOnHand) FROM Warehouse.StockItemHoldings) AS unidades_inventario
GO

-- Cambiar la base de datos a recuperación simple para que no crezca el log de transacciones
ALTER DATABASE WWI_Corporativo SET RECOVERY SIMPLE
GO

-- Quitar la política de seguridad y la función que la implementaba
DROP SECURITY POLICY IF EXISTS Application.FilterCustomersBySalesTerritoryRole
DROP FUNCTION IF EXISTS Application.DetermineCustomerAccess
GO

/*
   Quitar el versionado temporal de las tablas que se replican.
   El Corporativo es el Publicador. Segun Microsoft Learn indica que el publicador
   tampoco puede tener las tablas temporales activadas.
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

-- Valores por defecto para ValidFrom y ValidTo: ya no las llena SQL Server, y sin esto los INSERT de los SPs fallarían
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

-- Verificación de las tablas y columnas que tenían versionado temporal
SELECT name AS tabla, temporal_type_desc
FROM sys.tables
WHERE temporal_type <> 0

SELECT OBJECT_NAME(object_id) AS tabla, name AS columna, generated_always_type_desc
FROM sys.columns
WHERE generated_always_type <> 0
GO

-- Tabla de asignación de clientes a sucursales, según el territorio de ventas
CREATE TABLE dbo.AsignacionSucursal (
  Territorio nvarchar(50) NOT NULL PRIMARY KEY,
  Sucursal   nvarchar(20) NOT NULL
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

-- Asignar a cada cliente la sucursal que le corresponde según su territorio de ventas
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
   Fragmentacion del Corporativo: eliminar los datos que no le corresponden
   El Corporativo no vende ni tiene bodega: la facturación, los pedidos
   y el inventario viven en las sucursales.
   Se queda con: catálogos maestros, datos sensibles completos y las
   compras a proveedores.
*/
BEGIN TRY
  BEGIN TRANSACTION

  -- Si ya no hay facturas, este paso ya se había corrido
  IF NOT EXISTS (SELECT 1 FROM Sales.Invoices)
  BEGIN
    THROW 50001, 'La fragmentación del Corporativo ya se aplicó en esta base', 1
  END

  -- Movimientos de inventario por ventas.
  -- Solo se quedan los que no tienen factura ni cliente (compras a proveedores).
  DELETE FROM Warehouse.StockItemTransactions
  WHERE InvoiceID IS NOT NULL OR CustomerID IS NOT NULL
  
  /*
    Facturación:
        TRUNCATE vacía la tabla completa, más rápido y casi sin usar log.
        Invoices lleva DELETE porque otras tablas tienen llave foránea hacia ella.
  */
  TRUNCATE TABLE Sales.CustomerTransactions
  TRUNCATE TABLE Sales.InvoiceLines
  DELETE FROM Sales.Invoices

  -- Pedidos
  TRUNCATE TABLE Sales.OrderLines
  UPDATE Sales.Orders SET BackorderOrderID = NULL
  DELETE FROM Sales.Orders

  -- Inventario: cada sucursal maneja el suyo
  TRUNCATE TABLE Warehouse.StockItemHoldings

  COMMIT TRANSACTION
  SELECT 'Fragmentación del Corporativo aplicada' AS Resultado
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

-- Liberar espacio en el log de transacciones
CHECKPOINT
DBCC SHRINKFILE (WWI_Log, 100)
GO

-- Verificación final: el Corporativo debe tener los datos sensibles completos
SELECT 'Clientes' AS dato, COUNT(*) AS cantidad FROM Sales.Customers
UNION ALL SELECT 'Proveedores', COUNT(*) FROM Purchasing.Suppliers
UNION ALL SELECT 'Productos', COUNT(*) FROM Warehouse.StockItems
UNION ALL SELECT 'Facturas (debe ser 0)', COUNT(*) FROM Sales.Invoices
UNION ALL SELECT 'Pedidos (debe ser 0)', COUNT(*) FROM Sales.Orders
UNION ALL SELECT 'Inventario (debe ser 0)', COUNT(*) FROM Warehouse.StockItemHoldings
UNION ALL SELECT 'Ordenes de compra', COUNT(*) FROM Purchasing.PurchaseOrders
UNION ALL SELECT 'Movimientos de inventario (compras)', COUNT(*) FROM Warehouse.StockItemTransactions

-- Aquí es al revés que en las sucursales: las 3 deben salir con un número,
-- porque el Corporativo sí guarda los datos sensibles
SELECT COL_LENGTH('Sales.Customers', 'PhoneNumber') AS cliente_telefono,
       COL_LENGTH('Purchasing.Suppliers', 'BankAccountNumber') AS proveedor_cuenta,
       COL_LENGTH('Application.People', 'EmailAddress') AS persona_email
GO


---------- Seguridad y Cifrado de Contraseñas ----------


-- Confirmar en que BD vamos a trabajar
USE WWI_Corporativo
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
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'MasterKey_Corporativo*2026'
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

/*
   Tabla de usuarios del sistema
   El ID sale de una secuencia, igual que en el resto de WWI.
*/
CREATE SEQUENCE Sequences.UsuarioID AS int START WITH 1 INCREMENT BY 1
GO

CREATE TABLE dbo.Usuarios (
  iduser int NOT NULL CONSTRAINT DF_Usuarios_iduser DEFAULT (NEXT VALUE FOR Sequences.UsuarioID),
  username nvarchar(50) NOT NULL,
  password varbinary(256) NOT NULL, -- contraseña cifrada con LlaveUsuarios
  fullname nvarchar(100) NOT NULL,
  active bit NOT NULL CONSTRAINT DF_Usuarios_active DEFAULT 1,
  rol nvarchar(20) NOT NULL,
  email nvarchar(100) NULL,
  hiredate date NOT NULL,
  sucursal nvarchar(20) NULL, -- SanJose/Limon para Administrador, NULL para Corporativo
  CONSTRAINT PK_Usuarios PRIMARY KEY (iduser),
  CONSTRAINT UQ_Usuarios_username UNIQUE (username),
  CONSTRAINT CK_Usuarios_rol CHECK (rol IN ('Administrador', 'Corporativo')),
  CONSTRAINT CK_Usuarios_sucursal CHECK (
       (rol = 'Administrador' AND sucursal IN ('SanJose', 'Limon'))
    OR (rol = 'Corporativo' AND sucursal IS NULL))
)
GO

-- Stored procedures de usuarios

/*
  CrearUsuario: registra un usuario con la contraseña cifrada.
  Solo existe en el Corporativo (dueño del catálogo de usuarios);
  la replicación lo lleva a las sucursales.
*/
CREATE OR ALTER PROCEDURE dbo.CrearUsuario
  @username nvarchar(50),
  @password nvarchar(100),
  @fullname nvarchar(100),
  @rol nvarchar(20),
  @email nvarchar(100) = NULL,
  @hiredate date,
  @sucursal nvarchar(20) = NULL
WITH EXECUTE AS OWNER
AS
BEGIN
  SET XACT_ABORT ON
  BEGIN TRY
    BEGIN TRANSACTION

    IF EXISTS (SELECT 1 FROM dbo.Usuarios WHERE username = @username)
    BEGIN
      THROW 50030, 'Ya existe un usuario con ese nombre', 1
    END

    OPEN SYMMETRIC KEY LlaveUsuarios DECRYPTION BY CERTIFICATE CertificadoUsuarios

    INSERT INTO dbo.Usuarios (username, password, fullname, rol, email, hiredate, sucursal)
    VALUES (@username,
            EncryptByKey(Key_GUID('LlaveUsuarios'), @password),
            @fullname, @rol, @email, @hiredate, @sucursal)

    CLOSE SYMMETRIC KEY LlaveUsuarios

    COMMIT TRANSACTION
    SELECT iduser, username, rol, sucursal FROM dbo.Usuarios WHERE username = @username
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

/*
  ValidarUsuario: login del rol Corporativo.
  Devuelve 1 fila si el usuario y la contraseña son correctos, 0 si no.
  La contraseña nunca sale de la base de datos: se compara aquí adentro.
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
    -- COLLATE ..._CS_AS hace que distinga mayúsculas de minúsculas
    AND CONVERT(nvarchar(100), DecryptByKey(password)) = @password COLLATE Latin1_General_100_CS_AS
    AND active = 1
    AND rol = 'Corporativo'

  CLOSE SYMMETRIC KEY LlaveUsuarios
END
GO

/*
   Login de la API para el rol Corporativo
   Solo puede ejecutar stored procedures, nunca leer tablas.
*/
CREATE LOGIN api_corporativo
WITH PASSWORD = 'ApiCorp*2026', CHECK_POLICY = OFF, DEFAULT_DATABASE = WWI_Corporativo
GO

CREATE USER api_corporativo FOR LOGIN api_corporativo
CREATE ROLE rol_corporativo
ALTER ROLE rol_corporativo ADD MEMBER api_corporativo
GRANT EXECUTE ON dbo.ValidarUsuario TO rol_corporativo
GO

-- Pruebas

-- Usuario de prueba
EXEC dbo.CrearUsuario
  @username = 'prueba', @password = 'Prueba*123', @fullname = 'Usuario de Prueba',
  @rol = 'Corporativo', @email = 'prueba@wwi.com', @hiredate = '2026-11-02'

-- Así queda guardada la contraseña (cifrada, ilegible)
SELECT iduser, username, password FROM dbo.Usuarios

-- Login: correcto (1 fila), contraseña mala (0 filas), mayúsculas distintas (0 filas)
EXEC dbo.ValidarUsuario 'prueba', 'Prueba*123'
EXEC dbo.ValidarUsuario 'prueba', 'otra'
EXEC dbo.ValidarUsuario 'prueba', 'prueba*123'

-- Valor cifrado para probar la llave en las sucursales
OPEN SYMMETRIC KEY LlaveUsuarios DECRYPTION BY CERTIFICATE CertificadoUsuarios
SELECT EncryptByKey(Key_GUID('LlaveUsuarios'), N'Hola desde el Corporativo') AS valor_cifrado
CLOSE SYMMETRIC KEY LlaveUsuarios

-- Identificador de la llave
SELECT name, key_guid FROM sys.symmetric_keys WHERE name = 'LlaveUsuarios'

-- Borrar el usuario de prueba
DELETE FROM dbo.Usuarios WHERE username = 'prueba'
ALTER SEQUENCE Sequences.UsuarioID RESTART WITH 1
GO
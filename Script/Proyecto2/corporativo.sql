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


---------- Replicación transaccional ----------


-- Verificar el nombre del servidor: debe ser sqlcorporativo
USE master
GO
SELECT @@SERVERNAME AS servidor
GO


/*
   Configurar el Distribuidor y la base de distribución
   El Corporativo es su propio distribuidor (al igual como se ve en el tutorial de
   Learn para Linux). Se crea la base "distribution", donde se guardan los
   cambios mientras se envían a las sucursales.
*/
EXEC sp_adddistributor @distributor = N'sqlcorporativo'
GO

EXEC sp_adddistributiondb
  @database = N'distribution',
  @log_file_size = 2,
  @deletebatchsize_xact = 5000,
  @deletebatchsize_cmd = 2000,
  @security_mode = 0,
  @login = N'sa',
  @password = N'WWI_Bases2*2026'
GO

-- Carpeta de trabajo de los agentes, creadas en el contenedor Docker
USE distribution
GO
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name = 'UIProperties' AND type = 'U')
  CREATE TABLE UIProperties (id int)

IF EXISTS (SELECT * FROM ::fn_listextendedproperty('SnapshotFolder', 'user', 'dbo', 'table', 'UIProperties', NULL, NULL))
  EXEC sp_updateextendedproperty N'SnapshotFolder', N'/var/opt/mssql/data/ReplData/', 'user', dbo, 'table', 'UIProperties'
ELSE
  EXEC sp_addextendedproperty N'SnapshotFolder', N'/var/opt/mssql/data/ReplData/', 'user', dbo, 'table', 'UIProperties'
GO

-- El Corporativo queda registrado como publicador de este distribuidor
EXEC sp_adddistpublisher
  @publisher = N'sqlcorporativo',
  @distribution_db = N'distribution',
  @security_mode = 0,
  @login = N'sa',
  @password = N'WWI_Bases2*2026',
  @working_directory = N'/var/opt/mssql/data/ReplData',
  @trusted = N'false',
  @thirdparty_flag = 0,
  @publisher_type = N'MSSQLSERVER'
GO


/*
   Habilitar WWI_Corporativo para publicar y crear el Log Reader
   El Log Reader lee el log de transacciones y manda los cambios
   (INSERT / UPDATE / DELETE) de las tablas publicadas al distribuidor.
*/
USE WWI_Corporativo
GO

EXEC sp_replicationdboption
  @dbname = N'WWI_Corporativo',
  @optname = N'publish',
  @value = N'true'
GO

EXEC sp_addlogreader_agent
  @job_login = NULL,
  @job_password = NULL,
  @publisher_security_mode = 0,
  @publisher_login = N'sa',
  @publisher_password = N'WWI_Bases2*2026'
GO


/*
   Crear la Publicación transaccional
   - repl_freq = continuous: los cambios se envían apenas ocurren
   - allow_push: los agentes corren en el Corporativo
   - immediate_sync = false: no se necesita snapshot (las sucursales ya tienen los datos)
   - retention = 0: las suscripciones nunca expiran
*/
EXEC sp_addpublication
  @publication = N'CatalogosWWI',
  @description = N'Catalogos de Wide World Importers: del Corporativo a San Jose y Limon',
  @sync_method = N'concurrent',
  @retention = 0,
  @allow_push = N'true',
  @allow_pull = N'false',
  @allow_anonymous = N'false',
  @immediate_sync = N'false',
  @independent_agent = N'true',
  @repl_freq = N'continuous',
  @status = N'active'
GO


/*
   Artículos: las tablas que se replican
   pre_creation_cmd = none: si algún día se aplica un snapshot, nunca se borran las tablas de las sucursales.
*/

-- Productos
EXEC sp_addarticle @publication = N'CatalogosWWI', @article = N'StockItems',           @source_owner = N'Warehouse', @source_object = N'StockItems',           @destination_owner = N'Warehouse', @destination_table = N'StockItems',           @type = N'logbased', @pre_creation_cmd = N'none', @identityrangemanagementoption = N'manual'
EXEC sp_addarticle @publication = N'CatalogosWWI', @article = N'StockGroups',          @source_owner = N'Warehouse', @source_object = N'StockGroups',          @destination_owner = N'Warehouse', @destination_table = N'StockGroups',          @type = N'logbased', @pre_creation_cmd = N'none', @identityrangemanagementoption = N'manual'
EXEC sp_addarticle @publication = N'CatalogosWWI', @article = N'StockItemStockGroups', @source_owner = N'Warehouse', @source_object = N'StockItemStockGroups', @destination_owner = N'Warehouse', @destination_table = N'StockItemStockGroups', @type = N'logbased', @pre_creation_cmd = N'none', @identityrangemanagementoption = N'manual'
EXEC sp_addarticle @publication = N'CatalogosWWI', @article = N'Colors',               @source_owner = N'Warehouse', @source_object = N'Colors',               @destination_owner = N'Warehouse', @destination_table = N'Colors',               @type = N'logbased', @pre_creation_cmd = N'none', @identityrangemanagementoption = N'manual'
EXEC sp_addarticle @publication = N'CatalogosWWI', @article = N'PackageTypes',         @source_owner = N'Warehouse', @source_object = N'PackageTypes',         @destination_owner = N'Warehouse', @destination_table = N'PackageTypes',         @type = N'logbased', @pre_creation_cmd = N'none', @identityrangemanagementoption = N'manual'

-- Catálogos generales
-- Cities, StateProvinces y Countries tienen columnas geography: se usa la opción de esquema
-- por defecto (0x30F3) sin 0x20, porque 0x20 convierte geography a image y la replicación falla
EXEC sp_addarticle @publication = N'CatalogosWWI', @article = N'Cities',             @source_owner = N'Application', @source_object = N'Cities',             @destination_owner = N'Application', @destination_table = N'Cities',             @type = N'logbased', @pre_creation_cmd = N'none', @identityrangemanagementoption = N'manual', @schema_option = 0x00000000000030D3
EXEC sp_addarticle @publication = N'CatalogosWWI', @article = N'StateProvinces',     @source_owner = N'Application', @source_object = N'StateProvinces',     @destination_owner = N'Application', @destination_table = N'StateProvinces',     @type = N'logbased', @pre_creation_cmd = N'none', @identityrangemanagementoption = N'manual', @schema_option = 0x00000000000030D3
EXEC sp_addarticle @publication = N'CatalogosWWI', @article = N'Countries',          @source_owner = N'Application', @source_object = N'Countries',          @destination_owner = N'Application', @destination_table = N'Countries',          @type = N'logbased', @pre_creation_cmd = N'none', @identityrangemanagementoption = N'manual', @schema_option = 0x00000000000030D3
EXEC sp_addarticle @publication = N'CatalogosWWI', @article = N'DeliveryMethods',    @source_owner = N'Application', @source_object = N'DeliveryMethods',    @destination_owner = N'Application', @destination_table = N'DeliveryMethods',    @type = N'logbased', @pre_creation_cmd = N'none', @identityrangemanagementoption = N'manual'
EXEC sp_addarticle @publication = N'CatalogosWWI', @article = N'PaymentMethods',     @source_owner = N'Application', @source_object = N'PaymentMethods',     @destination_owner = N'Application', @destination_table = N'PaymentMethods',     @type = N'logbased', @pre_creation_cmd = N'none', @identityrangemanagementoption = N'manual'
EXEC sp_addarticle @publication = N'CatalogosWWI', @article = N'TransactionTypes',   @source_owner = N'Application', @source_object = N'TransactionTypes',   @destination_owner = N'Application', @destination_table = N'TransactionTypes',   @type = N'logbased', @pre_creation_cmd = N'none', @identityrangemanagementoption = N'manual'
EXEC sp_addarticle @publication = N'CatalogosWWI', @article = N'CustomerCategories', @source_owner = N'Sales',       @source_object = N'CustomerCategories', @destination_owner = N'Sales',       @destination_table = N'CustomerCategories', @type = N'logbased', @pre_creation_cmd = N'none', @identityrangemanagementoption = N'manual'
EXEC sp_addarticle @publication = N'CatalogosWWI', @article = N'BuyingGroups',       @source_owner = N'Sales',       @source_object = N'BuyingGroups',       @destination_owner = N'Sales',       @destination_table = N'BuyingGroups',       @type = N'logbased', @pre_creation_cmd = N'none', @identityrangemanagementoption = N'manual'
EXEC sp_addarticle @publication = N'CatalogosWWI', @article = N'SpecialDeals',       @source_owner = N'Sales',       @source_object = N'SpecialDeals',       @destination_owner = N'Sales',       @destination_table = N'SpecialDeals',       @type = N'logbased', @pre_creation_cmd = N'none', @identityrangemanagementoption = N'manual'
EXEC sp_addarticle @publication = N'CatalogosWWI', @article = N'SupplierCategories', @source_owner = N'Purchasing',  @source_object = N'SupplierCategories', @destination_owner = N'Purchasing',  @destination_table = N'SupplierCategories', @type = N'logbased', @pre_creation_cmd = N'none', @identityrangemanagementoption = N'manual'

-- Nuestras tablas
EXEC sp_addarticle @publication = N'CatalogosWWI', @article = N'AsignacionSucursal', @source_owner = N'dbo', @source_object = N'AsignacionSucursal', @destination_owner = N'dbo', @destination_table = N'AsignacionSucursal', @type = N'logbased', @pre_creation_cmd = N'none', @identityrangemanagementoption = N'manual'
EXEC sp_addarticle @publication = N'CatalogosWWI', @article = N'Usuarios',           @source_owner = N'dbo', @source_object = N'Usuarios',           @destination_owner = N'dbo', @destination_table = N'Usuarios',           @type = N'logbased', @pre_creation_cmd = N'none', @identityrangemanagementoption = N'manual'

-- Las 3 tablas con Fragmentación Vertical: vertical_partition = true
EXEC sp_addarticle @publication = N'CatalogosWWI', @article = N'Customers', @source_owner = N'Sales',       @source_object = N'Customers', @destination_owner = N'Sales',       @destination_table = N'Customers', @type = N'logbased', @pre_creation_cmd = N'none', @identityrangemanagementoption = N'manual', @vertical_partition = N'true'
EXEC sp_addarticle @publication = N'CatalogosWWI', @article = N'Suppliers', @source_owner = N'Purchasing',  @source_object = N'Suppliers', @destination_owner = N'Purchasing',  @destination_table = N'Suppliers', @type = N'logbased', @pre_creation_cmd = N'none', @identityrangemanagementoption = N'manual', @vertical_partition = N'true'
EXEC sp_addarticle @publication = N'CatalogosWWI', @article = N'People',    @source_owner = N'Application', @source_object = N'People',    @destination_owner = N'Application', @destination_table = N'People',    @type = N'logbased', @pre_creation_cmd = N'none', @identityrangemanagementoption = N'manual', @vertical_partition = N'true'
GO


/*
   Filtro de columnas (fragmentación vertical en la replicación)
   Según Learn: primero se agregan todas las columnas (@column = NULL)
   y después se quita, una por una, cada columna que NO se publica.
   Al final sp_articleview crea los objetos de sincronización.
*/

-- Clientes: todas menos contacto y direcciones
EXEC sp_articlecolumn @publication = N'CatalogosWWI', @article = N'Customers', @column = NULL, @operation = N'add'
EXEC sp_articlecolumn @publication = N'CatalogosWWI', @article = N'Customers', @column = N'PrimaryContactPersonID',   @operation = N'drop'
EXEC sp_articlecolumn @publication = N'CatalogosWWI', @article = N'Customers', @column = N'AlternateContactPersonID', @operation = N'drop'
EXEC sp_articlecolumn @publication = N'CatalogosWWI', @article = N'Customers', @column = N'PhoneNumber',              @operation = N'drop'
EXEC sp_articlecolumn @publication = N'CatalogosWWI', @article = N'Customers', @column = N'FaxNumber',                @operation = N'drop'
EXEC sp_articlecolumn @publication = N'CatalogosWWI', @article = N'Customers', @column = N'WebsiteURL',               @operation = N'drop'
EXEC sp_articlecolumn @publication = N'CatalogosWWI', @article = N'Customers', @column = N'DeliveryAddressLine1',     @operation = N'drop'
EXEC sp_articlecolumn @publication = N'CatalogosWWI', @article = N'Customers', @column = N'DeliveryAddressLine2',     @operation = N'drop'
EXEC sp_articlecolumn @publication = N'CatalogosWWI', @article = N'Customers', @column = N'DeliveryPostalCode',       @operation = N'drop'
EXEC sp_articlecolumn @publication = N'CatalogosWWI', @article = N'Customers', @column = N'DeliveryLocation',         @operation = N'drop'
EXEC sp_articlecolumn @publication = N'CatalogosWWI', @article = N'Customers', @column = N'PostalAddressLine1',       @operation = N'drop'
EXEC sp_articlecolumn @publication = N'CatalogosWWI', @article = N'Customers', @column = N'PostalAddressLine2',       @operation = N'drop'
EXEC sp_articlecolumn @publication = N'CatalogosWWI', @article = N'Customers', @column = N'PostalPostalCode',         @operation = N'drop'
EXEC sp_articleview   @publication = N'CatalogosWWI', @article = N'Customers'

-- Proveedores: todas menos contacto, direcciones y datos bancarios
EXEC sp_articlecolumn @publication = N'CatalogosWWI', @article = N'Suppliers', @column = NULL, @operation = N'add'
EXEC sp_articlecolumn @publication = N'CatalogosWWI', @article = N'Suppliers', @column = N'PrimaryContactPersonID',   @operation = N'drop'
EXEC sp_articlecolumn @publication = N'CatalogosWWI', @article = N'Suppliers', @column = N'AlternateContactPersonID', @operation = N'drop'
EXEC sp_articlecolumn @publication = N'CatalogosWWI', @article = N'Suppliers', @column = N'BankAccountName',          @operation = N'drop'
EXEC sp_articlecolumn @publication = N'CatalogosWWI', @article = N'Suppliers', @column = N'BankAccountBranch',        @operation = N'drop'
EXEC sp_articlecolumn @publication = N'CatalogosWWI', @article = N'Suppliers', @column = N'BankAccountCode',          @operation = N'drop'
EXEC sp_articlecolumn @publication = N'CatalogosWWI', @article = N'Suppliers', @column = N'BankAccountNumber',        @operation = N'drop'
EXEC sp_articlecolumn @publication = N'CatalogosWWI', @article = N'Suppliers', @column = N'BankInternationalCode',    @operation = N'drop'
EXEC sp_articlecolumn @publication = N'CatalogosWWI', @article = N'Suppliers', @column = N'PhoneNumber',              @operation = N'drop'
EXEC sp_articlecolumn @publication = N'CatalogosWWI', @article = N'Suppliers', @column = N'FaxNumber',                @operation = N'drop'
EXEC sp_articlecolumn @publication = N'CatalogosWWI', @article = N'Suppliers', @column = N'WebsiteURL',               @operation = N'drop'
EXEC sp_articlecolumn @publication = N'CatalogosWWI', @article = N'Suppliers', @column = N'DeliveryAddressLine1',     @operation = N'drop'
EXEC sp_articlecolumn @publication = N'CatalogosWWI', @article = N'Suppliers', @column = N'DeliveryAddressLine2',     @operation = N'drop'
EXEC sp_articlecolumn @publication = N'CatalogosWWI', @article = N'Suppliers', @column = N'DeliveryPostalCode',       @operation = N'drop'
EXEC sp_articlecolumn @publication = N'CatalogosWWI', @article = N'Suppliers', @column = N'DeliveryLocation',         @operation = N'drop'
EXEC sp_articlecolumn @publication = N'CatalogosWWI', @article = N'Suppliers', @column = N'PostalAddressLine1',       @operation = N'drop'
EXEC sp_articlecolumn @publication = N'CatalogosWWI', @article = N'Suppliers', @column = N'PostalAddressLine2',       @operation = N'drop'
EXEC sp_articlecolumn @publication = N'CatalogosWWI', @article = N'Suppliers', @column = N'PostalPostalCode',         @operation = N'drop'
EXEC sp_articleview   @publication = N'CatalogosWWI', @article = N'Suppliers'

-- Personas: todas menos usuario, contraseña y forma de contacto
EXEC sp_articlecolumn @publication = N'CatalogosWWI', @article = N'People', @column = NULL, @operation = N'add'
EXEC sp_articlecolumn @publication = N'CatalogosWWI', @article = N'People', @column = N'LogonName',       @operation = N'drop'
EXEC sp_articlecolumn @publication = N'CatalogosWWI', @article = N'People', @column = N'HashedPassword',  @operation = N'drop'
EXEC sp_articlecolumn @publication = N'CatalogosWWI', @article = N'People', @column = N'PhoneNumber',     @operation = N'drop'
EXEC sp_articlecolumn @publication = N'CatalogosWWI', @article = N'People', @column = N'FaxNumber',       @operation = N'drop'
EXEC sp_articlecolumn @publication = N'CatalogosWWI', @article = N'People', @column = N'EmailAddress',    @operation = N'drop'
EXEC sp_articlecolumn @publication = N'CatalogosWWI', @article = N'People', @column = N'Photo',           @operation = N'drop'
EXEC sp_articlecolumn @publication = N'CatalogosWWI', @article = N'People', @column = N'UserPreferences', @operation = N'drop'
EXEC sp_articleview   @publication = N'CatalogosWWI', @article = N'People'
GO


/*
   Suscripciones Push (sin snapshot: 'replication support only')
   - San José: se conecta con usuario_corporativo (db_owner en WWI_SanJose)
   - Limón: se conecta con sa
   frequency_type = 64: el agente corre en modo continuo.
*/

-- San José (Windows)
EXEC sp_addsubscription
  @publication = N'CatalogosWWI',
  @subscriber = N'DESKTOP-8CTQSKC',
  @destination_db = N'WWI_SanJose',
  @subscription_type = N'Push',
  @sync_type = N'replication support only',
  @article = N'all',
  @update_mode = N'read only',
  @subscriber_type = 0

EXEC sp_addpushsubscription_agent
  @publication = N'CatalogosWWI',
  @subscriber = N'DESKTOP-8CTQSKC',
  @subscriber_db = N'WWI_SanJose',
  @subscriber_security_mode = 0,
  @subscriber_login = N'usuario_corporativo',
  @subscriber_password = N'Corp_WWI*2026',
  @frequency_type = 64
GO

-- Limón (Red Hat)
EXEC sp_addsubscription
  @publication = N'CatalogosWWI',
  @subscriber = N'sqllimon',
  @destination_db = N'WWI_Limon',
  @subscription_type = N'Push',
  @sync_type = N'replication support only',
  @article = N'all',
  @update_mode = N'read only',
  @subscriber_type = 0

EXEC sp_addpushsubscription_agent
  @publication = N'CatalogosWWI',
  @subscriber = N'sqllimon',
  @subscriber_db = N'WWI_Limon',
  @subscriber_security_mode = 0,
  @subscriber_login = N'sa',
  @subscriber_password = N'WWI_Bases2*2026',
  @frequency_type = 64
GO


/*
   Arrancar los agentes
   Esta consulta arma los comandos para arrancar el Log Reader y los dos agentes de distribución.
*/
SELECT 'EXEC msdb.dbo.sp_start_job N''' + j.name + '''' AS ejecutar_esto, c.name AS tipo
FROM msdb.dbo.sysjobs j
INNER JOIN msdb.dbo.syscategories c ON c.category_id = j.category_id
WHERE c.name IN ('REPL-LogReader', 'REPL-Distribution')
GO


/*
   Revisar que los agentes estén trabajando
*/
-- Publicación y artículos
SELECT p.publication, COUNT(a.article_id) AS articulos
FROM distribution.dbo.MSpublications p
INNER JOIN distribution.dbo.MSarticles a ON a.publication_id = p.publication_id
GROUP BY p.publication

-- Últimos mensajes del Log Reader
SELECT TOP 5 time, comments
FROM distribution.dbo.MSlogreader_history
ORDER BY time DESC

-- Últimos mensajes de cada agente de distribución
SELECT TOP 10 a.subscriber_db, h.time, h.comments
FROM distribution.dbo.MSdistribution_history h
INNER JOIN distribution.dbo.MSdistribution_agents a ON a.id = h.agent_id
ORDER BY h.time DESC
GO

-- Prueba #1
USE WWI_Corporativo
GO
UPDATE Warehouse.StockItems
SET RecommendedRetailPrice = RecommendedRetailPrice + 1
WHERE StockItemID = 1

SELECT StockItemID, StockItemName, RecommendedRetailPrice
FROM Warehouse.StockItems WHERE StockItemID = 1

-- Regreso el precio original
UPDATE Warehouse.StockItems
SET RecommendedRetailPrice = RecommendedRetailPrice - 1
WHERE StockItemID = 1


-- Prueba #2
USE WWI_Corporativo
GO
EXEC dbo.CrearUsuario
  @username = 'corporativo', @password = 'Corporativo*2026', @fullname = 'Gerencia Corporativa',
  @rol = 'Corporativo', @email = 'corporativo@wwi.com', @hiredate = '2026-01-15'

EXEC dbo.CrearUsuario
  @username = 'admin_sanjose', @password = 'SanJose*2026', @fullname = 'Administrador San José',
  @rol = 'Administrador', @email = 'admin.sanjose@wwi.com', @hiredate = '2026-02-01', @sucursal = 'SanJose'

EXEC dbo.CrearUsuario
  @username = 'admin_limon', @password = 'Limon*2026', @fullname = 'Administrador Limón',
  @rol = 'Administrador', @email = 'admin.limon@wwi.com', @hiredate = '2026-02-01', @sucursal = 'Limon'
GO


---------- Linked servers ----------


/*
   Login que usan las sucursales (linked server CORPORATIVO).
   Solo puede leer las 3 tablas con datos sensibles, para reconstruir
   el detalle completo de clientes, proveedores y personas.
*/
USE WWI_Corporativo
GO
CREATE LOGIN lectura_sucursal
WITH PASSWORD = 'LecturaSuc*2026', CHECK_POLICY = OFF, DEFAULT_DATABASE = WWI_Corporativo
GO
CREATE USER lectura_sucursal FOR LOGIN lectura_sucursal
GO

/*
   Fragmentos Sensibles (fragmentación vertical).
   Cada vista tiene la llave primaria + los datos de privacidad / forma de contacto.
   Las sucursales leen estas vistas por linked server para reconstruir el detalle
   completo de un cliente, proveedor o persona.
   La ubicación (geography) se expone como latitud y longitud porque SQL Server
   no permite tipos CLR en consultas distribuidas.
*/
CREATE OR ALTER VIEW dbo.ClientesSensibles
AS
SELECT
  CustomerID,
  PrimaryContactPersonID,
  AlternateContactPersonID,
  PhoneNumber,
  FaxNumber,
  WebsiteURL,
  DeliveryAddressLine1,
  DeliveryAddressLine2,
  DeliveryPostalCode,
  DeliveryLocation.Lat AS Latitud,
  DeliveryLocation.Long AS Longitud,
  PostalAddressLine1,
  PostalAddressLine2,
  PostalPostalCode
FROM Sales.Customers
GO

CREATE OR ALTER VIEW dbo.ProveedoresSensibles
AS
SELECT
  SupplierID,
  PrimaryContactPersonID,
  AlternateContactPersonID,
  BankAccountName,
  BankAccountBranch,
  BankAccountCode,
  BankAccountNumber,
  BankInternationalCode,
  PhoneNumber,
  FaxNumber,
  WebsiteURL,
  DeliveryAddressLine1,
  DeliveryAddressLine2,
  DeliveryPostalCode,
  DeliveryLocation.Lat  AS Latitud,
  DeliveryLocation.Long AS Longitud,
  PostalAddressLine1,
  PostalAddressLine2,
  PostalPostalCode
FROM Purchasing.Suppliers
GO

CREATE OR ALTER VIEW dbo.PersonasSensibles
AS
SELECT
  PersonID,
  LogonName,
  PhoneNumber,
  FaxNumber,
  EmailAddress
FROM Application.People
GO

-- El login de las sucursales SOLO puede leer las 3 vistas, no las tablas
GRANT SELECT ON dbo.ClientesSensibles TO lectura_sucursal
GRANT SELECT ON dbo.ProveedoresSensibles TO lectura_sucursal
GRANT SELECT ON dbo.PersonasSensibles TO lectura_sucursal
GO

/*
   Linked servers hacia las sucursales.
   - @server: el nombre que usamos en las consultas (SANJOSE / LIMON)
   - @datasrc: el servidor real
   - Proveedor MSOLEDBSQL, el recomendado por Microsoft Learn
*/
USE master
GO
EXEC sp_addlinkedserver
  @server = N'SANJOSE',
  @srvproduct = N'',
  @provider = N'MSOLEDBSQL',
  @datasrc = N'DESKTOP-8CTQSKC'

EXEC sp_addlinkedsrvlogin
  @rmtsrvname = N'SANJOSE',
  @useself = N'False',
  @locallogin = NULL,
  @rmtuser = N'lectura_corporativo',
  @rmtpassword = N'LecturaCorp*2026'

-- Si San José no responde en 5 segundos, la consulta falla (no se queda esperando)
EXEC sp_serveroption @server = N'SANJOSE', @optname = N'connect timeout', @optvalue = N'5'
GO

EXEC sp_addlinkedserver
  @server = N'LIMON',
  @srvproduct = N'',
  @provider = N'MSOLEDBSQL',
  @datasrc = N'sqllimon'

EXEC sp_addlinkedsrvlogin
  @rmtsrvname = N'LIMON',
  @useself = N'False',
  @locallogin = NULL,
  @rmtuser = N'lectura_corporativo',
  @rmtpassword = N'LecturaCorp*2026'

EXEC sp_serveroption @server = N'LIMON', @optname = N'connect timeout', @optvalue = N'5'
GO

/*
   Pruebas de los linked servers
*/
-- Facturas de cada sucursal consultadas desde el Corporativo
SELECT 'San José' AS sucursal, COUNT(*) AS facturas FROM SANJOSE.WWI_SanJose.Sales.Invoices
UNION ALL
SELECT 'Limón', COUNT(*) FROM LIMON.WWI_Limon.Sales.Invoices

-- Primera consulta distribuida: total vendido por sucursal y consolidado
SELECT 'San José' AS sucursal, SUM(il.ExtendedPrice) AS total_vendido
FROM SANJOSE.WWI_SanJose.Sales.InvoiceLines il
UNION ALL
SELECT 'Limón', SUM(il.ExtendedPrice)
FROM LIMON.WWI_Limon.Sales.InvoiceLines il
GO


---------- Persona PagWeb (la replicación la lleva a las sucursales) ----------


USE WWI_Corporativo
GO
INSERT INTO personas (
  FullName, PreferredName, IsPermittedToLogon, IsExternalLogonProvider,
  IsSystemUser, IsEmployee, IsSalesperson, LastEditedBy
)
VALUES ('PagWeb', 'PagWeb', 0, 0, 1, 1, 0, 1)
GO

SELECT PersonID, FullName FROM personas WHERE FullName = 'PagWeb'
GO


---------- Productos y concurrencia (solo en el Corporativo) ----------


USE WWI_Corporativo
GO

/*
  AgregarNuevoProducto
  Crea el producto en el catálogo maestro. La replicación lo lleva a las
  sucursales, y el trigger de cada sucursal le crea su inventario en 0.
  Concurrencia: UPDLOCK + HOLDLOCK bloquean la búsqueda por nombre hasta el
  COMMIT, así dos sucursales no pueden crear el mismo producto a la vez.
*/
CREATE OR ALTER PROCEDURE AgregarNuevoProducto
  @Nombre_Producto nvarchar(100),
  @ProveedorID int,
  @ColorID int = NULL,
  @UnitPackageID int,
  @OuterPackageID int,
  @Marca nvarchar(50) = NULL,
  @Size nvarchar(20) = NULL,
  @QuantityPerOuter int,
  @TaxRate decimal(18, 3),
  @UnitPrice decimal(18, 2),
  @RecommendedPrice decimal(18, 2) = NULL,
  @TypicalWeight decimal(18, 3),
  @MarketingSearchDetails nvarchar(MAX),
  @Grupos_Productos nvarchar(100)
AS
BEGIN
  SET XACT_ABORT ON
  DECLARE @PersonaEncargadaID int
  DECLARE @ID_Producto int
  BEGIN TRY
    BEGIN TRANSACTION

    IF EXISTS (
      SELECT 1
      FROM productos p WITH (UPDLOCK, HOLDLOCK)
      WHERE p.StockItemName = @Nombre_Producto
    )
    BEGIN
      THROW 50002, 'Ya existe un producto con ese nombre', 1
    END

    SELECT @PersonaEncargadaID = p.PersonID
    FROM personas p
    WHERE FullName = 'PagWeb'

    INSERT INTO productos (
      StockItemName, SupplierID, ColorID, UnitPackageID, OuterPackageID,
      Brand, Size, LeadTimeDays, QuantityPerOuter, IsChillerStock,
      TaxRate, UnitPrice, RecommendedRetailPrice, TypicalWeightPerUnit,
      MarketingComments, LastEditedBy
    )
    VALUES (
      @Nombre_Producto, @ProveedorID, @ColorID, @UnitPackageID, @OuterPackageID,
      @Marca, @Size, 7, @QuantityPerOuter, 0,
      @TaxRate, @UnitPrice, @RecommendedPrice, @TypicalWeight,
      @MarketingSearchDetails, @PersonaEncargadaID
    )

    SELECT @ID_Producto = p.StockItemID
    FROM productos p
    WHERE p.StockItemName = @Nombre_Producto

    INSERT INTO grupos_productos (StockItemID, StockGroupID, LastEditedBy)
    SELECT @ID_Producto, CAST(value AS int), @PersonaEncargadaID
    FROM STRING_SPLIT(@Grupos_Productos, ',')

    COMMIT TRANSACTION

    SELECT StockItemID, CONVERT(varchar(27), ValidFrom, 121) AS Version
    FROM productos WHERE StockItemID = @ID_Producto
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
  EditarDatosProducto
  Control de concurrencia Optimista: @Version es el ValidFrom que tenía el
  producto cuando el usuario lo abrió. El UPDATE solo se hace si la versión
  sigue igual; si otro usuario lo modificó antes, no se actualiza ninguna
  fila y se avisa. Cada modificación pone una versión nueva (SYSUTCDATETIME).
*/
CREATE OR ALTER PROCEDURE EditarDatosProducto
  @ID_Producto int,
  @Version varchar(27),
  @Nombre_Producto nvarchar(100) = NULL,
  @ColorID int = NULL,
  @UnitPackageID int = NULL,
  @OuterPackageID int = NULL,
  @Marca nvarchar(50) = NULL,
  @Size nvarchar(20) = NULL,
  @QuantityPerOuter int = NULL,
  @TaxRate decimal(18, 3) = NULL,
  @UnitPrice decimal(18, 2) = NULL,
  @RecommendedPrice decimal(18, 2) = NULL,
  @TypicalWeight decimal(18, 3) = NULL,
  @MarketingSearchDetails nvarchar(MAX) = NULL,
  @Grupos_Productos nvarchar(100) = NULL
AS
BEGIN
  SET XACT_ABORT ON
  DECLARE @PersonaEncargadaID int
  BEGIN TRY
    BEGIN TRANSACTION

    IF NOT EXISTS (SELECT 1 FROM productos p WHERE p.StockItemID = @ID_Producto)
    BEGIN
      THROW 50017, 'El producto indicado no existe', 1
    END

    IF @Nombre_Producto IS NOT NULL AND EXISTS (
      SELECT 1
      FROM productos p WITH (UPDLOCK, HOLDLOCK)
      WHERE p.StockItemName = @Nombre_Producto AND p.StockItemID <> @ID_Producto
    )
    BEGIN
      THROW 50018, 'Ya existe un producto con ese nombre', 1
    END

    UPDATE productos
    SET
      StockItemName = ISNULL(@Nombre_Producto, StockItemName),
      ColorID = ISNULL(@ColorID, ColorID),
      UnitPackageID = ISNULL(@UnitPackageID, UnitPackageID),
      OuterPackageID = ISNULL(@OuterPackageID, OuterPackageID),
      UnitPrice = ISNULL(@UnitPrice, UnitPrice),
      Brand = ISNULL(@Marca, Brand),
      Size = ISNULL(@Size, Size),
      QuantityPerOuter = ISNULL(@QuantityPerOuter, QuantityPerOuter),
      TaxRate = ISNULL(@TaxRate, TaxRate),
      RecommendedRetailPrice = ISNULL(@RecommendedPrice, RecommendedRetailPrice),
      TypicalWeightPerUnit = ISNULL(@TypicalWeight, TypicalWeightPerUnit),
      MarketingComments = ISNULL(@MarketingSearchDetails, MarketingComments),
      ValidFrom = SYSUTCDATETIME()
    WHERE StockItemID = @ID_Producto
      AND CONVERT(varchar(27), ValidFrom, 121) = @Version

    IF @@ROWCOUNT = 0
    BEGIN
      THROW 50040, 'El producto fue modificado por otro usuario. Recargue los datos e intente de nuevo', 1
    END

    IF @Grupos_Productos IS NOT NULL
    BEGIN
      SELECT @PersonaEncargadaID = p.PersonID FROM personas p WHERE FullName = 'PagWeb'

      DELETE FROM grupos_productos WHERE StockItemID = @ID_Producto

      INSERT INTO grupos_productos (StockItemID, StockGroupID, LastEditedBy)
      SELECT @ID_Producto, CAST(value AS int), @PersonaEncargadaID
      FROM STRING_SPLIT(@Grupos_Productos, ',')
    END

    COMMIT TRANSACTION

    SELECT StockItemID, CONVERT(varchar(27), ValidFrom, 121) AS Version
    FROM productos WHERE StockItemID = @ID_Producto
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
  EliminarProducto
  1. Valida en el Corporativo (compras, movimientos y ofertas).
  2. Verifica que las dos sucursales respondan (sp_testlinkedserver). Si una no
     responde, no se borra: no se puede asegurar que el producto no tenga ventas ahí.
  3. Consulta en cada sucursal si el producto tiene ventas, pedidos, movimientos
     o inventario. Esas consultas van en sp_executesql para que solo se compilen
     si la sucursal respondió.
  4. Borra solo en el Corporativo; la replicación lo borra en las sucursales.
  Las consultas remotas van antes de la transacción, para que no se convierta
  en una transacción distribuida (MSDTC).
*/
CREATE OR ALTER PROCEDURE EliminarProducto
  @ID_Producto int
AS
BEGIN
  SET XACT_ABORT ON
  DECLARE @usos_sanjose int
  DECLARE @usos_limon int
  DECLARE @sql nvarchar(MAX)
  BEGIN TRY

    IF NOT EXISTS (SELECT 1 FROM productos p WHERE p.StockItemID = @ID_Producto)
    BEGIN
      THROW 50017, 'El producto indicado no existe', 1
    END

    -- 1. Validaciones en el Corporativo
    IF EXISTS (SELECT 1 FROM detalle_ordenes d WHERE d.StockItemID = @ID_Producto)
    BEGIN
      THROW 50019, 'El producto indicado se encuentra asociado a una orden de compra', 1
    END

    IF EXISTS (SELECT 1 FROM transacciones_productos t WHERE t.StockItemID = @ID_Producto)
    BEGIN
      THROW 50022, 'El producto indicado se encuentra asociado a una transacción', 1
    END

    IF EXISTS (SELECT 1 FROM ofertas o WHERE o.StockItemID = @ID_Producto)
    BEGIN
      THROW 50021, 'El producto indicado se encuentra asociado a una oferta especial', 1
    END

    -- 2. ¿Responden las dos sucursales?
    BEGIN TRY
      EXEC sp_testlinkedserver N'SANJOSE'
    END TRY
    BEGIN CATCH
      THROW 50023, 'No se puede eliminar: la sucursal San José no responde', 1
    END CATCH

    BEGIN TRY
      EXEC sp_testlinkedserver N'LIMON'
    END TRY
    BEGIN CATCH
      THROW 50024, 'No se puede eliminar: la sucursal Limón no responde', 1
    END CATCH

    -- 3. ¿Tiene ventas, pedidos, movimientos o inventario en las sucursales?
    SET @sql = N'
      SELECT @usos =
          (SELECT COUNT(*) FROM SANJOSE.WWI_SanJose.Sales.InvoiceLines WHERE StockItemID = @id)
        + (SELECT COUNT(*) FROM SANJOSE.WWI_SanJose.Sales.OrderLines WHERE StockItemID = @id)
        + (SELECT COUNT(*) FROM SANJOSE.WWI_SanJose.Warehouse.StockItemTransactions WHERE StockItemID = @id)
        + (SELECT COUNT(*) FROM SANJOSE.WWI_SanJose.Warehouse.StockItemHoldings WHERE StockItemID = @id AND QuantityOnHand > 0)'
    EXEC sp_executesql @sql, N'@id int, @usos int OUTPUT', @id = @ID_Producto, @usos = @usos_sanjose OUTPUT

    SET @sql = N'
      SELECT @usos =
          (SELECT COUNT(*) FROM LIMON.WWI_Limon.Sales.InvoiceLines WHERE StockItemID = @id)
        + (SELECT COUNT(*) FROM LIMON.WWI_Limon.Sales.OrderLines WHERE StockItemID = @id)
        + (SELECT COUNT(*) FROM LIMON.WWI_Limon.Warehouse.StockItemTransactions WHERE StockItemID = @id)
        + (SELECT COUNT(*) FROM LIMON.WWI_Limon.Warehouse.StockItemHoldings WHERE StockItemID = @id AND QuantityOnHand > 0)'
    EXEC sp_executesql @sql, N'@id int, @usos int OUTPUT', @id = @ID_Producto, @usos = @usos_limon OUTPUT

    IF @usos_sanjose > 0
    BEGIN
      THROW 50025, 'El producto tiene ventas, pedidos o inventario en la sucursal San José', 1
    END

    IF @usos_limon > 0
    BEGIN
      THROW 50026, 'El producto tiene ventas, pedidos o inventario en la sucursal Limón', 1
    END

    -- 4. Borrar (solo en el Corporativo; la replicación lo lleva a las sucursales)
    BEGIN TRANSACTION

    DELETE FROM grupos_productos WHERE StockItemID = @ID_Producto
    DELETE FROM productos WHERE StockItemID = @ID_Producto

    COMMIT TRANSACTION
    SELECT 'Producto eliminado correctamente' AS Resultado
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
USE WWI_Corporativo
GO
EXEC AgregarNuevoProducto
  @Nombre_Producto = 'Producto Prueba P2', @ProveedorID = 1, @UnitPackageID = 7, @OuterPackageID = 7,
  @QuantityPerOuter = 1, @TaxRate = 15, @UnitPrice = 10, @RecommendedPrice = 15,
  @TypicalWeight = 0.5, @MarketingSearchDetails = 'Producto de prueba del Proyecto 2',
  @Grupos_Productos = '1,2'

-- Intentar eliminar un producto con inventario en una sucursal
DECLARE @id int = (SELECT StockItemID FROM Warehouse.StockItems WHERE StockItemName = 'Producto Prueba P2')
EXEC EliminarProducto @ID_Producto = @id

-- Intentar eliminar un producto con ventas
EXEC EliminarProducto @ID_Producto = 1

-- Probar con una sucursal caida
DECLARE @id int = (SELECT StockItemID FROM Warehouse.StockItems WHERE StockItemName = 'Producto Prueba P2')
EXEC EliminarProducto @ID_Producto = @id


---------- Permisos del rol Administrador en el Corporativo ----------


/*
   Los administradores de sucursal modifican el catálogo de productos en el
   Corporativo (único maestro). La API usa este login, que solo puede ejecutar
   los 3 SPs de productos.
*/
USE WWI_Corporativo
GO
CREATE LOGIN api_productos
WITH PASSWORD = 'ApiProductos*2026', CHECK_POLICY = OFF, DEFAULT_DATABASE = WWI_Corporativo
GO
CREATE USER api_productos FOR LOGIN api_productos
CREATE ROLE rol_administrador
ALTER ROLE rol_administrador ADD MEMBER api_productos
GRANT EXECUTE ON AgregarNuevoProducto TO rol_administrador
GRANT EXECUTE ON EditarDatosProducto TO rol_administrador
GRANT EXECUTE ON EliminarProducto TO rol_administrador
GO

-- Prueba #2: La versión del producto
SELECT CONVERT(varchar(27), ValidFrom, 121) AS Version FROM Warehouse.StockItems WHERE StockItemID = 1


---------- Vista materializada de ventas (estadísticas del Corporativo) ----------


/*
   SQL Server no permite vistas indexadas (vistas materializadas) sobre tablas
   de otros servidores. Se usa lo "similar": tablas resumen en el Corporativo con una
   copia de las ventas de las dos sucursales, que un job del SQL Server Agent refresca
   cada 5 minutos (como un REFRESH MATERIALIZED VIEW).
*/
USE WWI_Corporativo
GO

-- Encabezados de las facturas de las dos sucursales
CREATE TABLE dbo.ResumenFacturas (
  InvoiceID int NOT NULL,
  Sucursal nvarchar(20) NOT NULL,
  CustomerID int NOT NULL,
  DeliveryMethodID int NOT NULL,
  InvoiceDate date NOT NULL,
  CONSTRAINT PK_ResumenFacturas PRIMARY KEY (InvoiceID)
)

-- Líneas de las facturas
CREATE TABLE dbo.ResumenDetalleFacturas (
  InvoiceLineID int NOT NULL,
  InvoiceID int NOT NULL,
  Sucursal nvarchar(20) NOT NULL,
  StockItemID int NOT NULL,
  Quantity int NOT NULL,
  UnitPrice decimal(18, 2) NULL,
  CONSTRAINT PK_ResumenDetalleFacturas PRIMARY KEY (InvoiceLineID)
)

-- Movimientos de inventario (ventas de las sucursales y compras del Corporativo)
CREATE TABLE dbo.ResumenMovimientosInventario (
  StockItemTransactionID int NOT NULL,
  Sucursal nvarchar(20) NOT NULL, -- SanJose, Limon o Corporativo
  StockItemID int NOT NULL,
  Quantity decimal(18, 3) NOT NULL,
  TransactionOccurredWhen datetime2(7) NOT NULL,
  CONSTRAINT PK_ResumenMovimientosInventario PRIMARY KEY (StockItemTransactionID)
)

-- Control: cuándo se actualizó cada sucursal y si respondió
CREATE TABLE dbo.ControlResumen (
  Sucursal nvarchar(20) NOT NULL PRIMARY KEY,
  UltimaActualizacion datetime2(0) NULL,
  UltimoIntento datetime2(0) NULL,
  Facturas int NULL,
  Estado nvarchar(100) NOT NULL
)

INSERT INTO dbo.ControlResumen (Sucursal, Estado) VALUES
  ('SanJose', 'Pendiente'),
  ('Limon', 'Pendiente')
GO

-- Índices para que los reportes filtren rápido por sucursal, fecha, cliente y producto
CREATE INDEX IX_ResumenFacturas_Sucursal ON dbo.ResumenFacturas (Sucursal, InvoiceDate)
CREATE INDEX IX_ResumenFacturas_Cliente ON dbo.ResumenFacturas (CustomerID)
CREATE INDEX IX_ResumenDetalleFacturas_Factura ON dbo.ResumenDetalleFacturas (InvoiceID) INCLUDE (StockItemID, Quantity, UnitPrice)
CREATE INDEX IX_ResumenDetalleFacturas_Producto ON dbo.ResumenDetalleFacturas (StockItemID)
CREATE INDEX IX_ResumenMovimientos_Producto ON dbo.ResumenMovimientosInventario (StockItemID, Sucursal)
GO

/*
  ActualizarResumenSucursal: refresca el corte de una sucursal.
  1. Si la sucursal no responde, se deja su último corte y se anota en ControlResumen.
  2. Los datos se traen primero a tablas temporales, fuera de la transacción
     (así no se necesita una transacción distribuida / MSDTC).
  3. En una sola transacción se reemplaza el corte anterior: todo o nada.
*/
CREATE OR ALTER PROCEDURE dbo.ActualizarResumenSucursal
  @Sucursal nvarchar(20) -- 'SanJose' o 'Limon'
AS
BEGIN
  SET NOCOUNT ON
  SET XACT_ABORT ON

  DECLARE @servidor sysname
  DECLARE @origen nvarchar(200)
  DECLARE @sql nvarchar(MAX)

  SET @servidor = CASE @Sucursal WHEN 'SanJose' THEN N'SANJOSE' WHEN 'Limon' THEN N'LIMON' END

  IF @servidor IS NULL
  BEGIN
    THROW 50050, 'La sucursal indicada no es válida', 1
  END

  SET @origen = @servidor + N'.WWI_' + @Sucursal -- por ejemplo SANJOSE.WWI_SanJose

  -- 1. ¿Responde la sucursal?
  BEGIN TRY
    EXEC sp_testlinkedserver @servidor
  END TRY
  BEGIN CATCH
    UPDATE dbo.ControlResumen
    SET UltimoIntento = SYSDATETIME(),
        Estado = 'Sin conexión: se mantienen los datos del último corte'
    WHERE Sucursal = @Sucursal
    RETURN
  END CATCH

  -- 2. Traer los datos de la sucursal (fuera de la transacción)
  CREATE TABLE #facturas (InvoiceID int, CustomerID int, DeliveryMethodID int, InvoiceDate date)
  CREATE TABLE #detalle (InvoiceLineID int, InvoiceID int, StockItemID int, Quantity int, UnitPrice decimal(18, 2))
  CREATE TABLE #movimientos (StockItemTransactionID int, StockItemID int, Quantity decimal(18, 3), TransactionOccurredWhen datetime2(7))

  SET @sql = N'INSERT INTO #facturas SELECT InvoiceID, CustomerID, DeliveryMethodID, InvoiceDate FROM '
           + @origen + N'.Sales.Invoices'
  EXEC (@sql)

  SET @sql = N'INSERT INTO #detalle SELECT InvoiceLineID, InvoiceID, StockItemID, Quantity, UnitPrice FROM '
           + @origen + N'.Sales.InvoiceLines'
  EXEC (@sql)

  SET @sql = N'INSERT INTO #movimientos SELECT StockItemTransactionID, StockItemID, Quantity, TransactionOccurredWhen FROM '
           + @origen + N'.Warehouse.StockItemTransactions'
  EXEC (@sql)

  -- 3. Reemplazar el corte anterior de esta sucursal (todo o nada)
  BEGIN TRANSACTION

  -- Si el job y un usuario refrescan al mismo tiempo, uno espera al otro
  EXEC sp_getapplock @Resource = N'ResumenVentas', @LockMode = N'Exclusive'

  DELETE FROM dbo.ResumenDetalleFacturas WHERE Sucursal = @Sucursal
  DELETE FROM dbo.ResumenFacturas WHERE Sucursal = @Sucursal
  DELETE FROM dbo.ResumenMovimientosInventario WHERE Sucursal = @Sucursal

  INSERT INTO dbo.ResumenFacturas (InvoiceID, Sucursal, CustomerID, DeliveryMethodID, InvoiceDate)
  SELECT InvoiceID, @Sucursal, CustomerID, DeliveryMethodID, InvoiceDate FROM #facturas

  INSERT INTO dbo.ResumenDetalleFacturas (InvoiceLineID, InvoiceID, Sucursal, StockItemID, Quantity, UnitPrice)
  SELECT InvoiceLineID, InvoiceID, @Sucursal, StockItemID, Quantity, UnitPrice FROM #detalle

  INSERT INTO dbo.ResumenMovimientosInventario (StockItemTransactionID, Sucursal, StockItemID, Quantity, TransactionOccurredWhen)
  SELECT StockItemTransactionID, @Sucursal, StockItemID, Quantity, TransactionOccurredWhen FROM #movimientos

  UPDATE dbo.ControlResumen
  SET UltimaActualizacion = SYSDATETIME(),
      UltimoIntento = SYSDATETIME(),
      Facturas = (SELECT COUNT(*) FROM #facturas),
      Estado = 'Actualizado'
  WHERE Sucursal = @Sucursal

  COMMIT TRANSACTION
END
GO

/*
  ActualizarResumenVentas: refresca toda la vista materializada.
  Lo ejecuta el job cada 5 minutos; también se puede llamar a mano
  (por ejemplo desde un botón "Actualizar" en las estadísticas).
  Si una sucursal falla, la otra se actualiza igual.
*/
CREATE OR ALTER PROCEDURE dbo.ActualizarResumenVentas
AS
BEGIN
  SET NOCOUNT ON

  -- Movimientos propios del Corporativo (compras a proveedores), para la rotación consolidada
  BEGIN TRANSACTION
  EXEC sp_getapplock @Resource = N'ResumenVentas', @LockMode = N'Exclusive'

  DELETE FROM dbo.ResumenMovimientosInventario WHERE Sucursal = 'Corporativo'

  INSERT INTO dbo.ResumenMovimientosInventario (StockItemTransactionID, Sucursal, StockItemID, Quantity, TransactionOccurredWhen)
  SELECT StockItemTransactionID, 'Corporativo', StockItemID, Quantity, TransactionOccurredWhen
  FROM Warehouse.StockItemTransactions
  COMMIT TRANSACTION

  -- San José
  BEGIN TRY
    EXEC dbo.ActualizarResumenSucursal 'SanJose'
  END TRY
  BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION
    UPDATE dbo.ControlResumen
    SET UltimoIntento = SYSDATETIME(), Estado = 'Error: ' + LEFT(ERROR_MESSAGE(), 90)
    WHERE Sucursal = 'SanJose'
  END CATCH

  -- Limón
  BEGIN TRY
    EXEC dbo.ActualizarResumenSucursal 'Limon'
  END TRY
  BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION
    UPDATE dbo.ControlResumen
    SET UltimoIntento = SYSDATETIME(), Estado = 'Error: ' + LEFT(ERROR_MESSAGE(), 90)
    WHERE Sucursal = 'Limon'
  END CATCH

  SELECT Sucursal, UltimaActualizacion, UltimoIntento, Facturas, Estado FROM dbo.ControlResumen
END
GO

/*
  ObtenerEstadoResumen: para mostrar en el Website "Datos actualizados al ..."
  y avisar si alguna sucursal no respondió.
*/
CREATE OR ALTER PROCEDURE dbo.ObtenerEstadoResumen
AS
BEGIN
  SELECT Sucursal, UltimaActualizacion, UltimoIntento, Facturas, Estado
  FROM dbo.ControlResumen
END
GO

-- Carga inicial de la vista materializada
EXEC dbo.ActualizarResumenVentas
GO

/*
  Job del SQL Server Agent: refresca la vista materializada cada 5 minutos
*/
USE msdb
GO
EXEC dbo.sp_add_job
  @job_name = N'WWI - Actualizar resumen de ventas',
  @description = N'Refresca la vista materializada de ventas del Corporativo con los datos de San José y Limón'

EXEC dbo.sp_add_jobstep
  @job_name = N'WWI - Actualizar resumen de ventas',
  @step_name = N'ActualizarResumenVentas',
  @subsystem = N'TSQL',
  @database_name = N'WWI_Corporativo',
  @command = N'EXEC dbo.ActualizarResumenVentas'

EXEC dbo.sp_add_schedule
  @schedule_name = N'Cada 5 minutos',
  @freq_type = 4, -- diario
  @freq_interval = 1, -- todos los días
  @freq_subday_type = 4, -- en minutos
  @freq_subday_interval = 5 -- cada 5 minutos

EXEC dbo.sp_attach_schedule
  @job_name = N'WWI - Actualizar resumen de ventas',
  @schedule_name = N'Cada 5 minutos'

EXEC dbo.sp_add_jobserver
  @job_name = N'WWI - Actualizar resumen de ventas'
GO

-- Pruebas --
-- #1: La vista materializada cuadra con las sucursales
SELECT
  CASE WHEN GROUPING(f.Sucursal) = 1 THEN 'Consolidado' ELSE f.Sucursal END AS Sucursal,
  COUNT(DISTINCT f.InvoiceID) AS facturas,
  SUM(df.Quantity * df.UnitPrice) AS ventas
FROM dbo.ResumenFacturas f
INNER JOIN dbo.ResumenDetalleFacturas df ON df.InvoiceID = f.InvoiceID
GROUP BY ROLLUP (f.Sucursal)

-- #2: Un reporte, tres vistas
EXEC ObtenerTopCincoClientes @InicioRango = 2016, @Sucursal = 'SanJose'
EXEC ObtenerTopCincoClientes @InicioRango = 2016, @Sucursal = 'Limon'
EXEC ObtenerTopCincoClientes @InicioRango = 2016

EXEC ResumenDeVentaPorCategoria @Sucursal = 'SanJose'
EXEC ResumenDeVentaPorCategoria

-- #3: “Tiempo real”: una venta nueva en Limón llega a las estadísticas
EXEC dbo.ActualizarResumenVentas

-- #4: Una sucursal caída
EXEC dbo.ActualizarResumenVentas
EXEC ObtenerTopCincoClientes @InicioRango = 2016, @Sucursal = 'Limon'
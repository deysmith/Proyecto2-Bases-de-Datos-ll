-- Este archivo se ejecuta en las 2 sucursales (WWI_SanJose y WWI_Limon)
IF DB_NAME() NOT IN ('WWI_SanJose', 'WWI_Limon')
BEGIN
  PRINT 'ERROR: está en la base ' + DB_NAME() + '. Elija WWI_SanJose o WWI_Limon.'
  SET NOEXEC ON
END
GO

/*
Devuelve el nombre, categoría y método de entrega de todos los proveedores
Entradas:
    - @NumeroPagina - Número de página que se desea consultar. 
    - @CantidadRegistros - Cantidad de registros que se mostrarán por página.
Salidas:
    - Nombre, categoría y método de entrega de todos los proveedores
Restricciones:
    - No posee restricciones
*/
CREATE OR ALTER PROCEDURE GetProveedores
  @NumeroPagina int = 1,
  @CantidadRegistros int = 20
AS
BEGIN
SELECT
    p.SupplierID,
    p.SupplierName,
    c.SupplierCategoryName,
    ISNULL(me.DeliveryMethodName, 'No posee un metodo de entrega estándar') as DeliveryMethodName
  FROM proveedores p
  INNER JOIN categorias_proveedores c on c.SupplierCategoryID = p.SupplierCategoryID
  LEFT JOIN metodos_entrega me on me.DeliveryMethodID = p.DeliveryMethodID
  ORDER BY p.SupplierName ASC
  OFFSET (@NumeroPagina - 1) * @CantidadRegistros ROWS
  FETCH NEXT @CantidadRegistros ROWS ONLY
END
GO

/*
Devuelve los proveedores donde su nombre o categoría coincida con el criterio
Entradas:
    - @Nombre_Proveedor - nvarchar(100): Nombre del proveedor 
    - @CategoriaID - int: ID de la categoría
    - @MetodoEntegaID - int: ID de la metodo de entrega
    - @NumeroPagina - Número de página que se desea consultar. 
    - @CantidadRegistros - Cantidad de registros que se mostrarán por página.
Salidas:
    - Nombre, categoría y método de envío de los proveedores que coincidan con
      el criterio de búsqueda
Restricciones:
    - EL criterio debe tener entre 0 y 50 caracteres
*/
CREATE OR ALTER PROCEDURE BuscarProveedores
  @Nombre_Proveedor nvarchar(100) = NULL,
  @CategoriaID int = NULL,
  @MetodoEntegaID int = NULL,
  @NumeroPagina int = 1,
  @CantidadRegistros int = 20
AS
BEGIN
SELECT
    p.SupplierID,
    p.SupplierName,
    c.SupplierCategoryName,
    ISNULL(me.DeliveryMethodName, 'No posee un metodo de entrega estándar') as DeliveryMethodName
  FROM proveedores p
  INNER JOIN categorias_proveedores c on c.SupplierCategoryID = p.SupplierCategoryID
  LEFT JOIN metodos_entrega me on me.DeliveryMethodID = p.DeliveryMethodID
  WHERE (
    @Nombre_Proveedor IS NULL
    OR @Nombre_Proveedor = ''
    OR p.SupplierName LIKE '%' + @Nombre_Proveedor + '%' 
  ) AND (
    @CategoriaID IS NULL
    OR p.SupplierCategoryID = @CategoriaID
  ) AND (
    @MetodoEntegaID IS NULL
    OR p.DeliveryMethodID = @MetodoEntegaID
  )
  ORDER BY p.SupplierName ASC
  OFFSET (@NumeroPagina - 1) * @CantidadRegistros ROWS
  FETCH NEXT @CantidadRegistros ROWS ONLY
END
GO

/*
Devuelve las categorías de los proveedores
Entradas:
    - No recibe entradas
Salidas:
    - Un 'lista' con las categorías de los proveedores
Restricciones:
    - No posee restricciones
*/
CREATE OR ALTER PROCEDURE ObtenerCategoriasProveedores
AS
BEGIN
  SELECT
      DISTINCT c.SupplierCategoryName, c.SupplierCategoryID
  FROM categorias_proveedores c
  INNER JOIN proveedores p on p.SupplierCategoryID = c.SupplierCategoryID
END
GO

/*
Devuelve todos los métodos de entrega utilizados por lo proveedores
Entradas:
    - No recibe parámetros
Salidas:
    - Los métodos de entrga que están vinvulo a algun proveedpr
Restricciones:
    - No posee restricciones
*/
CREATE OR ALTER PROCEDURE ObtenerMetodosDeEntregaProveedores
AS
BEGIN
  SELECT DISTINCT me.DeliveryMethodName, me.DeliveryMethodID
  FROM metodos_entrega me
  INNER JOIN proveedores p on p.DeliveryMethodID = me.DeliveryMethodID
END
GO

/*
  Devuelve los detalles completos de un proveedor (reconstruye la fragmentación vertical):
  - Fragmento general: tablas locales de la sucursal
  - Fragmento sensible: vista dbo.ProveedoresSensibles del Corporativo (incluye datos bancarios)
  Lo llama ObtenerDatosProveedor solo cuando el Corporativo responde.
*/
CREATE OR ALTER PROCEDURE ObtenerDatosProveedorCompleto
  @Nombre_Proveedor nvarchar(100) = NULL,
  @ID_Proveedor int = NULL
AS
BEGIN
  SELECT
      p.SupplierID,
      ISNULL(p.SupplierReference, 'No indica') AS SupplierReference,
      p.SupplierName,
      c.SupplierCategoryName,
      pe.FullName AS PrimaryContact,
      ISNULL(pe1.FullName, 'No posee contacto alternativo') AS AlternativeContact,
      ISNULL(me.DeliveryMethodName, 'No posee un metodo de entrega estándar') AS DeliveryMethodName,
      ci.CityName,
      s.DeliveryPostalCode,
      s.PhoneNumber,
      s.FaxNumber,
      s.WebsiteURL,
      CONCAT(
          'Entrega (Delivery): ',
          s.DeliveryAddressLine1,
          ISNULL(', ' + s.DeliveryAddressLine2, ''),
          ' - Postal: ',
          s.PostalAddressLine1,
          ISNULL(', ' + s.PostalAddressLine2, '')) AS Address,
      CASE
        WHEN s.Latitud IS NULL THEN NULL
        ELSE geography::Point(s.Latitud, s.Longitud, 4326)
      END AS DeliveryLocation,
      ISNULL(s.BankAccountBranch, 'No indica') AS BankAccountBranch,
      ISNULL(s.BankAccountNumber, 'No indica') AS BankAccountNumber,
      p.PaymentDays,
      p.SupplierCategoryID,
      p.DeliveryMethodID,
      p.DeliveryCityID,
      p.PostalCityID,
      cp.CityName AS PostalCityName,
      s.DeliveryAddressLine1,
      s.DeliveryAddressLine2,
      s.PostalAddressLine1,
      s.PostalAddressLine2,
      s.PostalPostalCode,
      'Disponible' AS DatosSensibles
  FROM proveedores p
  INNER JOIN CORPORATIVO.WWI_Corporativo.dbo.ProveedoresSensibles s ON s.SupplierID = p.SupplierID
  INNER JOIN categorias_proveedores c ON c.SupplierCategoryID = p.SupplierCategoryID
  INNER JOIN ciudades ci ON ci.CityID = p.DeliveryCityID
  INNER JOIN ciudades cp ON cp.CityID = p.PostalCityID
  LEFT JOIN personas pe ON pe.PersonID = s.PrimaryContactPersonID
  LEFT JOIN personas pe1 ON pe1.PersonID = s.AlternateContactPersonID
  LEFT JOIN metodos_entrega me ON me.DeliveryMethodID = p.DeliveryMethodID
  WHERE (@ID_Proveedor IS NULL AND p.SupplierName = @Nombre_Proveedor)
     OR (@ID_Proveedor IS NOT NULL AND p.SupplierID = @ID_Proveedor)
END
GO

/*
  Devuelve los detalles de un proveedor.
  Plan ante fallos: si el Corporativo no responde, devuelve los datos generales
  con los sensibles en NULL y DatosSensibles = 'No disponible...'.
*/
CREATE OR ALTER PROCEDURE ObtenerDatosProveedor
  @Nombre_Proveedor nvarchar(100) = NULL,
  @ID_Proveedor int = NULL
AS
BEGIN
  DECLARE @corporativo_disponible bit = 1

  BEGIN TRY
    EXEC sp_testlinkedserver N'CORPORATIVO'
  END TRY
  BEGIN CATCH
    SET @corporativo_disponible = 0
  END CATCH

  IF @corporativo_disponible = 1
  BEGIN
    EXEC ObtenerDatosProveedorCompleto @Nombre_Proveedor, @ID_Proveedor
  END
  ELSE
  BEGIN
    SELECT
        p.SupplierID,
        ISNULL(p.SupplierReference, 'No indica') AS SupplierReference,
        p.SupplierName,
        c.SupplierCategoryName,
        NULL AS PrimaryContact,
        NULL AS AlternativeContact,
        ISNULL(me.DeliveryMethodName, 'No posee un metodo de entrega estándar') AS DeliveryMethodName,
        ci.CityName,
        NULL AS DeliveryPostalCode,
        NULL AS PhoneNumber,
        NULL AS FaxNumber,
        NULL AS WebsiteURL,
        NULL AS Address,
        NULL AS DeliveryLocation,
        NULL AS BankAccountBranch,
        NULL AS BankAccountNumber,
        p.PaymentDays,
        p.SupplierCategoryID,
        p.DeliveryMethodID,
        p.DeliveryCityID,
        p.PostalCityID,
        cp.CityName AS PostalCityName,
        NULL AS DeliveryAddressLine1,
        NULL AS DeliveryAddressLine2,
        NULL AS PostalAddressLine1,
        NULL AS PostalAddressLine2,
        NULL AS PostalPostalCode,
        'No disponible: el Corporativo no responde' AS DatosSensibles
    FROM proveedores p
    INNER JOIN categorias_proveedores c ON c.SupplierCategoryID = p.SupplierCategoryID
    INNER JOIN ciudades ci ON ci.CityID = p.DeliveryCityID
    INNER JOIN ciudades cp ON cp.CityID = p.PostalCityID
    LEFT JOIN metodos_entrega me ON me.DeliveryMethodID = p.DeliveryMethodID
    WHERE (@ID_Proveedor IS NULL AND p.SupplierName = @Nombre_Proveedor)
       OR (@ID_Proveedor IS NOT NULL AND p.SupplierID = @ID_Proveedor)
  END
END
GO

SET NOEXEC OFF
GO
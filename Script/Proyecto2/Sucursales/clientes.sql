-- Este archivo se ejecuta en las 2 sucursales (WWI_SanJose y WWI_Limon)
IF DB_NAME() NOT IN ('WWI_SanJose', 'WWI_Limon')
BEGIN
  PRINT 'ERROR: está en la base ' + DB_NAME() + '. Elija WWI_SanJose o WWI_Limon.'
  SET NOEXEC ON
END
GO

/*
Devuelve el nombre, categoría y método de entrega de los clientes registrados
Entradas:
    - @NumeroPagina - Número de página que se desea consultar. 
    - @CantidadRegistros - Cantidad de registros que se mostrarán por página.
Salidas:
    - Nombre, categoría, método de entraga y entrega de los clientes registrados
Restricciones:
    - @NumeroPagina debe ser un número entero positivo
    - @CantidadRegistros deber ser mayor a 0 (entero positivo)
*/
CREATE OR ALTER PROCEDURE GetClientes 
  @NumeroPagina int = 1,
  @CantidadRegistros int = 20
AS
BEGIN
  SELECT
      c.CustomerID,
      c.CustomerName,
      cc.CustomerCategoryName,
      me.DeliveryMethodName,
      ci.CityName
    FROM clientes c
    INNER JOIN categorias_clientes cc on cc.CustomerCategoryID = c.CustomerCategoryID
    INNER JOIN  metodos_entrega me on me.DeliveryMethodID = c.DeliveryMethodID
    INNER JOIN ciudades ci on ci.CityID = c.DeliveryCityID
    ORDER BY c.CustomerName ASC

    OFFSET (@NumeroPagina - 1) * @CantidadRegistros ROWS
    FETCH NEXT @CantidadRegistros ROWS ONLY
END
GO

/*
Devuelve el nombre, categoría y método de entraga de los clientes qque su nombre
coincide con el criterio de búsqueda
Entradas:
    - @Criterio - nvarchar(100): Texto utilizado para buscar coincidencias con nombre
    - @CategoriaID - int: Identificador de la categoría
    - @MetodoEntregaID - int: Identificador del metodo de entrega
    - @NumeroPagina - Número de página que se desea consultar. 
    - @CantidadRegistros - Cantidad de registros que se mostrarán por página.
Salidas:
    - Nombre, categoría, método de entraga y ciudad de los clientes que su nombre cumple 
      con el criterio
Restricciones:
    - @NumeroPagina debe ser un número entero positivo
    - @CantidadRegistros deber ser mayor a 0 (entero positivo)
*/
CREATE OR ALTER PROCEDURE BuscarFiltrarClientes
  @Criterio nvarchar(100) = NULL,
  @CategoriaID int = NULL,
  @MetodoEntregaID int = NULL,
  @NumeroPagina int = 1,
  @CantidadRegistros int = 20

AS
BEGIN
  SELECT
      c.CustomerID,
      c.CustomerName,
      cc.CustomerCategoryName,
      me.DeliveryMethodName,
      ci.CityName
    FROM clientes c
    INNER JOIN categorias_clientes cc on cc.CustomerCategoryID = c.CustomerCategoryID
    INNER JOIN  metodos_entrega me on me.DeliveryMethodID = c.DeliveryMethodID
    INNER JOIN ciudades ci on ci.CityID = c.DeliveryCityID

    WHERE (
      @Criterio is NULL
      OR @Criterio = ''
      OR c.CustomerName LIKE '%' + @Criterio + '%'
    ) AND (
      @CategoriaID is NULL
      OR c.CustomerCategoryID = @CategoriaID
    ) AND (
      @MetodoEntregaID is NULL
      OR c.DeliveryMethodID = @MetodoEntregaID
    )

    ORDER BY c.CustomerName ASC
    OFFSET (@NumeroPagina - 1) * @CantidadRegistros ROWS
    FETCH NEXT @CantidadRegistros ROWS ONLY
END
GO

/*
Devuelve las categorías de los clientes
Entradas:
    - No recibe entradas
Salidas:
    - Categorías de los clientes registrados
Restricciones:
    - No posee restricciones
*/
CREATE OR ALTER PROCEDURE ObtenerCategoriasClientes
AS
BEGIN
  SELECT 
      DISTINCT (cc.CustomerCategoryName),
      cc.CustomerCategoryID
  FROM categorias_clientes cc
  INNER JOIN clientes c on cc.CustomerCategoryID = c.CustomerCategoryID
END
GO

/*
Devuelve todos los métodos de entrega utilizados por lo clientes
Entradas:
    - No recibe parámetros
Salidas:
    - Los métodos de entrga que están vinvulo a algun cliente
Restricciones:
    - No posee restricciones
*/
CREATE OR ALTER PROCEDURE ObtenerMetodosDeEntregaClientes
AS
BEGIN
  SELECT DISTINCT (DeliveryMethodName),
  me.DeliveryMethodID
  FROM metodos_entrega me
  INNER JOIN clientes c on c.DeliveryMethodID = me.DeliveryMethodID
END
GO

/*
  Devuelve los detalles completos de un cliente (reconstruye la fragmentación vertical):
  - Fragmento general: tablas locales de la sucursal (clientes, categorías, ciudades, personas)
  - Fragmento sensible: vista dbo.ClientesSensibles del Corporativo (linked server)
  La ubicación llega como latitud/longitud y se vuelve a armar como geography,
  para que la API y el mapa del Website la reciba.
  Lo llama ObtenerDatosClientes solo cuando el Corporativo responde.
*/
CREATE OR ALTER PROCEDURE ObtenerDatosClientesCompleto
  @Nombre_Cliente nvarchar(100) = NULL,
  @ID_Cliente int = NULL
AS
BEGIN
  SELECT
      c.CustomerID,
      c.CustomerName,
      cc.CustomerCategoryName,
      CASE
        WHEN c.BuyingGroupID IS NULL THEN 'No pertenece a un grupo de compra'
        ELSE gc.BuyingGroupName
      END AS BuyingGroupName,
      p.FullName AS PrimaryContact,
      ISNULL(p1.FullName, 'No posee contacto alternativo') AS AlternativeContact,
      CASE
        WHEN c.BillToCustomerID <> c.CustomerID THEN (SELECT CustomerName FROM clientes WHERE CustomerID = c.BillToCustomerID)
        ELSE c.CustomerName
      END AS BillToCustomer,
      me.DeliveryMethodName,
      ci.CityName,
      s.DeliveryPostalCode,
      s.PhoneNumber,
      s.FaxNumber,
      c.PaymentDays,
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
      c.CustomerCategoryID,
      c.DeliveryMethodID,
      c.DeliveryCityID,
      c.PostalCityID,
      cp.CityName AS PostalCityName,
      s.DeliveryAddressLine1,
      s.DeliveryAddressLine2,
      s.PostalAddressLine1,
      s.PostalAddressLine2,
      s.PostalPostalCode,
      c.Sucursal,
      'Disponible' AS DatosSensibles
  FROM clientes c
  INNER JOIN CORPORATIVO.WWI_Corporativo.dbo.ClientesSensibles s ON s.CustomerID = c.CustomerID
  INNER JOIN categorias_clientes cc ON cc.CustomerCategoryID = c.CustomerCategoryID
  INNER JOIN metodos_entrega me ON me.DeliveryMethodID = c.DeliveryMethodID
  INNER JOIN ciudades ci ON ci.CityID = c.DeliveryCityID
  INNER JOIN ciudades cp ON cp.CityID = c.PostalCityID
  LEFT JOIN personas p ON p.PersonID = s.PrimaryContactPersonID
  LEFT JOIN personas p1 ON p1.PersonID = s.AlternateContactPersonID
  LEFT JOIN grupo_compra gc ON gc.BuyingGroupID = c.BuyingGroupID
  WHERE (@ID_Cliente IS NULL AND c.CustomerName = @Nombre_Cliente)
     OR (@ID_Cliente IS NOT NULL AND c.CustomerID = @ID_Cliente)
END
GO

/*
  Devuelve los detalles de un cliente.
  Plan ante fallos:
  - Si el Corporativo responde: datos completos (llama a ObtenerDatosClientesCompleto).
  - Si NO responde: devuelve igual los datos generales que tiene la sucursal, con los
    datos sensibles en NULL y DatosSensibles = 'No disponible...'.
*/
CREATE OR ALTER PROCEDURE ObtenerDatosClientes
  @Nombre_Cliente nvarchar(100) = NULL,
  @ID_Cliente int = NULL
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
    EXEC ObtenerDatosClientesCompleto @Nombre_Cliente, @ID_Cliente
  END
  ELSE
  BEGIN
    SELECT
        c.CustomerID,
        c.CustomerName,
        cc.CustomerCategoryName,
        CASE
          WHEN c.BuyingGroupID IS NULL THEN 'No pertenece a un grupo de compra'
          ELSE gc.BuyingGroupName
        END AS BuyingGroupName,
        NULL AS PrimaryContact,
        NULL AS AlternativeContact,
        CASE
          WHEN c.BillToCustomerID <> c.CustomerID THEN (SELECT CustomerName FROM clientes WHERE CustomerID = c.BillToCustomerID)
          ELSE c.CustomerName
        END AS BillToCustomer,
        me.DeliveryMethodName,
        ci.CityName,
        NULL AS DeliveryPostalCode,
        NULL AS PhoneNumber,
        NULL AS FaxNumber,
        c.PaymentDays,
        NULL AS WebsiteURL,
        NULL AS Address,
        NULL AS DeliveryLocation,
        c.CustomerCategoryID,
        c.DeliveryMethodID,
        c.DeliveryCityID,
        c.PostalCityID,
        cp.CityName AS PostalCityName,
        NULL AS DeliveryAddressLine1,
        NULL AS DeliveryAddressLine2,
        NULL AS PostalAddressLine1,
        NULL AS PostalAddressLine2,
        NULL AS PostalPostalCode,
        c.Sucursal,
        'No disponible: el Corporativo no responde' AS DatosSensibles
    FROM clientes c
    INNER JOIN categorias_clientes cc ON cc.CustomerCategoryID = c.CustomerCategoryID
    INNER JOIN metodos_entrega me ON me.DeliveryMethodID = c.DeliveryMethodID
    INNER JOIN ciudades ci ON ci.CityID = c.DeliveryCityID
    INNER JOIN ciudades cp ON cp.CityID = c.PostalCityID
    LEFT JOIN grupo_compra gc ON gc.BuyingGroupID = c.BuyingGroupID
    WHERE (@ID_Cliente IS NULL AND c.CustomerName = @Nombre_Cliente)
       OR (@ID_Cliente IS NOT NULL AND c.CustomerID = @ID_Cliente)
  END
END
GO

SET NOEXEC OFF
GO
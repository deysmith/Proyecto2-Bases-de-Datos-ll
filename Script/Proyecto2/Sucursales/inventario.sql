-- Este archivo se ejecuta en las 2 sucursales (WWI_SanJose y WWI_Limon)
IF DB_NAME() NOT IN ('WWI_SanJose', 'WWI_Limon')
BEGIN
  PRINT 'ERROR: está en la base ' + DB_NAME() + '. Elija WWI_SanJose o WWI_Limon.'
  SET NOEXEC ON
END
GO

/*
Se encarga de obtener el nombre, grupos y cantidad en inventario de los productos
Entradas:
    - @NumeroPagina - Número de página que se desea consultar. 
    - @CantidadRegistros - Cantidad de registros que se mostrarán por página.
Salidas:
    - Nombre, grupos y cantidad en inventario de los productos registrados
Restricciones:
    - @NumeroPagina debe ser un número entero positivo
    - @CantidadRegistros deber ser mayor a 0 (entero positivo)
*/
CREATE OR ALTER PROCEDURE GetProductos
  @NumeroPagina int = 1,
  @CantidadRegistros int = 20
AS
BEGIN
  SELECT
      p.StockItemID,
      p.StockItemName,
      STRING_AGG(np.StockGroupName, ', ') as [Group],
      ip.QuantityOnHand

  FROM productos p
  LEFT JOIN inventario_productos ip on ip.StockItemID = p.StockItemID
  LEFT JOIN grupos_productos gp on gp.StockItemID = p.StockItemID
  LEFT JOIN nombre_grupo_producto np on np.StockGroupID = gp.StockGroupID
  GROUP BY p.StockItemID, p.StockItemName, ip.QuantityOnHand
  ORDER BY p.StockItemName ASC
  OFFSET (@NumeroPagina - 1) * @CantidadRegistros ROWS
  FETCH NEXT @CantidadRegistros ROWS ONLY
END
GO


/*
Se encarga de obtener el nombre, grupos y cantidad en inventario de los productos
que su nombre o grupo coincide con el criterio de búsqueda
Entradas:
    - @Nombre - nvarchar(100): Coincidencia de nombre
    - @GrupoID - int: Identificador del grupo de productos
    - @CantidadMinima - int: Cantidad minimo de productos
    - @CantidadMaxima - int: Cantidad maxima de productos
    - @NumeroPagina - Número de página que se desea consultar. 
    - @CantidadRegistros - Cantidad de registros que se mostrarán por página.
Salidas:
    - Nombre, grupos y cantidad en inventario de los productos registrados
Restricciones:
    - @NumeroPagina debe ser un número entero positivo
    - @CantidadRegistros deber ser mayor a 0 (entero positivo)
*/
CREATE OR ALTER PROCEDURE BuscarProductos
  @Nombre nvarchar(100) = NULL,
  @GrupoID int = NULL,
  @CantidadMinima int = NULL,
  @CantidadMaxima int = NULL,
  @NumeroPagina int = 1,
  @CantidadRegistros int = 20
AS
BEGIN
  SELECT
      p.StockItemID,
      p.StockItemName,
      STRING_AGG(np.StockGroupName, ', ') as [Group],
      ip.QuantityOnHand

  FROM productos p
  LEFT JOIN inventario_productos ip on ip.StockItemID = p.StockItemID
  LEFT JOIN grupos_productos gp on gp.StockItemID = p.StockItemID
  LEFT JOIN nombre_grupo_producto np on np.StockGroupID = gp.StockGroupID
  WHERE (
    @Nombre IS NULL
    OR @Nombre = ''
    OR p.StockItemName LIKE '%' + @Nombre + '%'
  ) AND (
    @GrupoID IS NULL
    OR EXISTS (
      SELECT 1
      FROM grupos_productos g
      WHERE g.StockItemID = p.StockItemID AND g.StockGroupID = @GrupoID
    )
  ) AND (
    @CantidadMinima IS NULL
    OR ip.QuantityOnHand >= @CantidadMinima
  ) AND (
    @CantidadMaxima IS NULL
    OR ip.QuantityOnHand <= @CantidadMaxima 
  )

  GROUP BY p.StockItemID, p.StockItemName, ip.QuantityOnHand
  ORDER BY p.StockItemName ASC
  OFFSET (@NumeroPagina - 1) * @CantidadRegistros ROWS
  FETCH NEXT @CantidadRegistros ROWS ONLY
END
GO

/*
Devuelve los grupos de productos que tienen al menos un producto asociado
Entradas:
    - No recibe entradas
Salidas:
    - Grupo de productos que tienen al menos un producto asociadp
Restricciones:
    - No posee restricciones
*/
CREATE OR ALTER PROCEDURE ObtenerGruposProductos
AS
BEGIN
  SELECT
      DISTINCT (ng.StockGroupName),
      ng.StockGroupID
  FROM nombre_grupo_producto ng
  INNER JOIN grupos_productos gp on gp.StockGroupID = ng.StockGroupID
END
GO

/*
  Devuelve los datos de un producto y su Version.
  Version es el ValidFrom del producto: la API la guarda y la manda al Corporativo
  al editar (EditarDatosProducto) para el control de concurrencia optimista.
  El inventario (QuantityOnHand, BinLocation) es el de esta sucursal.
*/
CREATE OR ALTER PROCEDURE ObtenerDatosProducto
  @Nombre_Producto nvarchar(100) = NULL,
  @ID_Producto int = NULL
AS
BEGIN
  SELECT
    p.StockItemID,
    p.StockItemName,
    p.SupplierID,
    pr.SupplierName,
    p.ColorID,
    ISNULL(c.ColorName, 'No posee color registrado') AS Color,
    p.UnitPackageID,
    tp.PackageTypeName AS UnitPackage,
    p.OuterPackageID,
    tp1.PackageTypeName AS OuterPackage,
    p.QuantityPerOuter,
    ISNULL(p.Brand, 'No posee marca') AS Brand,
    ISNULL(p.Size, 'No indica tamaño') AS Size,
    p.TaxRate,
    p.UnitPrice,
    ISNULL(CAST(p.RecommendedRetailPrice AS nvarchar(25)), 'No indica') AS RecommendedRetailPrice,
    p.TypicalWeightPerUnit,
    ip.QuantityOnHand,
    ip.BinLocation,
    p.SearchDetails,
    p.MarketingComments,
    (SELECT STRING_AGG(CAST(g.StockGroupID AS nvarchar(10)), ',')
     FROM grupos_productos g
     WHERE g.StockItemID = p.StockItemID) AS GruposIDs,
    CONVERT(varchar(27), p.ValidFrom, 121) AS Version
  FROM productos p
  INNER JOIN proveedores pr ON pr.SupplierID = p.SupplierID
  INNER JOIN tipos_paquetes_productos tp ON tp.PackageTypeID = p.UnitPackageID
  INNER JOIN tipos_paquetes_productos tp1 ON tp1.PackageTypeID = p.OuterPackageID
  LEFT JOIN inventario_productos ip ON ip.StockItemID = p.StockItemID
  LEFT JOIN colores_productos c ON c.ColorID = p.ColorID
  WHERE (@ID_Producto IS NULL AND p.StockItemName = @Nombre_Producto)
     OR (@ID_Producto IS NOT NULL AND p.StockItemID = @ID_Producto)
END
GO

SET NOEXEC OFF
GO
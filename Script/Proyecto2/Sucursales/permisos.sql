-- Este archivo se ejecuta en las 2 sucursales (WWI_SanJose y WWI_Limon)
IF DB_NAME() NOT IN ('WWI_SanJose', 'WWI_Limon')
BEGIN
  PRINT 'ERROR: está en la base ' + DB_NAME() + '. Elija WWI_SanJose o WWI_Limon.'
  SET NOEXEC ON
END
GO

/*
   Permisos del rol Administrador en la sucursal.
   El login de la API (api_sanjose / api_limon) solo puede ejecutar estos SPs.
   No puede leer ni modificar tablas directamente.
*/

-- Generales
GRANT EXECUTE ON ObtenerTodasCategoriasProveedores TO rol_administrador
GRANT EXECUTE ON ObtenerTodasCategoriasClientes TO rol_administrador
GRANT EXECUTE ON ObtenerMetodosDeEntregaGeneral TO rol_administrador
GRANT EXECUTE ON ObtenerTodasGruposProductos TO rol_administrador
GRANT EXECUTE ON ObtenerTiposDePaquete TO rol_administrador
GRANT EXECUTE ON ObtenerColoresProductos TO rol_administrador
GRANT EXECUTE ON ObtenerFechasVentasAnioProveedor TO rol_administrador
GRANT EXECUTE ON BuscarPersonas TO rol_administrador

-- Clientes (solo consulta)
GRANT EXECUTE ON GetClientes TO rol_administrador
GRANT EXECUTE ON BuscarFiltrarClientes TO rol_administrador
GRANT EXECUTE ON ObtenerCategoriasClientes TO rol_administrador
GRANT EXECUTE ON ObtenerMetodosDeEntregaClientes TO rol_administrador
GRANT EXECUTE ON ObtenerDatosClientes TO rol_administrador

-- Proveedores (solo consulta)
GRANT EXECUTE ON GetProveedores TO rol_administrador
GRANT EXECUTE ON BuscarProveedores TO rol_administrador
GRANT EXECUTE ON ObtenerCategoriasProveedores TO rol_administrador
GRANT EXECUTE ON ObtenerMetodosDeEntregaProveedores TO rol_administrador
GRANT EXECUTE ON ObtenerDatosProveedor TO rol_administrador

-- Productos (consulta) e inventario propio
GRANT EXECUTE ON GetProductos TO rol_administrador
GRANT EXECUTE ON BuscarProductos TO rol_administrador
GRANT EXECUTE ON ObtenerGruposProductos TO rol_administrador
GRANT EXECUTE ON ObtenerDatosProducto TO rol_administrador
GRANT EXECUTE ON ActualizarInventarioProducto TO rol_administrador

-- Facturas de la sucursal
GRANT EXECUTE ON GetFacturas TO rol_administrador
GRANT EXECUTE ON BuscarFacturas TO rol_administrador
GRANT EXECUTE ON ObtenerEncabezadoFactura TO rol_administrador
GRANT EXECUTE ON ObtenerDetalleFactura TO rol_administrador
GRANT EXECUTE ON CrearFactura TO rol_administrador
GRANT EXECUTE ON EditarDatosFactura TO rol_administrador
GRANT EXECUTE ON EliminarFactura TO rol_administrador
GO

SET NOEXEC OFF
GO

const express = require('express');
const { sql } = require('../db');
const { ejecutarSP, errorServidor, aEntero, leerPaginacion } = require('../helpers');

const router = express.Router();

/*
  Estadísticas: solo para el rol Corporativo (se controla en server.js).
  Todas se ejecutan en el Corporativo (req.nodo = 'Corporativo').

  Los 7 reportes de VENTAS reciben ?sucursal=SanJose | Limon
  y si no se manda, el reporte es CONSOLIDADO (las dos sucursales).
  Los 3 reportes de COMPRAS son del Corporativo (compras centralizadas),
  entonces siempre son consolidados.
*/

// Lee ?sucursal=. Devuelve null si viene vacío (consolidado) o 'invalida' si no existe
function leerSucursal(query) {
  const sucursal = query.sucursal;
  if (sucursal === undefined || sucursal === '' || sucursal === 'Consolidado') return null;
  if (sucursal === 'SanJose' || sucursal === 'Limon') return sucursal;
  return 'invalida';
}

// Middleware para los reportes de ventas: valida la sucursal y la deja en req.sucursal
function validarSucursal(req, res, next) {
  const sucursal = leerSucursal(req.query);

  if (sucursal === 'invalida') {
    return res.status(400).json({ ok: false, error: 'La sucursal debe ser SanJose, Limon o vacía (consolidado)' });
  }

  req.sucursal = sucursal;
  next();
}

// Parámetro @Sucursal de los reportes de ventas (null = consolidado, no se manda)
function paramSucursal(req) {
  return { nombre: 'Sucursal', tipo: sql.NVarChar(20), valor: req.sucursal };
}

// Parámetros de paginación que llevan casi todos los reportes
function paramsPagina(pagina, cantidad) {
  return [
    { nombre: 'NumeroPagina', tipo: sql.Int, valor: pagina },
    { nombre: 'CantidadRegistros', tipo: sql.Int, valor: cantidad }
  ];
}

// Rango de años de los tres tops: ?anioInicio=2014&anioFin=2015
function paramsRango(query) {
  return [
    { nombre: 'InicioRango', tipo: sql.Int, valor: aEntero(query.anioInicio) },
    { nombre: 'FinalRango', tipo: sql.Int, valor: aEntero(query.anioFin) }
  ];
}

// Filtros que comparten los dos seguimientos de compras
function paramsFiltrosSeguimiento(query) {
  return [
    { nombre: 'Anio', tipo: sql.Int, valor: aEntero(query.anio) },
    { nombre: 'Mes', tipo: sql.Int, valor: aEntero(query.mes) },
    { nombre: 'ID_Categoria', tipo: sql.Int, valor: aEntero(query.categoriaId) },
    { nombre: 'ID_Subcategoria', tipo: sql.Int, valor: aEntero(query.subcategoriaId) }
  ];
}

// Ejecuta el SP del reporte y responde con los datos
async function responderReporte(req, res, nombreSP, parametros, pagina, cantidad) {
  try {
    const filas = await ejecutarSP(req.nodo, nombreSP, parametros);
    res.json({ ok: true, sucursal: req.sucursal || 'Consolidado', pagina, cantidad, datos: filas });
  } catch (error) {
    errorServidor(res, error);
  }
}

// 1. GET /api/reportes/compras-proveedores?proveedor=datum&categoria=novelty  (compras: consolidado)
router.get('/compras-proveedores', (req, res) => {
  const { pagina, cantidad } = leerPaginacion(req.query);

  const parametros = [
    { nombre: 'Nombre_Proveedor', tipo: sql.NVarChar(100), valor: req.query.proveedor },
    { nombre: 'Categoria', tipo: sql.NVarChar(100), valor: req.query.categoria },
    ...paramsPagina(pagina, cantidad)
  ];

  responderReporte(req, res, 'ObtenerDatosCompraProveedores', parametros, pagina, cantidad);
});

// 2. GET /api/reportes/ventas-clientes?cliente=toys&categoria=novelty&sucursal=Limon
router.get('/ventas-clientes', validarSucursal, (req, res) => {
  const { pagina, cantidad } = leerPaginacion(req.query);

  const parametros = [
    { nombre: 'Nombre_Cliente', tipo: sql.NVarChar(100), valor: req.query.cliente },
    { nombre: 'Categoria', tipo: sql.NVarChar(100), valor: req.query.categoria },
    paramSucursal(req),
    ...paramsPagina(pagina, cantidad)
  ];

  responderReporte(req, res, 'ObtenerDatosVentasCompradores', parametros, pagina, cantidad);
});

// 3. GET /api/reportes/top-productos?anioInicio=2014&anioFin=2015&sucursal=SanJose
router.get('/top-productos', validarSucursal, (req, res) => {
  const { pagina, cantidad } = leerPaginacion(req.query);
  const parametros = [...paramsRango(req.query), paramSucursal(req), ...paramsPagina(pagina, cantidad)];

  responderReporte(req, res, 'ObtenerTopCincoProductos', parametros, pagina, cantidad);
});

// 4. GET /api/reportes/top-clientes?anioInicio=2014&anioFin=2015&sucursal=Limon
router.get('/top-clientes', validarSucursal, (req, res) => {
  const { pagina, cantidad } = leerPaginacion(req.query);
  const parametros = [...paramsRango(req.query), paramSucursal(req), ...paramsPagina(pagina, cantidad)];

  responderReporte(req, res, 'ObtenerTopCincoClientes', parametros, pagina, cantidad);
});

// 5. GET /api/reportes/top-proveedores?anioInicio=2014&anioFin=2015  (compras: consolidado)
router.get('/top-proveedores', (req, res) => {
  const { pagina, cantidad } = leerPaginacion(req.query);
  const parametros = [...paramsRango(req.query), ...paramsPagina(pagina, cantidad)];

  responderReporte(req, res, 'ObtenerTopCincoProveedores', parametros, pagina, cantidad);
});

// 6. GET /api/reportes/resumen-categorias?sucursal=SanJose  (matriz)
router.get('/resumen-categorias', validarSucursal, async (req, res) => {
  try {
    const filas = await ejecutarSP(req.nodo, 'ResumenDeVentaPorCategoria', [paramSucursal(req)]);
    res.json({ ok: true, sucursal: req.sucursal || 'Consolidado', datos: filas });
  } catch (error) {
    errorServidor(res, error);
  }
});

// 7. GET /api/reportes/seguimiento-clientes?clienteId=1&anio=2015&mes=2&categoriaId=2&sucursal=Limon
router.get('/seguimiento-clientes', validarSucursal, (req, res) => {
  const { pagina, cantidad } = leerPaginacion(req.query);

  const parametros = [
    { nombre: 'ID_Cliente', tipo: sql.Int, valor: aEntero(req.query.clienteId) },
    ...paramsFiltrosSeguimiento(req.query),
    paramSucursal(req),
    ...paramsPagina(pagina, cantidad)
  ];

  responderReporte(req, res, 'ObtenerSeguimientoComprasClientes', parametros, pagina, cantidad);
});

// 8. GET /api/reportes/seguimiento-proveedores?proveedorId=2&anio=2015&mes=2&categoriaId=2  (compras: consolidado)
router.get('/seguimiento-proveedores', (req, res) => {
  const { pagina, cantidad } = leerPaginacion(req.query);

  const parametros = [
    { nombre: 'ID_Proveedor', tipo: sql.Int, valor: aEntero(req.query.proveedorId) },
    ...paramsFiltrosSeguimiento(req.query),
    ...paramsPagina(pagina, cantidad)
  ];

  responderReporte(req, res, 'ObtenerSeguimientoComprasProveedores', parametros, pagina, cantidad);
});

// 9. GET /api/reportes/rotacion-inventario?anio=2013&proveedorId=2&categoriaId=2&productoId=10&sucursal=SanJose
router.get('/rotacion-inventario', validarSucursal, (req, res) => {
  const { pagina, cantidad } = leerPaginacion(req.query);

  const parametros = [
    { nombre: 'ID_Producto', tipo: sql.Int, valor: aEntero(req.query.productoId) },
    { nombre: 'Anio', tipo: sql.Int, valor: aEntero(req.query.anio) },
    { nombre: 'ID_Proveedor', tipo: sql.Int, valor: aEntero(req.query.proveedorId) },
    { nombre: 'ID_CategoriaProducto', tipo: sql.Int, valor: aEntero(req.query.categoriaId) },
    paramSucursal(req),
    ...paramsPagina(pagina, cantidad)
  ];

  responderReporte(req, res, 'PromedioDiasRotacionProducto', parametros, pagina, cantidad);
});

// 10. GET /api/reportes/metodo-envio-favorito?anio=2013&mes=5&categoriaClienteId=3&categoriaProductoId=2&productoId=10&sucursal=Limon
router.get('/metodo-envio-favorito', validarSucursal, (req, res) => {
  const { pagina, cantidad } = leerPaginacion(req.query);

  const parametros = [
    { nombre: 'Anio', tipo: sql.Int, valor: aEntero(req.query.anio) },
    { nombre: 'Mes', tipo: sql.Int, valor: aEntero(req.query.mes) },
    { nombre: 'ID_CategoriaCliente', tipo: sql.Int, valor: aEntero(req.query.categoriaClienteId) },
    { nombre: 'ID_CategoriaProducto', tipo: sql.Int, valor: aEntero(req.query.categoriaProductoId) },
    { nombre: 'ID_Producto', tipo: sql.Int, valor: aEntero(req.query.productoId) },
    paramSucursal(req),
    ...paramsPagina(pagina, cantidad)
  ];

  responderReporte(req, res, 'MetodoEnvioFavoritoPorCuidad', parametros, pagina, cantidad);
});

/*
  Vista materializada (tablas de resumen del Corporativo)
  El job del Agent la refresca cada 5 minutos; estas rutas permiten ver
  cuándo fue el último corte y forzar una actualización desde la página.
*/

// GET /api/reportes/estado-resumen
router.get('/estado-resumen', async (req, res) => {
  try {
    const filas = await ejecutarSP(req.nodo, 'ObtenerEstadoResumen');
    res.json({ ok: true, datos: filas });
  } catch (error) {
    errorServidor(res, error);
  }
});

// POST /api/reportes/actualizar-resumen  (si una sucursal no responde, se mantiene su último corte)
router.post('/actualizar-resumen', async (req, res) => {
  try {
    const filas = await ejecutarSP(req.nodo, 'ActualizarResumenVentas');
    res.json({ ok: true, mensaje: 'Resumen actualizado', datos: filas });
  } catch (error) {
    errorServidor(res, error);
  }
});

module.exports = router;

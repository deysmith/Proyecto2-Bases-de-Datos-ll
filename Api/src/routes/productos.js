const express = require('express');
const { sql } = require('../db');
const {
  ejecutarSP, hayError, responderError, errorServidor, aEntero, leerPaginacion, armarParametros, esperar
} = require('../helpers');
const { permitirRoles } = require('../seguridad');

const router = express.Router();

/*
  Productos del catálogo replicado

  - Las consultas se hacen en la sucursal del usuario (req.nodo): ahí está el catálogo replicado y el inventario propio de esa sucursal.
  - Crear, modificar y eliminar se hace en el Corporativo (nodo 'Productos'), que es el único maestro del catálogo. 
    La replicación transaccional lo lleva a San José y Limón en pocos segundos.
  - El inventario (cantidad y ubicación) es propio de cada sucursal, por eso se actualiza aparte, en la sucursal del usuario, con ActualizarInventarioProducto.
*/
const soloAdmin = permitirRoles('Administrador');

// Datos del catálogo (va al Corporativo). Ya no llevan inventario.
const camposAgregar = [
  { nombre: 'Nombre_Producto', tipo: sql.NVarChar(100) },
  { nombre: 'ProveedorID', tipo: sql.Int },
  { nombre: 'ColorID', tipo: sql.Int },
  { nombre: 'UnitPackageID', tipo: sql.Int },
  { nombre: 'OuterPackageID', tipo: sql.Int },
  { nombre: 'Marca', tipo: sql.NVarChar(50) },
  { nombre: 'Size', tipo: sql.NVarChar(20) },
  { nombre: 'QuantityPerOuter', tipo: sql.Int },
  { nombre: 'TaxRate', tipo: sql.Decimal(18, 3) },
  { nombre: 'UnitPrice', tipo: sql.Decimal(18, 2) },
  { nombre: 'RecommendedPrice', tipo: sql.Decimal(18, 2) },
  { nombre: 'TypicalWeight', tipo: sql.Decimal(18, 3) },
  { nombre: 'MarketingSearchDetails', tipo: sql.NVarChar(sql.MAX) },
  { nombre: 'Grupos_Productos', tipo: sql.NVarChar(100) }
];

const camposEditar = [
  { nombre: 'Version', tipo: sql.VarChar(27) },
  { nombre: 'Nombre_Producto', tipo: sql.NVarChar(100) },
  { nombre: 'ColorID', tipo: sql.Int },
  { nombre: 'UnitPackageID', tipo: sql.Int },
  { nombre: 'OuterPackageID', tipo: sql.Int },
  { nombre: 'Marca', tipo: sql.NVarChar(50) },
  { nombre: 'Size', tipo: sql.NVarChar(20) },
  { nombre: 'QuantityPerOuter', tipo: sql.Int },
  { nombre: 'TaxRate', tipo: sql.Decimal(18, 3) },
  { nombre: 'UnitPrice', tipo: sql.Decimal(18, 2) },
  { nombre: 'RecommendedPrice', tipo: sql.Decimal(18, 2) },
  { nombre: 'TypicalWeight', tipo: sql.Decimal(18, 3) },
  { nombre: 'MarketingSearchDetails', tipo: sql.NVarChar(sql.MAX) },
  { nombre: 'Grupos_Productos', tipo: sql.NVarChar(100) }
];

// Datos del inventario (va a la sucursal del usuario)
const camposInventario = [
  { nombre: 'QuantityOnHand', tipo: sql.Int },
  { nombre: 'BinLocation', tipo: sql.NVarChar(20) }
];

// Estos no tienen valor por defecto en el SP, entonces son obligatorios
const camposObligatorios = [
  'Nombre_Producto', 'ProveedorID', 'UnitPackageID', 'OuterPackageID',
  'QuantityPerOuter', 'TaxRate', 'UnitPrice', 'TypicalWeight',
  'MarketingSearchDetails', 'Grupos_Productos'
];

// Si los grupos vienen como arreglo [1, 2, 3] los convierte a "1,2,3"
function prepararGrupos(body) {
  if (Array.isArray(body.Grupos_Productos)) {
    body.Grupos_Productos = body.Grupos_Productos.join(',');
  }
}

// ¿El body trae algo del inventario?
function traeInventario(body) {
  return body.QuantityOnHand !== undefined || body.BinLocation !== undefined;
}

/*
  Actualiza el inventario del producto en la sucursal del usuario.
  Si el producto es nuevo, puede que la replicación todavía no lo haya llevado
  a la sucursal (error 50041). En ese caso se espera 2 segundos y se intenta otra vez, hasta 'intentos' veces.
*/
async function actualizarInventario(nodo, idProducto, body, intentos = 1) {
  const parametros = armarParametros(camposInventario, body);
  parametros.push({ nombre: 'ID_Producto', tipo: sql.Int, valor: idProducto });

  let filas = [];
  for (let i = 1; i <= intentos; i++) {
    filas = await ejecutarSP(nodo, 'ActualizarInventarioProducto', parametros);

    const noHaLlegado = hayError(filas) && filas[0].NumeroError === 50041;
    if (!noHaLlegado || i === intentos) break;

    await esperar(2000);
  }

  return filas;
}

// GET /api/productos?pagina=1&cantidad=20
router.get('/', soloAdmin, async (req, res) => {
  try {
    const { pagina, cantidad } = leerPaginacion(req.query);

    const filas = await ejecutarSP(req.nodo, 'GetProductos', [
      { nombre: 'NumeroPagina', tipo: sql.Int, valor: pagina },
      { nombre: 'CantidadRegistros', tipo: sql.Int, valor: cantidad }
    ]);

    res.json({ ok: true, pagina, cantidad, datos: filas });
  } catch (error) {
    errorServidor(res, error);
  }
});

// GET /api/productos/buscar?nombre=shirt&grupoId=2&cantidadMinima=10&cantidadMaxima=500
router.get('/buscar', permitirRoles('Administrador', 'Corporativo'), async (req, res) => {
  try {
    const { pagina, cantidad } = leerPaginacion(req.query);

    const filas = await ejecutarSP(req.nodo, 'BuscarProductos', [
      { nombre: 'Nombre', tipo: sql.NVarChar(100), valor: req.query.nombre },
      { nombre: 'GrupoID', tipo: sql.Int, valor: aEntero(req.query.grupoId) },
      { nombre: 'CantidadMinima', tipo: sql.Int, valor: aEntero(req.query.cantidadMinima) },
      { nombre: 'CantidadMaxima', tipo: sql.Int, valor: aEntero(req.query.cantidadMaxima) },
      { nombre: 'NumeroPagina', tipo: sql.Int, valor: pagina },
      { nombre: 'CantidadRegistros', tipo: sql.Int, valor: cantidad }
    ]);

    res.json({ ok: true, pagina, cantidad, datos: filas });
  } catch (error) {
    errorServidor(res, error);
  }
});

// GET /api/productos/grupos  (solo los grupos con productos, para los filtros)
router.get('/grupos', soloAdmin, async (req, res) => {
  try {
    const filas = await ejecutarSP(req.nodo, 'ObtenerGruposProductos');
    res.json({ ok: true, datos: filas });
  } catch (error) {
    errorServidor(res, error);
  }
});

// GET /api/productos/detalle?nombre=Camiseta TEC
router.get('/detalle', soloAdmin, async (req, res) => {
  try {
    const nombre = req.query.nombre;

    if (!nombre) {
      return res.status(400).json({ ok: false, error: 'Falta el parámetro nombre' });
    }

    const filas = await ejecutarSP(req.nodo, 'ObtenerDatosProducto', [
      { nombre: 'Nombre_Producto', tipo: sql.NVarChar(100), valor: nombre }
    ]);

    if (filas.length === 0) {
      return res.status(404).json({ ok: false, error: 'Producto no encontrado' });
    }

    res.json({ ok: true, datos: filas[0] });
  } catch (error) {
    errorServidor(res, error);
  }
});

// GET /api/productos/10  (trae la columna Version, que se usa para editar)
router.get('/:id', soloAdmin, async (req, res) => {
  try {
    const id = aEntero(req.params.id);

    if (id === undefined) {
      return res.status(400).json({ ok: false, error: 'El ID del producto no es válido' });
    }

    const filas = await ejecutarSP(req.nodo, 'ObtenerDatosProducto', [
      { nombre: 'ID_Producto', tipo: sql.Int, valor: id }
    ]);

    if (filas.length === 0) {
      return res.status(404).json({ ok: false, error: 'Producto no encontrado' });
    }

    res.json({ ok: true, datos: filas[0] });
  } catch (error) {
    errorServidor(res, error);
  }
});

/*
  POST /api/productos
  1. Crea el producto en el Corporativo (se replica a las dos sucursales).
  2. Si viene cantidad o ubicación, la asigna en la sucursal del usuario, esperando a que llegue la replicación (hasta 5 intentos, unos 10 segundos).
*/
router.post('/', soloAdmin, async (req, res) => {
  try {
    prepararGrupos(req.body);

    const faltantes = camposObligatorios.filter(
      (campo) => req.body[campo] === undefined || req.body[campo] === null
    );

    if (faltantes.length > 0) {
      return res.status(400).json({ ok: false, error: 'Faltan campos obligatorios', faltantes });
    }

    const filas = await ejecutarSP('Productos', 'AgregarNuevoProducto', armarParametros(camposAgregar, req.body));

    if (hayError(filas)) {
      return responderError(res, filas[0]);
    }

    const producto = filas[0]; // { StockItemID, Version }
    let inventario = null;
    let aviso = null;

    if (traeInventario(req.body)) {
      const filasInv = await actualizarInventario(req.nodo, producto.StockItemID, req.body, 5);

      if (hayError(filasInv)) {
        aviso = 'El producto se creó, pero el inventario no se pudo asignar todavía: ' + filasInv[0].MensajeError;
      } else {
        inventario = filasInv[0];
      }
    }

    res.status(201).json({ ok: true, mensaje: 'Producto creado', datos: { ...producto, inventario }, aviso });
  } catch (error) {
    errorServidor(res, error);
  }
});

/*
  PUT /api/productos/10  (solo se manda lo que se quiere cambiar y la versión)
  Concurrencia optimista: Version es la que tenía el producto cuando el usuario lo abrió. 
  Si otro administrador lo modificó antes, el SP responde 50040 y la API devuelve 409 para que el usuario recargue los datos.
*/
router.put('/:id', soloAdmin, async (req, res) => {
  try {
    const id = aEntero(req.params.id);

    if (id === undefined) {
      return res.status(400).json({ ok: false, error: 'El ID del producto no es válido' });
    }

    if (!req.body.Version) {
      return res.status(400).json({ ok: false, error: 'Falta la versión del producto (Version), recargue los datos' });
    }

    prepararGrupos(req.body);

    const parametros = armarParametros(camposEditar, req.body);
    parametros.push({ nombre: 'ID_Producto', tipo: sql.Int, valor: id });

    const filas = await ejecutarSP('Productos', 'EditarDatosProducto', parametros);

    if (hayError(filas)) {
      return responderError(res, filas[0]);
    }

    const producto = filas[0]; // { StockItemID, Version nueva }
    let inventario = null;
    let aviso = null;

    // El inventario se actualiza en la sucursal solo si el producto se pudo modificar
    if (traeInventario(req.body)) {
      const filasInv = await actualizarInventario(req.nodo, id, req.body);

      if (hayError(filasInv)) {
        aviso = 'El producto se modificó, pero el inventario no: ' + filasInv[0].MensajeError;
      } else {
        inventario = filasInv[0];
      }
    }

    res.json({ ok: true, mensaje: 'Producto actualizado', datos: { ...producto, inventario }, aviso });
  } catch (error) {
    errorServidor(res, error);
  }
});

// PUT /api/productos/10/inventario  { QuantityOnHand, BinLocation }  (solo en la sucursal del usuario)
router.put('/:id/inventario', soloAdmin, async (req, res) => {
  try {
    const id = aEntero(req.params.id);

    if (id === undefined) {
      return res.status(400).json({ ok: false, error: 'El ID del producto no es válido' });
    }

    if (!traeInventario(req.body)) {
      return res.status(400).json({ ok: false, error: 'Debe indicar la cantidad (QuantityOnHand) o la ubicación (BinLocation)' });
    }

    const filas = await actualizarInventario(req.nodo, id, req.body);

    if (hayError(filas)) {
      return responderError(res, filas[0]);
    }

    res.json({ ok: true, mensaje: 'Inventario actualizado', datos: filas[0] });
  } catch (error) {
    errorServidor(res, error);
  }
});

/*
  DELETE /api/productos/10
  Se borra en el Corporativo. El SP revisa antes, por servidor vinculado, que el
  producto no tenga ventas ni inventario en ninguna sucursal; si una sucursal no responde, no se borra (503).
*/
router.delete('/:id', soloAdmin, async (req, res) => {
  try {
    const id = aEntero(req.params.id);

    if (id === undefined) {
      return res.status(400).json({ ok: false, error: 'El ID del producto no es válido' });
    }

    const filas = await ejecutarSP('Productos', 'EliminarProducto', [
      { nombre: 'ID_Producto', tipo: sql.Int, valor: id }
    ]);

    if (hayError(filas)) {
      // 50025 y 50026 aquí significan "tiene ventas o inventario en una sucursal"
      if ([50025, 50026].includes(filas[0].NumeroError)) {
        return res.status(409).json({ ok: false, codigo: filas[0].NumeroError, error: filas[0].MensajeError });
      }
      return responderError(res, filas[0]);
    }

    res.json({ ok: true, mensaje: 'Producto eliminado' });
  } catch (error) {
    errorServidor(res, error);
  }
});

module.exports = router;

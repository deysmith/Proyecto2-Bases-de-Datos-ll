const express = require('express');
const { sql } = require('../db');
const { ejecutarSP, errorServidor, aEntero, leerPaginacion } = require('../helpers');
const { permitirRoles } = require('../seguridad');

const router = express.Router();

/*
  Proveedores: el Administrador solo CONSULTA. El catálogo está replicado en las
  sucursales sin las columnas sensibles; esas (banco, teléfonos, ubicación) se
  traen del Corporativo dentro del SP ObtenerDatosProveedor.
  El Corporativo solo usa GET / (lista para los filtros de Estadísticas).
*/
const soloAdmin = permitirRoles('Administrador');

// GET /api/proveedores?pagina=1&cantidad=20
router.get('/', permitirRoles('Administrador', 'Corporativo'), async (req, res) => {
  try {
    const { pagina, cantidad } = leerPaginacion(req.query);

    const filas = await ejecutarSP(req.nodo, 'GetProveedores', [
      { nombre: 'NumeroPagina', tipo: sql.Int, valor: pagina },
      { nombre: 'CantidadRegistros', tipo: sql.Int, valor: cantidad }
    ]);

    res.json({ ok: true, pagina, cantidad, datos: filas });
  } catch (error) {
    errorServidor(res, error);
  }
});

// GET /api/proveedores/buscar?nombre=novelty&categoriaId=2&metodoEntregaId=1&pagina=1&cantidad=20
router.get('/buscar', soloAdmin, async (req, res) => {
  try {
    const { pagina, cantidad } = leerPaginacion(req.query);

    const filas = await ejecutarSP(req.nodo, 'BuscarProveedores', [
      { nombre: 'Nombre_Proveedor', tipo: sql.NVarChar(100), valor: req.query.nombre },
      { nombre: 'CategoriaID', tipo: sql.Int, valor: aEntero(req.query.categoriaId) },
      { nombre: 'MetodoEntegaID', tipo: sql.Int, valor: aEntero(req.query.metodoEntregaId) },
      { nombre: 'NumeroPagina', tipo: sql.Int, valor: pagina },
      { nombre: 'CantidadRegistros', tipo: sql.Int, valor: cantidad }
    ]);

    res.json({ ok: true, pagina, cantidad, datos: filas });
  } catch (error) {
    errorServidor(res, error);
  }
});

// GET /api/proveedores/categorias  (solo las que tienen proveedores, para los filtros)
router.get('/categorias', soloAdmin, async (req, res) => {
  try {
    const filas = await ejecutarSP(req.nodo, 'ObtenerCategoriasProveedores');
    res.json({ ok: true, datos: filas });
  } catch (error) {
    errorServidor(res, error);
  }
});

// GET /api/proveedores/metodos-entrega  (solo los usados por proveedores, para los filtros)
router.get('/metodos-entrega', soloAdmin, async (req, res) => {
  try {
    const filas = await ejecutarSP(req.nodo, 'ObtenerMetodosDeEntregaProveedores');
    res.json({ ok: true, datos: filas });
  } catch (error) {
    errorServidor(res, error);
  }
});

// GET /api/proveedores/detalle?nombre=A Datum Corporation
router.get('/detalle', soloAdmin, async (req, res) => {
  try {
    const nombre = req.query.nombre;

    if (!nombre) {
      return res.status(400).json({ ok: false, error: 'Falta el parámetro nombre' });
    }

    const filas = await ejecutarSP(req.nodo, 'ObtenerDatosProveedor', [
      { nombre: 'Nombre_Proveedor', tipo: sql.NVarChar(100), valor: nombre }
    ]);

    if (filas.length === 0) {
      return res.status(404).json({ ok: false, error: 'Proveedor no encontrado' });
    }

    res.json({ ok: true, datos: filas[0] });
  } catch (error) {
    errorServidor(res, error);
  }
});

// GET /api/proveedores/18
router.get('/:id', soloAdmin, async (req, res) => {
  try {
    const id = aEntero(req.params.id);

    if (id === undefined) {
      return res.status(400).json({ ok: false, error: 'El ID del proveedor no es válido' });
    }

    const filas = await ejecutarSP(req.nodo, 'ObtenerDatosProveedor', [
      { nombre: 'ID_Proveedor', tipo: sql.Int, valor: id }
    ]);

    if (filas.length === 0) {
      return res.status(404).json({ ok: false, error: 'Proveedor no encontrado' });
    }

    res.json({ ok: true, datos: filas[0] });
  } catch (error) {
    errorServidor(res, error);
  }
});

module.exports = router;

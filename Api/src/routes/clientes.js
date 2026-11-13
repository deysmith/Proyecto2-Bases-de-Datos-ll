const express = require('express');
const { sql } = require('../db');
const { ejecutarSP, errorServidor, aEntero, leerPaginacion } = require('../helpers');
const { permitirRoles } = require('../seguridad');

const router = express.Router();

/*
  Clientes: el Administrador solo consulta clientes.
  Todo se ejecuta en la sede del usuario (req.nodo); cada sucursal solo tiene
  sus clientes (fragmentación horizontal) y los datos sensibles se traen del
  Corporativo por servidor vinculado dentro del SP ObtenerDatosClientes.
  El Corporativo solo usa /buscar, para los filtros de Estadísticas.
*/
const soloAdmin = permitirRoles('Administrador');

// GET /api/clientes?pagina=1&cantidad=20
router.get('/', soloAdmin, async (req, res) => {
  try {
    const { pagina, cantidad } = leerPaginacion(req.query);

    const filas = await ejecutarSP(req.nodo, 'GetClientes', [
      { nombre: 'NumeroPagina', tipo: sql.Int, valor: pagina },
      { nombre: 'CantidadRegistros', tipo: sql.Int, valor: cantidad }
    ]);

    res.json({ ok: true, pagina, cantidad, datos: filas });
  } catch (error) {
    errorServidor(res, error);
  }
});

// GET /api/clientes/buscar?criterio=toys&categoriaId=3&metodoEntregaId=2&pagina=1&cantidad=20
router.get('/buscar', permitirRoles('Administrador', 'Corporativo'), async (req, res) => {
  try {
    const { pagina, cantidad } = leerPaginacion(req.query);

    const filas = await ejecutarSP(req.nodo, 'BuscarFiltrarClientes', [
      { nombre: 'Criterio', tipo: sql.NVarChar(100), valor: req.query.criterio },
      { nombre: 'CategoriaID', tipo: sql.Int, valor: aEntero(req.query.categoriaId) },
      { nombre: 'MetodoEntregaID', tipo: sql.Int, valor: aEntero(req.query.metodoEntregaId) },
      { nombre: 'NumeroPagina', tipo: sql.Int, valor: pagina },
      { nombre: 'CantidadRegistros', tipo: sql.Int, valor: cantidad }
    ]);

    res.json({ ok: true, pagina, cantidad, datos: filas });
  } catch (error) {
    errorServidor(res, error);
  }
});

// GET /api/clientes/categorias  (solo las que tienen clientes, para los filtros)
router.get('/categorias', soloAdmin, async (req, res) => {
  try {
    const filas = await ejecutarSP(req.nodo, 'ObtenerCategoriasClientes');
    res.json({ ok: true, datos: filas });
  } catch (error) {
    errorServidor(res, error);
  }
});

// GET /api/clientes/metodos-entrega  (solo los usados por clientes, para los filtros)
router.get('/metodos-entrega', soloAdmin, async (req, res) => {
  try {
    const filas = await ejecutarSP(req.nodo, 'ObtenerMetodosDeEntregaClientes');
    res.json({ ok: true, datos: filas });
  } catch (error) {
    errorServidor(res, error);
  }
});

// GET /api/clientes/detalle?nombre=Tailspin Toys (Sylvanite, MT)
router.get('/detalle', soloAdmin, async (req, res) => {
  try {
    const nombre = req.query.nombre;

    if (!nombre) {
      return res.status(400).json({ ok: false, error: 'Falta el parámetro nombre' });
    }

    const filas = await ejecutarSP(req.nodo, 'ObtenerDatosClientes', [
      { nombre: 'Nombre_Cliente', tipo: sql.NVarChar(100), valor: nombre }
    ]);

    if (filas.length === 0) {
      return res.status(404).json({ ok: false, error: 'Cliente no encontrado en esta sucursal' });
    }

    res.json({ ok: true, datos: filas[0] });
  } catch (error) {
    errorServidor(res, error);
  }
});

// GET /api/clientes/1164
router.get('/:id', soloAdmin, async (req, res) => {
  try {
    const id = aEntero(req.params.id);

    if (id === undefined) {
      return res.status(400).json({ ok: false, error: 'El ID del cliente no es válido' });
    }

    const filas = await ejecutarSP(req.nodo, 'ObtenerDatosClientes', [
      { nombre: 'ID_Cliente', tipo: sql.Int, valor: id }
    ]);

    if (filas.length === 0) {
      return res.status(404).json({ ok: false, error: 'Cliente no encontrado en esta sucursal' });
    }

    res.json({ ok: true, datos: filas[0] });
  } catch (error) {
    errorServidor(res, error);
  }
});

module.exports = router;
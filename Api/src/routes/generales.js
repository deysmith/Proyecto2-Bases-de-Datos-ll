const express = require('express');
const { sql } = require('../db');
const { ejecutarSP, errorServidor, aEntero } = require('../helpers');
const { permitirRoles } = require('../seguridad');

const router = express.Router();

/*
  Catálogos generales. Se ejecutan en la sede del usuario (req.nodo).
  roles: quién puede usar cada ruta. El Corporativo solo usa los catálogos
  que necesitan los filtros de Estadísticas.
*/
const ambos = ['Administrador', 'Corporativo'];
const soloAdmin = ['Administrador'];

const rutas = [
  { url: '/categorias-proveedores', sp: 'ObtenerTodasCategoriasProveedores', roles: soloAdmin },
  { url: '/categorias-clientes', sp: 'ObtenerTodasCategoriasClientes', roles: ambos },
  { url: '/metodos-entrega', sp: 'ObtenerMetodosDeEntregaGeneral', roles: soloAdmin },
  { url: '/grupos-productos', sp: 'ObtenerTodasGruposProductos', roles: ambos },
  { url: '/tipos-paquete', sp: 'ObtenerTiposDePaquete', roles: soloAdmin },
  { url: '/colores-productos', sp: 'ObtenerColoresProductos', roles: soloAdmin },
  { url: '/anios-ventas', sp: 'ObtenerFechasVentasAnioProveedor', roles: ambos }
];

rutas.forEach((ruta) => {
  router.get(ruta.url, permitirRoles(...ruta.roles), async (req, res) => {
    try {
      const filas = await ejecutarSP(req.nodo, ruta.sp);
      res.json({ ok: true, datos: filas });
    } catch (error) {
      errorServidor(res, error);
    }
  });
});

// GET /api/generales/ciudades?criterio=glen&cantidad=20  (solo existe en el Corporativo)
router.get('/ciudades', permitirRoles('Corporativo'), async (req, res) => {
  try {
    const cantidad = Math.min(aEntero(req.query.cantidad) || 20, 50);

    const filas = await ejecutarSP(req.nodo, 'BuscarCiudades', [
      { nombre: 'Criterio', tipo: sql.NVarChar(50), valor: req.query.criterio },
      { nombre: 'CantidadRegistros', tipo: sql.Int, valor: cantidad }
    ]);

    res.json({ ok: true, datos: filas });
  } catch (error) {
    errorServidor(res, error);
  }
});

// GET /api/generales/personas?criterio=an&soloVendedores=1&soloEmpleados=1  (para crear facturas)
router.get('/personas', permitirRoles('Administrador'), async (req, res) => {
  try {
    const cantidad = Math.min(aEntero(req.query.cantidad) || 20, 50);

    const filas = await ejecutarSP(req.nodo, 'BuscarPersonas', [
      { nombre: 'Criterio', tipo: sql.NVarChar(50), valor: req.query.criterio },
      { nombre: 'SoloVendedores', tipo: sql.Bit, valor: req.query.soloVendedores === '1' ? 1 : 0 },
      { nombre: 'SoloEmpleados', tipo: sql.Bit, valor: req.query.soloEmpleados === '1' ? 1 : 0 },
      { nombre: 'CantidadRegistros', tipo: sql.Int, valor: cantidad }
    ]);

    res.json({ ok: true, datos: filas });
  } catch (error) {
    errorServidor(res, error);
  }
});

module.exports = router;

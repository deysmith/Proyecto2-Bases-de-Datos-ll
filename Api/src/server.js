const express = require('express');
const cors = require('cors');
require('dotenv').config();

const { verificarToken, permitirRoles } = require('./seguridad');

const rutasAuth = require('./routes/auth');
const rutasGenerales = require('./routes/generales');
const rutasClientes = require('./routes/clientes');
const rutasProveedores = require('./routes/proveedores');
const rutasProductos = require('./routes/productos');
const rutasFacturas = require('./routes/facturas');
const rutasReportes = require('./routes/reportes');

const app = express();

app.use(cors());
app.use(express.json());

app.get('/', (req, res) => {
  res.json({ mensaje: 'API distribuida de Wide World Importers funcionando' });
});

// Rutas públicas: iniciar sesión y ver qué sedes responden
app.use('/api/auth', rutasAuth);

app.use('/api', verificarToken);

app.use('/api/generales', rutasGenerales);
app.use('/api/clientes', rutasClientes);
app.use('/api/proveedores', rutasProveedores);
app.use('/api/productos', rutasProductos);
app.use('/api/facturas', permitirRoles('Administrador'), rutasFacturas);
app.use('/api/reportes', permitirRoles('Corporativo'), rutasReportes);

// Cualquier otra ruta no existe (o se quitó, como POST/PUT/DELETE de clientes)
app.use((req, res) => {
  res.status(404).json({ ok: false, error: 'Ruta no encontrada' });
});

const puerto = process.env.PORT || 3000;
app.listen(puerto, () => {
  console.log(`API corriendo en http://localhost:${puerto}`);
});

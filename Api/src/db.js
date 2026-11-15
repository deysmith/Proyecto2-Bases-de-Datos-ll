const sql = require('mssql');
require('dotenv').config();

/*
  Conexiones de la API, una por sede y una para productos.

  - SanJose: SQL Server en Windows, login api_sanjose (rol_administrador)
  - Limon: SQL Server en contenedor Red Hat, login api_limon (rol_administrador)
  - Corporativo: SQL Server en contenedor Ubuntu, login api_corporativo (rol_corporativo)
  - Productos: el mismo Corporativo, pero con el login api_productos, que solo puede ejecutar los 3 SPs que modifican el catálogo de productos

  Cada login de la API solo tiene permiso de EXECUTE sobre sus SPs, nunca de leer tablas.
*/
const conexiones = {
  SanJose: {
    server: process.env.SJ_SERVER,
    port: parseInt(process.env.SJ_PORT),
    database: process.env.SJ_DB,
    user: process.env.SJ_USER,
    password: process.env.SJ_PASSWORD
  },
  Limon: {
    server: process.env.LIMON_SERVER,
    port: parseInt(process.env.LIMON_PORT),
    database: process.env.LIMON_DB,
    user: process.env.LIMON_USER,
    password: process.env.LIMON_PASSWORD
  },
  Corporativo: {
    server: process.env.CORP_SERVER,
    port: parseInt(process.env.CORP_PORT),
    database: process.env.CORP_DB,
    user: process.env.CORP_USER,
    password: process.env.CORP_PASSWORD
  },
  Productos: {
    server: process.env.CORP_SERVER,
    port: parseInt(process.env.CORP_PORT),
    database: process.env.CORP_DB,
    user: process.env.PRODUCTOS_USER,
    password: process.env.PRODUCTOS_PASSWORD
  }
};

// Nombre bonito de cada nodo, para los mensajes de error
const nombresNodos = {
  SanJose: 'San José',
  Limon: 'Limón',
  Corporativo: 'Corporativo',
  Productos: 'Corporativo'
};

// Aquí se guarda el pool de cada nodo cuando ya se conectó
const pools = {};

async function obtenerPool(nodo) {
  if (!conexiones[nodo]) {
    throw new Error(`El nodo ${nodo} no existe`);
  }

  if (!pools[nodo]) {
    const pool = new sql.ConnectionPool({
      ...conexiones[nodo],
      connectionTimeout: 5000, // si el nodo no responde en 5 segundos, se da por caído
      requestTimeout: 120000, // la actualización del resumen puede tardar
      options: {
        encrypt: true,
        trustServerCertificate: true
      }
    });

    // Se guarda la promesa para que dos peticiones al mismo tiempo no abran dos pools.
    // Si la conexión falla, se borra para intentar de nuevo en la siguiente petición.
    pools[nodo] = pool.connect().catch((error) => {
      delete pools[nodo];
      throw error;
    });
  }

  return pools[nodo];
}

module.exports = { sql, obtenerPool, nombresNodos };

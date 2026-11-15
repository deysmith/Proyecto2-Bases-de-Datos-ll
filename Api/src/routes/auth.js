const express = require('express');
const jwt = require('jsonwebtoken');
const { sql, obtenerPool, nombresNodos } = require('../db');
const { ejecutarSP, errorServidor } = require('../helpers');
const { verificarToken } = require('../seguridad');

const router = express.Router();

// Sedes donde se puede iniciar sesión
const sedes = ['SanJose', 'Limon', 'Corporativo'];

/*
  POST /api/auth/login
  Inicia sesión en la API con un usuario y contraseña.
  La contraseña se valida en la sede elegida con ValidarUsuario, que descifra la contraseña con LlaveUsuarios. 
  Como la tabla Usuarios está replicada, cada sede puede validar sola aunque el Corporativo esté caído.
  Cada sede solo acepta a sus usuarios: San José y Limón a sus administradores, y el Corporativo a los usuarios con rol Corporativo.
*/
router.post('/login', async (req, res) => {
  try {
    const { username, password, sede } = req.body;

    if (!username || !password || !sede) {
      return res.status(400).json({ ok: false, error: 'Debe indicar usuario, contraseña y sede' });
    }

    if (!sedes.includes(sede)) {
      return res.status(400).json({ ok: false, error: 'La sede debe ser SanJose, Limon o Corporativo' });
    }

    const filas = await ejecutarSP(sede, 'ValidarUsuario', [
      { nombre: 'username', tipo: sql.NVarChar(50), valor: username },
      { nombre: 'password', tipo: sql.NVarChar(100), valor: password }
    ]);

    if (filas.length === 0) {
      return res.status(401).json({ ok: false, error: 'Usuario, contraseña o sede incorrectos' });
    }

    const usuario = filas[0];

    // Datos que viajan dentro del token, sin contra
    const datos = {
      iduser: usuario.iduser,
      username: usuario.username,
      fullname: usuario.fullname,
      rol: usuario.rol,
      sucursal: usuario.sucursal,
      nodo: sede
    };

    const token = jwt.sign(datos, process.env.TOKEN_SECRETO, { expiresIn: '8h' });

    res.json({ ok: true, token, usuario: datos });
  } catch (error) {
    errorServidor(res, error);
  }
});

// GET /api/auth/yo  (devuelve los datos del usuario del token)
router.get('/yo', verificarToken, (req, res) => {
  res.json({ ok: true, usuario: req.usuario });
});

/*
  GET /api/auth/sedes
  Revisa cuáles sedes responden. Sirve para la pantalla de login y para demostrar la tolerancia a fallos.
*/
async function probarSede(sede) {
  try {
    const pool = await obtenerPool(sede);
    const peticion = pool.request();

    // Si en 5 segundos no contesta, se cancela la consulta y se da por caída
    const temporizador = setTimeout(() => peticion.cancel(), 5000);
    await peticion.query('SELECT 1 AS ok');
    clearTimeout(temporizador);

    return { sede, nombre: nombresNodos[sede], disponible: true };
  } catch (error) {
    return { sede, nombre: nombresNodos[sede], disponible: false };
  }
}

router.get('/sedes', async (req, res) => {
  // Las tres sedes se prueban al mismo tiempo, así no se suman los tiempos de espera
  const resultado = await Promise.all(sedes.map(probarSede));
  res.json({ ok: true, datos: resultado });
});

module.exports = router;

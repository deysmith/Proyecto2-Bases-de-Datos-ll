const jwt = require('jsonwebtoken');
require('dotenv').config();

/*
  Middlewares de seguridad de la API

  verificarToken: revisa que la petición traiga un token válido
    (header Authorization: Bearer <token>). El token se firma en el login con
    TOKEN_SECRETO, así que nadie lo puede alterar (por ejemplo, cambiarse el rol).
    Deja en req.usuario los datos del usuario y en req.nodo la sede a la que
    se tienen que mandar sus consultas (SanJose, Limon o Corporativo).

  permitirRoles: deja pasar solo a los roles indicados.
*/
function verificarToken(req, res, next) {
  const encabezado = req.headers.authorization || '';
  const token = encabezado.startsWith('Bearer ') ? encabezado.slice(7) : null;

  if (!token) {
    return res.status(401).json({ ok: false, error: 'Debe iniciar sesión' });
  }

  try {
    req.usuario = jwt.verify(token, process.env.TOKEN_SECRETO);
    req.nodo = req.usuario.nodo;
    next();
  } catch (error) {
    res.status(401).json({ ok: false, error: 'La sesión expiró o no es válida, inicie sesión de nuevo' });
  }
}

function permitirRoles(...roles) {
  return (req, res, next) => {
    if (!roles.includes(req.usuario.rol)) {
      return res.status(403).json({ ok: false, error: 'Su rol no tiene acceso a esta opción' });
    }
    next();
  };
}

module.exports = { verificarToken, permitirRoles };

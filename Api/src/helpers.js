const { obtenerPool, nombresNodos } = require('./db');

// Se ejecuta un procedure en el nodo indicado (SanJose, Limon, Corporativo o Productos).
// Los parámetros undefined o null no se mandan, así el SP usa su valor por defecto.
async function ejecutarSP(nodo, nombreSP, parametros = []) {
  let pool;

  try {
    pool = await obtenerPool(nodo);
  } catch (error) {
    error.nodo = nodo; // para saber cuál sede no respondió
    throw error;
  }

  const peticion = pool.request();

  for (const p of parametros) {
    if (p.valor !== undefined && p.valor !== null) {
      peticion.input(p.nombre, p.tipo, p.valor);
    }
  }

  try {
    const resultado = await peticion.execute(nombreSP);
    return resultado.recordset || [];
  } catch (error) {
    error.nodo = nodo;
    throw error;
  }
}

// Los SPs devuelven los errores como un SELECT con NumeroError
function hayError(filas) {
  return filas.length > 0 && filas[0].NumeroError !== undefined;
}

// Códigos de error de los SPs, se van agregando según los módulos
const codigosNoExiste = [50007, 50011, 50017, 50026, 50041];
const codigosDuplicado = [50001, 50002, 50003, 50018, 2627, 2601];
const codigosConflicto = [50040]; // concurrencia optimista: otro usuario modificó el producto
const codigosSinConexion = [50023, 50024]; // una sucursal no responde
const codigosProhibido = [50043]; // el cliente es de otra sucursal

function responderError(res, fila) {
  let estado = 400;
  if (codigosNoExiste.includes(fila.NumeroError)) estado = 404;
  if (codigosDuplicado.includes(fila.NumeroError)) estado = 409;
  if (codigosConflicto.includes(fila.NumeroError)) estado = 409;
  if (codigosSinConexion.includes(fila.NumeroError)) estado = 503;
  if (codigosProhibido.includes(fila.NumeroError)) estado = 403;

  res.status(estado).json({
    ok: false,
    codigo: fila.NumeroError,
    error: fila.MensajeError
  });
}

// Errores de conexión del paquete mssql: el servidor está apagado o no se alcanza
const erroresConexion = ['ESOCKET', 'ETIMEOUT', 'ECONNCLOSED', 'ENOTOPEN', 'ECONNRESET'];

function errorServidor(res, error) {
  // El nodo no responde
  if (erroresConexion.includes(error.code)) {
    const sede = nombresNodos[error.nodo] || 'de la base de datos';
    return res.status(503).json({
      ok: false,
      error: `La sede ${sede} no responde en este momento, intente más tarde`
    });
  }

  // 229 = permiso de EXECUTE denegado (la seguridad de la BD bloqueó la operación)
  if (error.number === 229) {
    return res.status(403).json({ ok: false, error: 'No tiene permiso para realizar esta operación' });
  }

  // Los THROW de los SPs (50000 en adelante) son errores de validación, no del servidor
  if (error.number >= 50000 && error.number < 60000) {
    return res.status(400).json({ ok: false, codigo: error.number, error: error.message });
  }

  console.log(error);
  res.status(500).json({ ok: false, error: error.message });
}

// Se convierte texto a entero, si no se puede devuelve undefined
function aEntero(valor) {
  const numero = parseInt(valor);
  return isNaN(numero) ? undefined : numero;
}

// Convierte texto a decimal, si no se puede devuelve undefined
function aDecimal(valor) {
  const numero = parseFloat(valor);
  return isNaN(numero) ? undefined : numero;
}

// Lee ?pagina=1&cantidad=20 y valida que sean positivos
function leerPaginacion(query) {
  let pagina = aEntero(query.pagina);
  let cantidad = aEntero(query.cantidad);

  if (pagina === undefined || pagina < 1) pagina = 1;
  if (cantidad === undefined || cantidad < 1) cantidad = 20;

  return { pagina, cantidad };
}

// Convierte el body en la lista de parámetros que espera ejecutarSP
function armarParametros(campos, body) {
  return campos.map((campo) => ({
    nombre: campo.nombre,
    tipo: campo.tipo,
    valor: body[campo.nombre]
  }));
}

// Espera unos milisegundos, para la replicación
function esperar(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

module.exports = {
  ejecutarSP, hayError, responderError, errorServidor, aEntero, aDecimal,
  leerPaginacion, armarParametros, esperar
};

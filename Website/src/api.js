import { obtenerSesion, borrarSesion } from './sesion';

// Vacío = las peticiones van al mismo servidor de Vite, que las pasa a la API (proxy en vite.config.js).
// Así la página funciona igual desde esta PC o desde otra PC por Tailscale.
const URL_BASE = import.meta.env.VITE_API_URL || '';

// Hace la petición a la API y devuelve el JSON.
// Si hay sesión, manda el token. Si algo falla, lanza un Error con un mensaje claro para mostrar al usuario.
export async function pedir(ruta, opciones = {}) {
  const sesion = obtenerSesion();
  const encabezados = { 'Content-Type': 'application/json' };

  if (sesion) {
    encabezados.Authorization = 'Bearer ' + sesion.token;
  }

  let respuesta;

  try {
    respuesta = await fetch(URL_BASE + ruta, {
      ...opciones,
      headers: encabezados
    });
  } catch (error) {
    throw new Error('No se pudo conectar con la API. Verifique que esté encendida.');
  }

  let datos = null;
  try {
    datos = await respuesta.json();
  } catch (error) {
    datos = null;
  }

  // La sesión venció o el token no sirve: se cierra la sesión y se vuelve al login
  if (respuesta.status === 401 && sesion) {
    borrarSesion();
    window.location.href = '/login';
  }

  if (!respuesta.ok || (datos && datos.ok === false)) {
    const error = new Error((datos && datos.error) || 'Ocurrió un error inesperado.');
    error.estado = respuesta.status;
    error.codigo = datos ? datos.codigo : undefined;
    throw error;
  }

  return datos;
}

// Arma el texto ?a=1&b=2 sin incluir los valores vacíos
export function armarQuery(parametros) {
  const query = new URLSearchParams();

  Object.entries(parametros).forEach(([clave, valor]) => {
    if (valor !== '' && valor !== null && valor !== undefined) {
      query.append(clave, valor);
    }
  });

  const texto = query.toString();
  return texto ? '?' + texto : '';
}

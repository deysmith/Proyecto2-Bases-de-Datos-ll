// Guarda la sesión del usuario (token y datos) en el navegador.
// Se usa try/catch porque en algunos navegadores el almacenamiento puede estar bloqueado.
const CLAVE = 'sesionWWI';

export function guardarSesion(sesion) {
  try {
    localStorage.setItem(CLAVE, JSON.stringify(sesion));
  } catch {
    // Si no se puede guardar, la sesión solo dura mientras no se recargue la página
  }
}

export function obtenerSesion() {
  try {
    const texto = localStorage.getItem(CLAVE);
    return texto ? JSON.parse(texto) : null;
  } catch {
    return null;
  }
}

export function borrarSesion() {
  try {
    localStorage.removeItem(CLAVE);
  } catch {
    // Nada que hacer
  }
}

// Nombre bonito de cada sede
export const nombresSedes = {
  SanJose: 'San José',
  Limon: 'Limón',
  Corporativo: 'Corporativo'
};

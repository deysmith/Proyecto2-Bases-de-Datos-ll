import { useState } from 'react';
import { Navigate, Route, Routes } from 'react-router-dom';
import Layout from './components/Layout';
import Login from './pages/Login';
import Clientes from './pages/Clientes';
import Proveedores from './pages/Proveedores';
import Inventario from './pages/Inventario';
import Ventas from './pages/Ventas';
import Estadisticas from './pages/Estadisticas';
import { obtenerSesion, borrarSesion } from './sesion';

function App() {
  const [sesion, setSesion] = useState(obtenerSesion());

  function cerrarSesion() {
    borrarSesion();
    setSesion(null);
  }

  // Sin sesión: solo existe la página de login
  if (!sesion) {
    return (
      <Routes>
        <Route path="/login" element={<Login alIniciarSesion={setSesion} />} />
        <Route path="*" element={<Navigate to="/login" replace />} />
      </Routes>
    );
  }

  const usuario = sesion.usuario;
  const esAdmin = usuario.rol === 'Administrador';
  const inicio = esAdmin ? '/clientes' : '/estadisticas';

  return (
    <Layout usuario={usuario} alCerrarSesion={cerrarSesion}>
      <Routes>
        {/* Administrador de sucursal: consulta su sucursal y administra productos */}
        {esAdmin && (
          <>
            <Route path="/clientes" element={<Clientes />} />
            <Route path="/proveedores" element={<Proveedores />} />
            <Route path="/productos" element={<Inventario usuario={usuario} />} />
            <Route path="/ventas" element={<Ventas />} />
          </>
        )}

        {/* Corporativo: solo estadísticas */}
        {!esAdmin && <Route path="/estadisticas" element={<Estadisticas />} />}

        <Route path="*" element={<Navigate to={inicio} replace />} />
      </Routes>
    </Layout>
  );
}

export default App;

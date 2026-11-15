import { useEffect, useState } from 'react';
import {
  Alert, Box, Button, Chip, CircularProgress, Paper, Tab, Tabs,
  ToggleButton, ToggleButtonGroup, Typography
} from '@mui/material';
import SyncIcon from '@mui/icons-material/Sync';
import EncabezadoPagina from '../components/EncabezadoPagina';
import ReporteGenerico from '../components/ReporteGenerico';
import Aviso from '../components/Aviso';
import { reportes } from '../reportes';
import { pedir } from '../api';
import { entero } from '../formato';
import { nombresSedes } from '../sesion';

// Fecha y hora del último corte, por ejemplo 13/11/2026 15:40:05
function fechaHora(valor) {
  if (!valor) return 'Nunca';
  return new Date(valor).toLocaleString('es-CR');
}

function Estadisticas() {
  const [indice, setIndice] = useState(0);
  const [sucursal, setSucursal] = useState(''); // '' = consolidado
  const reporte = reportes[indice];

  // Estado de la "vista materializada" (tablas de resumen del Corporativo)
  const [estado, setEstado] = useState([]);
  const [actualizando, setActualizando] = useState(false);
  const [corte, setCorte] = useState(0);
  const [aviso, setAviso] = useState(null);

  // Al abrir la página se consulta cuándo fue el último corte de cada sucursal
  useEffect(() => {
    async function cargarEstado() {
      try {
        const respuesta = await pedir('/api/reportes/estado-resumen');
        setEstado(respuesta.datos);
      } catch (e) {
        setAviso({ tipo: 'error', texto: 'No se pudo consultar el estado del resumen. ' + e.message });
      }
    }
    cargarEstado();
  }, []);

  // Trae las facturas nuevas de las sucursales sin esperar al job de 30 minutos
  async function actualizarAhora() {
    setActualizando(true);
    try {
      const respuesta = await pedir('/api/reportes/actualizar-resumen', { method: 'POST' });
      setEstado(respuesta.datos);
      setCorte((valor) => valor + 1); // los reportes se vuelven a consultar

      const caidas = respuesta.datos.filter((fila) => fila.Estado !== 'Actualizado');
      if (caidas.length > 0) {
        setAviso({
          tipo: 'warning',
          texto: 'Resumen actualizado, pero ' + caidas.map((fila) => nombresSedes[fila.Sucursal]).join(' y ') +
            ' no respondió: se mantienen sus datos del último corte.'
        });
      } else {
        setAviso({ tipo: 'success', texto: 'Resumen actualizado con los datos de las dos sucursales.' });
      }
    } catch (e) {
      setAviso({ tipo: 'error', texto: e.message });
    } finally {
      setActualizando(false);
    }
  }

  return (
    <>
      <EncabezadoPagina
        titulo="Estadísticas"
        subtitulo="Reportes de compras, ventas e inventario de las dos sucursales, por sucursal o consolidados."
        accion={
          <Button
            variant="outlined"
            startIcon={actualizando ? <CircularProgress size={18} /> : <SyncIcon />}
            disabled={actualizando}
            onClick={actualizarAhora}
          >
            {actualizando ? 'Actualizando...' : 'Actualizar ahora'}
          </Button>
        }
      />

      {/* Último corte de cada sucursal */}
      <Paper sx={{ p: 2, mb: 3 }}>
        <Typography variant="subtitle2" fontWeight={700} sx={{ mb: 1 }}>
          Datos de las sucursales (se actualizan solos cada 30 minutos)
        </Typography>
        <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', sm: '1fr 1fr' }, gap: 2 }}>
          {estado.map((fila) => (
            <Box
              key={fila.Sucursal}
              sx={{ border: 1, borderColor: 'divider', borderRadius: 2, p: 1.5 }}
            >
              <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 1, mb: 0.5 }}>
                <Typography fontWeight={600}>{nombresSedes[fila.Sucursal] || fila.Sucursal}</Typography>
                <Chip
                  size="small"
                  color={fila.Estado === 'Actualizado' ? 'success' : 'warning'}
                  label={fila.Estado === 'Actualizado' ? 'Actualizado' : 'Sin conexión'}
                />
              </Box>
              <Typography variant="body2" color="text.secondary">
                Datos al: {fechaHora(fila.UltimaActualizacion)} · {entero(fila.Facturas)} facturas
              </Typography>
              {fila.Estado !== 'Actualizado' && (
                <Typography variant="body2" color="warning.main">{fila.Estado}</Typography>
              )}
            </Box>
          ))}
        </Box>
      </Paper>

      <Paper sx={{ mb: 3 }}>
        <Tabs
          value={indice}
          onChange={(evento, nuevoIndice) => setIndice(nuevoIndice)}
          variant="scrollable"
          scrollButtons="auto"
          allowScrollButtonsMobile
          aria-label="Reportes"
        >
          {reportes.map((item, posicion) => (
            <Tab key={item.id} label={`${posicion + 1}. ${item.titulo}`} />
          ))}
        </Tabs>
      </Paper>

      <Box
        sx={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          flexWrap: 'wrap',
          gap: 2,
          mb: 1
        }}
      >
        <Typography variant="h5" component="h2">
          {reporte.titulo}
        </Typography>

        {/* Filtro por sucursal o consolidado (solo reportes de ventas) */}
        {reporte.porSucursal && (
          <ToggleButtonGroup
            exclusive
            size="small"
            color="primary"
            value={sucursal}
            onChange={(evento, valor) => valor !== null && setSucursal(valor)}
            aria-label="Sucursal"
          >
            <ToggleButton value="">Consolidado</ToggleButton>
            <ToggleButton value="SanJose">San José</ToggleButton>
            <ToggleButton value="Limon">Limón</ToggleButton>
          </ToggleButtonGroup>
        )}
      </Box>

      {!reporte.porSucursal && (
        <Alert severity="info" sx={{ mb: 2 }}>
          Las compras a proveedores están centralizadas en el Corporativo, por eso este reporte siempre es consolidado.
        </Alert>
      )}

      {/* El key hace que cada reporte empiece con sus filtros limpios */}
      <ReporteGenerico key={reporte.id} reporte={reporte} sucursal={sucursal} corte={corte} />

      <Aviso aviso={aviso} alCerrar={() => setAviso(null)} />
    </>
  );
}

export default Estadisticas;

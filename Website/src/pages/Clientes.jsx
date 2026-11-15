import { useSearchParams } from 'react-router-dom';
import { useEffect, useState } from 'react';
import {
  Alert, Box, Button, Chip, CircularProgress, Dialog, DialogActions, DialogContent,
  DialogTitle, MenuItem, Paper, TextField, Typography
} from '@mui/material';
import SearchIcon from '@mui/icons-material/Search';
import RestartAltIcon from '@mui/icons-material/RestartAlt';
import { pedir, armarQuery } from '../api';
import { obtenerSesion, nombresSedes } from '../sesion';
import EncabezadoPagina from '../components/EncabezadoPagina';
import TablaDatos from '../components/TablaDatos';
import Paginacion from '../components/Paginacion';
import Aviso from '../components/Aviso';
import CampoDetalle from '../components/CampoDetalle';
import Mapa from '../components/Mapa';

const filtrosVacios = { nombre: '', categoriaId: '', metodoEntregaId: '' };

// El catálogo de clientes es el mismo en las dos sucursales, pero cada cliente
// pertenece a una sola (y solo ahí tiene sus facturas). Se marca con un chip.
function chipSucursal(valor) {
  const miSucursal = obtenerSesion()?.usuario.sucursal;
  if (!valor) return '—';

  return valor === miSucursal ? (
    <Chip size="small" color="secondary" label="Esta sucursal" />
  ) : (
    <Chip size="small" variant="outlined" label={nombresSedes[valor] || valor} />
  );
}

const columnas = [
  { campo: 'CustomerName', titulo: 'Cliente' },
  { campo: 'CustomerCategoryName', titulo: 'Categoría' },
  { campo: 'DeliveryMethodName', titulo: 'Método de entrega' },
  { campo: 'Sucursal', titulo: 'Sucursal', formato: chipSucursal }
];

function Clientes() {
  // Filtros: "filtros" es lo que el usuario escribe, "filtrosAplicados" es lo que se consultó
  const [filtros, setFiltros] = useState(filtrosVacios);
  const [filtrosAplicados, setFiltrosAplicados] = useState(filtrosVacios);
  const [categorias, setCategorias] = useState([]);
  const [metodos, setMetodos] = useState([]);

  // Tabla
  const [filas, setFilas] = useState([]);
  const [pagina, setPagina] = useState(1);
  const [cantidad, setCantidad] = useState(20);
  const [cargando, setCargando] = useState(true);
  const [error, setError] = useState('');
  const [recarga, setRecarga] = useState(0);

  // Ventana de detalle
  const [detalleAbierto, setDetalleAbierto] = useState(false);
  const [detalle, setDetalle] = useState(null);

  // Aviso general
  const [aviso, setAviso] = useState(null);

  // Mantener los filtros en la URL para que se puedan compartir
  const [parametros, setParametros] = useSearchParams();

  // Opciones de los filtros (se cargan una sola vez)
  useEffect(() => {
    async function cargarOpciones() {
      try {
        const [resCategorias, resMetodos] = await Promise.all([
          pedir('/api/clientes/categorias'),
          pedir('/api/clientes/metodos-entrega')
        ]);
        setCategorias(resCategorias.datos);
        setMetodos(resMetodos.datos);
      } catch (e) {
        setAviso({ tipo: 'error', texto: 'No se pudieron cargar los filtros. ' + e.message });
      }
    }
    cargarOpciones();
  }, []);

  // Lista de clientes: se vuelve a consultar cuando cambian los filtros o la página
  useEffect(() => {
    async function cargarClientes() {
      setCargando(true);
      setError('');

      try {
        const query = armarQuery({
          criterio: filtrosAplicados.nombre.trim(),
          categoriaId: filtrosAplicados.categoriaId,
          metodoEntregaId: filtrosAplicados.metodoEntregaId,
          pagina,
          cantidad
        });
        const respuesta = await pedir('/api/clientes/buscar' + query);
        setFilas(respuesta.datos);
      } catch (e) {
        setError(e.message);
        setFilas([]);
      } finally {
        setCargando(false);
      }
    }
    cargarClientes();
  }, [filtrosAplicados, pagina, cantidad, recarga]);

  // Si se llega desde un enlace (/clientes?id=1) se abre directamente el detalle de ese cliente
  useEffect(() => {
    const id = parametros.get('id');
    if (id) {
      abrirDetalle({ CustomerID: id });
      setParametros({}, { replace: true });
    }
  }, []);

  function aplicarFiltros() {
    setFiltrosAplicados(filtros);
    setPagina(1);
  }

  function restaurarFiltros() {
    setFiltros(filtrosVacios);
    setFiltrosAplicados(filtrosVacios);
    setPagina(1);
  }

  function cambiarFiltro(campo, valor) {
    setFiltros({ ...filtros, [campo]: valor });
  }

  async function abrirDetalle(fila) {
    setDetalle(null);
    setDetalleAbierto(true);

    try {
      const respuesta = await pedir('/api/clientes/' + fila.CustomerID);
      setDetalle(respuesta.datos);
    } catch (e) {
      setDetalleAbierto(false);
      setAviso({ tipo: 'error', texto: e.message });
    }
  }

  const punto = detalle?.DeliveryLocation?.points?.[0];

  return (
    <>
      <EncabezadoPagina
        titulo="Clientes"
        subtitulo="Consulte el catálogo de clientes, filtre los resultados y vea el detalle de cada uno. Las facturas de cada cliente están en la sucursal a la que pertenece."
      />

      <Paper sx={{ p: 2, mb: 3 }}>
        <Box
          component="form"
          onSubmit={(evento) => {
            evento.preventDefault();
            aplicarFiltros();
          }}
          sx={{
            display: 'grid',
            gridTemplateColumns: { xs: '1fr', md: '2fr 1fr 1fr' },
            gap: 2
          }}
        >
          <TextField
            label="Nombre del cliente"
            placeholder="Escriba parte del nombre"
            size="small"
            value={filtros.nombre}
            onChange={(evento) => cambiarFiltro('nombre', evento.target.value)}
            slotProps={{ htmlInput: { maxLength: 100 } }}
          />

          <TextField
            select
            label="Categoría"
            size="small"
            value={filtros.categoriaId}
            onChange={(evento) => cambiarFiltro('categoriaId', evento.target.value)}
            slotProps={{ inputLabel: { shrink: true }, select: { displayEmpty: true } }}
          >
            <MenuItem value="">Todas</MenuItem>
            {categorias.map((categoria) => (
              <MenuItem key={categoria.CustomerCategoryID} value={categoria.CustomerCategoryID}>
                {categoria.CustomerCategoryName}
              </MenuItem>
            ))}
          </TextField>

          <TextField
            select
            label="Método de entrega"
            size="small"
            value={filtros.metodoEntregaId}
            onChange={(evento) => cambiarFiltro('metodoEntregaId', evento.target.value)}
            slotProps={{ inputLabel: { shrink: true }, select: { displayEmpty: true } }}
          >
            <MenuItem value="">Todos</MenuItem>
            {metodos.map((metodo) => (
              <MenuItem key={metodo.DeliveryMethodID} value={metodo.DeliveryMethodID}>
                {metodo.DeliveryMethodName}
              </MenuItem>
            ))}
          </TextField>

          <Box
            sx={{
              display: 'flex',
              gap: 1,
              flexWrap: 'wrap',
              gridColumn: { md: '1 / -1' },
              justifyContent: { md: 'flex-end' }
            }}
          >
            <Button type="submit" variant="contained" startIcon={<SearchIcon />}>
              Buscar
            </Button>
            <Button variant="outlined" startIcon={<RestartAltIcon />} onClick={restaurarFiltros}>
              Restaurar filtros
            </Button>
          </Box>
        </Box>
      </Paper>

      {error && (
        <Alert
          severity="error"
          sx={{ mb: 2 }}
          action={
            <Button color="inherit" size="small" onClick={() => setRecarga((valor) => valor + 1)}>
              Reintentar
            </Button>
          }
        >
          {error}
        </Alert>
      )}

      <TablaDatos
        columnas={columnas}
        filas={filas}
        cargando={cargando}
        claveFila="CustomerID"
        alSeleccionar={abrirDetalle}
      />

      <Paginacion
        pagina={pagina}
        cantidad={cantidad}
        cantidadFilas={filas.length}
        alCambiarPagina={setPagina}
        alCambiarCantidad={(nuevaCantidad) => {
          setCantidad(nuevaCantidad);
          setPagina(1);
        }}
      />

      {/* Ventana con el detalle del cliente */}
      <Dialog
        open={detalleAbierto}
        onClose={() => setDetalleAbierto(false)}
        fullWidth
        maxWidth="md"
      >
        <DialogTitle>{detalle ? detalle.CustomerName : 'Detalle del cliente'}</DialogTitle>

        <DialogContent dividers>
          {!detalle ? (
            <Box sx={{ textAlign: 'center', py: 4 }}>
              <CircularProgress />
            </Box>
          ) : (
            <>
              {/* Si el Corporativo no responde, los datos sensibles no se pueden mostrar */}
              {detalle.DatosSensibles !== 'Disponible' && (
                <Alert severity="warning" sx={{ mb: 2 }}>
                  {detalle.DatosSensibles}. Los datos de contacto, dirección y ubicación se guardan en
                  el Corporativo, por eso solo se muestran los datos que tiene esta sucursal.
                </Alert>
              )}

              <Box
                sx={{
                  display: 'grid',
                  gridTemplateColumns: { xs: '1fr', sm: '1fr 1fr' },
                  gap: 2,
                  mb: 2
                }}
              >
                <CampoDetalle titulo="Nombre del cliente" valor={detalle.CustomerName} />
                <CampoDetalle titulo="Sucursal" valor={nombresSedes[detalle.Sucursal] || detalle.Sucursal} />
                <CampoDetalle titulo="Categoría" valor={detalle.CustomerCategoryName} />
                <CampoDetalle titulo="Grupo de compra" valor={detalle.BuyingGroupName} />
                <CampoDetalle titulo="Cliente por facturar" valor={detalle.BillToCustomer} />
                <CampoDetalle titulo="Contacto primario" valor={detalle.PrimaryContact} />
                <CampoDetalle titulo="Contacto alternativo" valor={detalle.AlternativeContact} />
                <CampoDetalle titulo="Método de entrega" valor={detalle.DeliveryMethodName} />
                <CampoDetalle titulo="Ciudad de entrega" valor={detalle.CityName} />
                <CampoDetalle titulo="Código postal" valor={detalle.DeliveryPostalCode} />
                <CampoDetalle titulo="Días de gracia para pagar" valor={detalle.PaymentDays} />
                <CampoDetalle titulo="Teléfono" valor={detalle.PhoneNumber} />
                <CampoDetalle titulo="Fax" valor={detalle.FaxNumber} />
                <CampoDetalle titulo="Sitio web" valor={detalle.WebsiteURL} enlace />
              </Box>

              <CampoDetalle titulo="Dirección" valor={detalle.Address} />

              <Typography variant="subtitle1" fontWeight={600} sx={{ mt: 3, mb: 1 }}>
                Ubicación de entrega
              </Typography>
              <Mapa latitud={punto?.lat} longitud={punto?.lng} texto={detalle.CustomerName} />
            </>
          )}
        </DialogContent>

        <DialogActions sx={{ px: 3, py: 2 }}>
          <Box sx={{ flexGrow: 1 }} />
          <Button variant="contained" onClick={() => setDetalleAbierto(false)}>
            Cerrar
          </Button>
        </DialogActions>
      </Dialog>

      <Aviso aviso={aviso} alCerrar={() => setAviso(null)} />
    </>
  );
}

export default Clientes;
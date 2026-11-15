import { useEffect, useState } from 'react';
import {
  Alert, Box, Button, Chip, CircularProgress, IconButton, InputAdornment,
  Paper, TextField, ToggleButton, ToggleButtonGroup, Tooltip, Typography
} from '@mui/material';
import LoginIcon from '@mui/icons-material/Login';
import RefreshIcon from '@mui/icons-material/Refresh';
import Visibility from '@mui/icons-material/Visibility';
import VisibilityOff from '@mui/icons-material/VisibilityOff';
import { pedir } from '../api';
import { guardarSesion, nombresSedes } from '../sesion';

const sedes = [
  { valor: 'SanJose', texto: 'San José', detalle: 'Sucursal · Windows' },
  { valor: 'Limon', texto: 'Limón', detalle: 'Sucursal · Red Hat' },
  { valor: 'Corporativo', texto: 'Corporativo', detalle: 'Plaza Roble · Ubuntu' }
];

function Login({ alIniciarSesion }) {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [sede, setSede] = useState('SanJose');
  const [verClave, setVerClave] = useState(false);
  const [errores, setErrores] = useState({});
  const [errorApi, setErrorApi] = useState('');
  const [entrando, setEntrando] = useState(false);

  // Estado de las sedes: { SanJose: true, Limon: false, ... }  (null = revisando)
  const [estadoSedes, setEstadoSedes] = useState(null);
  const [revision, setRevision] = useState(0);

  // Pregunta a la API cuáles sedes responden (cada vez que cambia "revision")
  useEffect(() => {
    async function revisarSedes() {
      try {
        const respuesta = await pedir('/api/auth/sedes');
        const estado = {};
        respuesta.datos.forEach((fila) => {
          estado[fila.sede] = fila.disponible;
        });
        setEstadoSedes(estado);
      } catch (e) {
        setEstadoSedes({});
        setErrorApi(e.message);
      }
    }
    revisarSedes();
  }, [revision]);

  function volverARevisar() {
    setEstadoSedes(null);
    setErrorApi('');
    setRevision((valor) => valor + 1);
  }

  async function entrar(evento) {
    evento.preventDefault();

    const nuevosErrores = {};
    if (!username.trim()) nuevosErrores.username = 'Ingrese su usuario.';
    if (!password) nuevosErrores.password = 'Ingrese su contraseña.';
    setErrores(nuevosErrores);
    setErrorApi('');
    if (Object.keys(nuevosErrores).length > 0) return;

    setEntrando(true);
    try {
      const respuesta = await pedir('/api/auth/login', {
        method: 'POST',
        body: JSON.stringify({ username: username.trim(), password, sede })
      });

      const sesion = { token: respuesta.token, usuario: respuesta.usuario };
      guardarSesion(sesion);
      alIniciarSesion(sesion);
    } catch (e) {
      setErrorApi(e.message);
    } finally {
      setEntrando(false);
    }
  }

  // Chip verde o rojo según si la sede responde
  function chipEstado(valor) {
    if (estadoSedes === null) {
      return <Chip size="small" label="Revisando..." variant="outlined" />;
    }
    return estadoSedes[valor] ? (
      <Chip size="small" color="success" label="En línea" />
    ) : (
      <Chip size="small" color="error" label="Sin conexión" />
    );
  }

  return (
    <Box
      sx={{
        minHeight: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        p: 2,
        background: 'linear-gradient(135deg, #1F4E79 0%, #00796B 100%)'
      }}
    >
      <Paper
        component="form"
        noValidate
        onSubmit={entrar}
        elevation={6}
        sx={{ width: '100%', maxWidth: 460, p: { xs: 3, sm: 4 } }}
      >
        <Typography variant="h5" fontWeight={700} color="primary">
          Wide World Importers
        </Typography>
        <Typography color="text.secondary" sx={{ mb: 3 }}>
          Sistema distribuido · Inicie sesión en su sede
        </Typography>

        {errorApi && <Alert severity="error" sx={{ mb: 2 }}>{errorApi}</Alert>}

        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 1 }}>
          <Typography variant="subtitle2" fontWeight={700}>Sede</Typography>
          <Tooltip title="Volver a revisar las sedes">
            <IconButton size="small" onClick={volverARevisar} aria-label="Revisar sedes">
              <RefreshIcon fontSize="small" />
            </IconButton>
          </Tooltip>
        </Box>

        <ToggleButtonGroup
          exclusive
          orientation="vertical"
          fullWidth
          value={sede}
          onChange={(evento, valor) => valor && setSede(valor)}
          sx={{ mb: 3 }}
        >
          {sedes.map((item) => (
            <ToggleButton
              key={item.valor}
              value={item.valor}
              sx={{ justifyContent: 'space-between', textTransform: 'none', py: 1.2 }}
            >
              <Box sx={{ textAlign: 'left' }}>
                <Typography fontWeight={600}>{item.texto}</Typography>
                <Typography variant="caption" color="text.secondary">{item.detalle}</Typography>
              </Box>
              {chipEstado(item.valor)}
            </ToggleButton>
          ))}
        </ToggleButtonGroup>

        <TextField
          label="Usuario"
          fullWidth
          size="small"
          autoComplete="username"
          value={username}
          onChange={(evento) => setUsername(evento.target.value)}
          error={Boolean(errores.username)}
          helperText={errores.username || ' '}
          slotProps={{ htmlInput: { maxLength: 50 } }}
        />

        <TextField
          label="Contraseña"
          fullWidth
          size="small"
          type={verClave ? 'text' : 'password'}
          autoComplete="current-password"
          value={password}
          onChange={(evento) => setPassword(evento.target.value)}
          error={Boolean(errores.password)}
          helperText={errores.password || ' '}
          slotProps={{
            htmlInput: { maxLength: 100 },
            input: {
              endAdornment: (
                <InputAdornment position="end">
                  <IconButton
                    size="small"
                    onClick={() => setVerClave(!verClave)}
                    aria-label={verClave ? 'Ocultar contraseña' : 'Mostrar contraseña'}
                  >
                    {verClave ? <VisibilityOff fontSize="small" /> : <Visibility fontSize="small" />}
                  </IconButton>
                </InputAdornment>
              )
            }
          }}
        />

        <Button
          type="submit"
          variant="contained"
          fullWidth
          size="large"
          disabled={entrando}
          startIcon={entrando ? <CircularProgress size={18} color="inherit" /> : <LoginIcon />}
          sx={{ mt: 1 }}
        >
          {entrando ? 'Entrando...' : `Entrar a ${nombresSedes[sede]}`}
        </Button>
      </Paper>
    </Box>
  );
}

export default Login;

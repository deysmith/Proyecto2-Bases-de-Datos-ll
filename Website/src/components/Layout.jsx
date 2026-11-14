import { useState } from 'react';
import { NavLink, useLocation } from 'react-router-dom';
import {
  AppBar, Box, Button, Chip, Divider, Drawer, IconButton, List, ListItemButton,
  ListItemIcon, ListItemText, Toolbar, Typography
} from '@mui/material';
import LogoutIcon from '@mui/icons-material/Logout';
import StorefrontIcon from '@mui/icons-material/Storefront';
import { nombresSedes } from '../sesion';
import MenuIcon from '@mui/icons-material/Menu';
import PeopleIcon from '@mui/icons-material/People';
import LocalShippingIcon from '@mui/icons-material/LocalShipping';
import Inventory2Icon from '@mui/icons-material/Inventory2';
import ReceiptLongIcon from '@mui/icons-material/ReceiptLong';
import BarChartIcon from '@mui/icons-material/BarChart';

const anchoMenu = 240;

// Cada opción del menú indica qué rol la puede ver
const opciones = [
  { texto: 'Clientes', ruta: '/clientes', icono: <PeopleIcon />, rol: 'Administrador' },
  { texto: 'Proveedores', ruta: '/proveedores', icono: <LocalShippingIcon />, rol: 'Administrador' },
  { texto: 'Inventario', ruta: '/productos', icono: <Inventory2Icon />, rol: 'Administrador' },
  { texto: 'Ventas', ruta: '/ventas', icono: <ReceiptLongIcon />, rol: 'Administrador' },
  { texto: 'Estadísticas', ruta: '/estadisticas', icono: <BarChartIcon />, rol: 'Corporativo' }
];

function Layout({ usuario, alCerrarSesion, children }) {
  const [menuAbierto, setMenuAbierto] = useState(false);
  const ubicacion = useLocation();

  const opcionesUsuario = opciones.filter((opcion) => opcion.rol === usuario.rol);
  const sede = nombresSedes[usuario.nodo];

  const menu = (
    <Box>
      <Toolbar />
      {/* Datos del usuario y su sede */}
      <Box sx={{ px: 2, py: 2 }}>
        <Typography fontWeight={700} noWrap>{usuario.fullname}</Typography>
        <Typography variant="body2" color="text.secondary" noWrap sx={{ mb: 1 }}>
          {usuario.username} · {usuario.rol}
        </Typography>
        <Chip
          icon={<StorefrontIcon />}
          label={usuario.rol === 'Administrador' ? 'Sucursal ' + sede : 'Oficina Corporativa'}
          color="secondary"
          size="small"
        />
      </Box>
      <Divider />
      <List>
        {opcionesUsuario.map((opcion) => (
          <ListItemButton
            key={opcion.ruta}
            component={NavLink}
            to={opcion.ruta}
            selected={ubicacion.pathname.startsWith(opcion.ruta)}
            onClick={() => setMenuAbierto(false)}
          >
            <ListItemIcon>{opcion.icono}</ListItemIcon>
            <ListItemText primary={opcion.texto} />
          </ListItemButton>
        ))}
      </List>
    </Box>
  );

  return (
    <Box sx={{ display: 'flex' }}>
      <AppBar position="fixed" sx={{ zIndex: (tema) => tema.zIndex.drawer + 1 }}>
        <Toolbar>
          <IconButton
            color="inherit"
            aria-label="Abrir menú"
            edge="start"
            onClick={() => setMenuAbierto(true)}
            sx={{ mr: 2, display: { md: 'none' } }}
          >
            <MenuIcon />
          </IconButton>
          <Typography variant="h6" component="div" fontWeight={700} sx={{ flexGrow: 1 }} noWrap>
            Wide World Importers
            <Box component="span" sx={{ fontWeight: 400, display: { xs: 'none', sm: 'inline' } }}>
              {' · '}{sede}
            </Box>
          </Typography>
          <Button color="inherit" startIcon={<LogoutIcon />} onClick={alCerrarSesion}>
            Salir
          </Button>
        </Toolbar>
      </AppBar>

      {/* Menú fijo en pantallas grandes */}
      <Drawer
        variant="permanent"
        sx={{
          width: anchoMenu,
          flexShrink: 0,
          display: { xs: 'none', md: 'block' },
          '& .MuiDrawer-paper': { width: anchoMenu, boxSizing: 'border-box' }
        }}
      >
        {menu}
      </Drawer>

      {/* Menú desplegable en celulares */}
      <Drawer
        variant="temporary"
        open={menuAbierto}
        onClose={() => setMenuAbierto(false)}
        ModalProps={{ keepMounted: true }}
        sx={{
          display: { xs: 'block', md: 'none' },
          '& .MuiDrawer-paper': { width: anchoMenu, boxSizing: 'border-box' }
        }}
      >
        {menu}
      </Drawer>

      <Box component="main" sx={{ flexGrow: 1, p: { xs: 2, md: 3 }, minWidth: 0 }}>
        <Toolbar />
        {children}
      </Box>
    </Box>
  );
}

export default Layout;
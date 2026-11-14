import { createTheme } from '@mui/material/styles';

const tema = createTheme({
  palette: {
    primary: { main: '#1F4E79' },
    secondary: { main: '#00796B' },
    background: { default: '#F4F6F8', paper: '#FFFFFF' }
  },
  shape: { borderRadius: 8 },
  typography: {
    fontFamily: 'Roboto, Arial, sans-serif',
    h4: { fontWeight: 600, fontSize: '1.9rem' }
  },
  components: {
    MuiButton: {
      defaultProps: { disableElevation: true },
      styleOverrides: { root: { textTransform: 'none', fontWeight: 600 } }
    }
  }
});

export default tema;
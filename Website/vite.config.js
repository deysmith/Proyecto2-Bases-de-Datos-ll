import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'

export default defineConfig({
  plugins: [react()],
  server: {
    // El host permite que la app sea accesible desde otras PCs de la red local, no solo desde localhost.
    host: true,
    port: 5173,
    // Todo lo que empiece con /api se pasa a la API, que corre en esta misma PC.
    // Así solo hay que abrir el puerto 5173 y la API (3000) nunca queda expuesta.
    proxy: {
      '/api': 'http://localhost:3000'
    }
  }
})

import path from 'node:path';
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  server: {
    port: 1421,
    host: '127.0.0.1',
    strictPort: true,
  },
  plugins: [react()],
  build: {
    minify: 'esbuild',
    sourcemap: false,
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
});

import path from 'path';
import { createReadStream, readFileSync } from 'node:fs';
import { defineConfig, loadEnv } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, '.', '');
  const antdCssPath = path.resolve(__dirname, 'node_modules/antd/dist/antd.css');
  return {
    server: {
      port: 3000,
      host: '0.0.0.0',
      strictPort: true,
      proxy: {
        '/api': {
          target: env.URGS_API_URL || 'http://localhost:8080',
          changeOrigin: true,
        },
        '/uploads': {
          target: env.URGS_API_URL || 'http://localhost:8080',
          changeOrigin: true,
        },
        '/profile': {
          target: env.URGS_API_URL || 'http://localhost:8080',
          changeOrigin: true,
        },
      },
    },
    plugins: [
      react(),
      {
        name: 'antd-static-css',
        configureServer(server) {
          server.middlewares.use('/antd.css', (request, response, next) => {
            if (request.url?.split('?')[0] !== '/') {
              next();
              return;
            }
            response.setHeader('Content-Type', 'text/css; charset=utf-8');
            createReadStream(antdCssPath).pipe(response);
          });
        },
        generateBundle() {
          this.emitFile({
            type: 'asset',
            fileName: 'antd.css',
            source: readFileSync(antdCssPath),
          });
        },
      },
    ],
    esbuild: {
      drop: mode === 'production' ? ['console', 'debugger'] : [],
    },
    build: {
      minify: 'esbuild',
      sourcemap: false,
    },
    define: {
      'process.env.API_KEY': JSON.stringify(env.GEMINI_API_KEY),
      'process.env.GEMINI_API_KEY': JSON.stringify(env.GEMINI_API_KEY)
    },
    resolve: {
      alias: {
        '@': path.resolve(__dirname, './src'),
      }
    }
  };
});

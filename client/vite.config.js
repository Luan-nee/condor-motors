import react from '@vitejs/plugin-react-swc';
import { defineConfig, loadEnv } from 'vite';

// https://vite.dev/config/
export default ({ mode }) => {
  // eslint-disable-next-line no-undef
  const env = loadEnv(mode, process.cwd());

  const PORT = `${env.VITE_PORT ?? '3000'}`;

  return defineConfig({
    plugins: [react()],
    build: {
      outDir: '../server/client-build',
      emptyOutDir: true,
    },
    server: {
      port: parseInt(PORT),
    },
  });
};

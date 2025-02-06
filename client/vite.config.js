import react from '@vitejs/plugin-react-swc';
import { defineConfig, loadEnv } from 'vite';

// https://vite.dev/config/
export default ({ mode }) => {
  process.env = { ...process.env, ...loadEnv(mode, process.cwd()) };

  return defineConfig({
    plugins: [react()],
    build: {
      outDir: '../server/client-build',
      emptyOutDir: true,
    },
    server: {
      port: parseInt(process.env.VITE_PORT),
    },
  });
};

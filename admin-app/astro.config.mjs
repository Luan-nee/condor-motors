// @ts-check
import { defineConfig, envField } from 'astro/config';
import tailwindcss from '@tailwindcss/vite';

// https://astro.build/config
export default defineConfig({
  vite: {
    plugins: [tailwindcss()],
  },
  env: {
    schema: {
      API_URL: envField.string({
        context: 'client',
        access: 'public',
        optional: false,
      }),
      PORT: envField.number({
        context: 'server',
        access: 'public',
        default: 4321,
      }),
    },
  },
});

// @ts-check
import { defineConfig, envField } from 'astro/config';
import tailwindcss from '@tailwindcss/vite';
import solidJs from '@astrojs/solid-js';

// https://astro.build/config
export default defineConfig({
  integrations: [solidJs()],
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

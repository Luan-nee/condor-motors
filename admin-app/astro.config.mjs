// @ts-check
import { loadEnv } from 'vite';
import { defineConfig } from 'astro/config';
import tailwindcss from '@tailwindcss/vite';
import solidJs from '@astrojs/solid-js';

// https://astro.build/config
export default defineConfig({
  integrations: [solidJs()],
  vite: {
    plugins: [tailwindcss()],
  },
  base: get('BASE_URL'),
  outDir: get('OUT_DIR'),
  server: {
    port: Number(get('PORT', 4321)),
  },
});

/**
 * @param {string} name
 * @param {any} defaultValue
 */
function get(name, defaultValue = '') {
  const val =
    loadEnv(process.env.NODE_ENV ?? 'development', process.cwd(), '')[name] ??
    defaultValue;

  if (val === '') {
    return;
  }

  return val;
}

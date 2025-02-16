import { defineConfig } from 'drizzle-kit'
import { envs } from './src/config/envs'

const { DATABASE_URL: databaseUrl } = envs

export default defineConfig({
  out: './drizzle',
  schema: './src/db/schema.ts',
  dialect: 'postgresql',
  dbCredentials: {
    url: databaseUrl
  }
})

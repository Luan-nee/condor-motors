import { envs } from '@/config/envs'
import { isProduction } from '@/consts'
import * as schema from '@db/schema'
import { drizzle } from 'drizzle-orm/node-postgres'
import { Pool, type PoolConfig } from 'pg'

const { DATABASE_URL: databaseUrl } = envs

const dbConfig: PoolConfig = {
  connectionString: databaseUrl,
  ssl: isProduction,
  max: 5,
  idleTimeoutMillis: 30000
}

const pool = new Pool(dbConfig)

export const db = drizzle({
  client: pool,
  logger: !isProduction,
  schema
})

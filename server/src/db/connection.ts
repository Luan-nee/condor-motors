import { envs } from '@/config/envs'
import { databaseEnableSSL, isProduction } from '@/consts'
import * as schema from '@db/schema'
import { drizzle } from 'drizzle-orm/node-postgres'
import { Pool, type PoolConfig } from 'pg'

const { DATABASE_URL: databaseUrl } = envs

const dbConfig: PoolConfig = {
  connectionString: databaseUrl,
  ssl: databaseEnableSSL,
  max: 5,
  idleTimeoutMillis: 30000
}

const pool = new Pool(dbConfig)

export const db = drizzle({
  client: pool,
  logger: !isProduction,
  schema
})

export const testDatabaseConnection = async () => {
  await pool.query('SELECT 1')
  // eslint-disable-next-line no-console
  console.log('Connected to the database')
}

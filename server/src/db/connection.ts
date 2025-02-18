import { envs } from '@/config/envs'
import * as schema from '@db/schema'
import { drizzle } from 'drizzle-orm/node-postgres'
import { Pool, type PoolConfig } from 'pg'

const { DATABASE_URL: databaseUrl, NODE_ENV: nodeEnv } = envs

const isProduction = nodeEnv === 'production'

const dbConfig: PoolConfig = {
  connectionString: databaseUrl,
  ssl: isProduction,
  max: 5,
  idleTimeoutMillis: 30000
}

const pool = new Pool(dbConfig)

export const db = drizzle({ client: pool, logger: !isProduction, schema })

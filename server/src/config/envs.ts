import 'dotenv/config'
import { get } from 'env-var'

export const envs = {
  SERVER_PORT: get('SERVER_PORT').default(3000).asPortNumber(),
  DATABASE_URL: get('DATABASE_URL').required().asString(),
  JWT_SEED: get('JWT_SEED').required().asString(),
  NODE_ENV: get('NODE_ENV').default('development').asString()
}

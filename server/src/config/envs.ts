import 'dotenv/config'
import { get } from 'env-var'

export const envs = {
  SERVER_HOST: get('SERVER_HOST').default('localhost').asString(),
  SERVER_PORT: get('SERVER_PORT').default(3000).asPortNumber(),
  DATABASE_URL: get('DATABASE_URL').required().asString(),
  DATABASE_ENABLE_SSL: get('DATABASE_ENABLE_SSL').asBool(),
  JWT_SEED: get('JWT_SEED').required().asString(),
  NODE_ENV: get('NODE_ENV').default('development').asString(),
  REFRESH_TOKEN_DURATION: get('REFRESH_TOKEN_DURATION')
    .default(60 * 60 * 24 * 7)
    .asIntPositive(),
  ACCESS_TOKEN_DURATION: get('ACCESS_TOKEN_DURATION')
    .default(60 * 30)
    .asIntPositive(),
  ADMIN_USER: get('ADMIN_USER').required().asString(),
  ADMIN_PASSWORD: get('ADMIN_PASSWORD').required().asString(),
  ALLOWED_ORIGINS: get('ALLOWED_ORIGINS')
    .default('')
    .asArray(',')
    .filter(Boolean)
}

import 'dotenv/config'
import { get } from 'env-var'

export const envs = {
  NODE_ENV: get('NODE_ENV').default('development').asString(),
  ALLOWED_ORIGINS: get('ALLOWED_ORIGINS').default('').asArray(','),
  SERVER_HOST: get('SERVER_HOST').default('localhost').asString(),
  SERVER_PORT: get('SERVER_PORT').default(3000).asPortNumber(),
  DATABASE_URL: get('DATABASE_URL').required().asString(),
  DATABASE_ENABLE_SSL: get('DATABASE_ENABLE_SSL').asBool(),
  JWT_SEED: get('JWT_SEED').required().asString(),
  REFRESH_TOKEN_DURATION: get('REFRESH_TOKEN_DURATION')
    .default(60 * 60 * 24 * 7)
    .asIntPositive(),
  ACCESS_TOKEN_DURATION: get('ACCESS_TOKEN_DURATION')
    .default(60 * 30)
    .asIntPositive(),
  ADMIN_USER: get('ADMIN_USER').required().asString(),
  ADMIN_PASSWORD: get('ADMIN_PASSWORD').required().asString(),
  CONSULTA_API_BASE_URL: get('CONSULTA_API_BASE_URL').asString(),
  TOKEN_CONSULTA: get('TOKEN_CONSULTA').asString(),
  FACTURACION_API_BASE_URL: get('FACTURACION_API_BASE_URL').asString(),
  TOKEN_FACTURACION: get('TOKEN_FACTURACION').asString(),
  LOGS: get('LOGS').default('console').asString(),
  MAX_UPLOAD_FILE_SIZE_MB: get('MAX_UPLOAD_FILE_SIZE_MB')
    .default(150)
    .asIntPositive()
}

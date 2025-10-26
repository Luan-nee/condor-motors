import { envs } from '@/config/envs'
import { testDatabaseConnection } from '@/db/connection'
import { AppRoutes } from '@/presentation/routes/index.routes'
import { Server } from '@presentation/server'

const main = async () => {
  const {
    SERVER_PORT: port,
    SERVER_HOST: host,
    PRIVATE_STORAGE_PATH: privateStoragePath,
    PUBLIC_STORAGE_PATH: publicStoragePath
  } = envs

  const { routes } = AppRoutes

  await testDatabaseConnection()

  const server = new Server({
    port,
    host,
    routes,
    privateStoragePath,
    publicStoragePath
  })

  server.start()
}

void main()

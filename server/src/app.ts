import { envs } from '@/config/envs'
import { testDatabaseConnection } from '@/db/connection'
import { AppRoutes } from '@presentation/routes'
import { Server } from '@presentation/server'

const main = async () => {
  const { SERVER_PORT: port } = envs
  const { routes } = AppRoutes

  try {
    await testDatabaseConnection()

    const server = new Server({
      port,
      routes
    })

    server.start()
  } catch (error) {
    // eslint-disable-next-line no-console
    console.error('Error starting the server:', error)
    process.exit(1)
  }
}

void main()

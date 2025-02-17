import { AppRoutes } from '@/presentation/routes'
import { envs } from './config/envs'
import { Server } from './presentation/server'

const main = () => {
  const { SERVER_PORT: port } = envs
  const { routes } = AppRoutes

  const server = new Server({
    port,
    routes
  })

  server.start()
}

main()

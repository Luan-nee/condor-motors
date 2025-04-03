import { login } from './controllers/auth'

const baseUrl = import.meta.env.BASE_URL

export const routes = {
  dashboard: `${baseUrl}/dashboard`,
  login: `${baseUrl}/login`
}

import { login } from './lib/auth'

const baseUrl = import.meta.env.BASE_URL

export const routes = {
  dashboard: `${baseUrl}/dashboard`,
  login: `${baseUrl}/login`
}

import { apiBaseUrl, baseUrl } from './consts'

export const routes = {
  dashboard: `${baseUrl}/dashboard`,
  login: `${baseUrl}/login`
}

export const backendRoutes = {
  testSession: `${apiBaseUrl}/api/auth/testsession`,
  login: `${apiBaseUrl}/api/auth/login`,
  refresh: `${apiBaseUrl}/api/auth/refresh`,
  logout: `${apiBaseUrl}/api/auth/logout`,
  downloadFile: `${apiBaseUrl}/api/archivos/download`,
  downloadFilePublic: `${apiBaseUrl}/downloads`,
  shareFile: `${apiBaseUrl}/api/archivos/share`
}

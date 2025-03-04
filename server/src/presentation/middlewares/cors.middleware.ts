import cors from 'cors'

export class CorsMiddleware {
  static readonly requests = cors()
}

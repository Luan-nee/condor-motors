import cookieParser from 'cookie-parser'

export class CookieMiddleware {
  static readonly requests = cookieParser()
}

import cookieParser from 'cookie-parser'

export class CookieMiddleware {
  static requests = cookieParser()
}

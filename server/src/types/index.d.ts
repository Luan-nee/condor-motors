declare namespace Express {
  export interface Request {
    authPayload?: AuthPayload
  }
}

interface AuthPayload {
  id: number
}

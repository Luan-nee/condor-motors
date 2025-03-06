declare namespace Express {
  export interface Request {
    authPayload?: AuthPayload
    sucursalId?: number
  }
}

interface AuthPayload {
  id: number
}

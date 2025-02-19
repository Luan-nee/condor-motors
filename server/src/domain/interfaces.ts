import type { DecodeOptions, JwtPayload, SignOptions } from 'jsonwebtoken'

type durationType = SignOptions['expiresIn']

export interface TokenAuthenticator {
  generateToken: (payload: object, duration: durationType) => string
  generateAccessToken: (payload: object, duration?: durationType) => string
  decode: (token: string, options?: DecodeOptions) => string | JwtPayload | null
  generateRefreshToken: (
    payload: object,
    duration?: durationType
  ) => {
    secret: string
    token: string
  }
}

export interface Encryptor {
  hash: (password: string) => Promise<string>
  compare: (password: string, hash: string) => Promise<boolean>
}

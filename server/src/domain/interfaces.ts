import type { SignOptions } from 'jsonwebtoken'

type durationType = SignOptions['expiresIn']

export interface TokenAuthenticator {
  generateToken: (payload: object, duration?: durationType) => string
}

export interface Encryptor {
  hash: (password: string) => Promise<string>
  compare: (password: string, hash: string) => Promise<boolean>
}

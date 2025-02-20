import type {
  decodeType,
  generateAccessTokenType,
  generateRefreshTokenType,
  randomSecretType,
  verifyType
} from '@/config/types'

export interface TokenAuthenticator {
  generateAccessToken: generateAccessTokenType
  generateRefreshToken: generateRefreshTokenType
  decode: decodeType
  verify: verifyType
  randomSecret: randomSecretType
}

export interface Encryptor {
  hash: (password: string) => Promise<string>
  compare: (password: string, hash: string) => Promise<boolean>
}

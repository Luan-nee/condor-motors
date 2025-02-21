import type {
  bearerAccessTokenType,
  decodeType,
  generateAccessTokenType,
  generateRefreshTokenType,
  randomSecretType,
  refreshAccessTokenType,
  refreshTokenCookieType,
  verifyType
} from '@/types/config'

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

export interface AuthSerializer {
  refreshTokenCookie: refreshTokenCookieType
  bearerAccessToken: bearerAccessTokenType
  refreshAccessToken: refreshAccessTokenType
}

import type {
  bearerAccessTokenType,
  cancelDocumentType,
  consultDocumentType,
  decodeType,
  generateAccessTokenType,
  generateRefreshTokenType,
  randomSecretType,
  refreshAccessTokenType,
  refreshTokenCookieType,
  searchClientType,
  sendDocumentType,
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

export interface BillingService {
  sendDocument: sendDocumentType
  consultDocument: consultDocumentType
  cancelDocument: cancelDocumentType
}

export interface ConsultService {
  searchClient: searchClientType
}

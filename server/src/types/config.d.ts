import type {
  DecodeOptions,
  Jwt,
  JwtPayload,
  SignOptions,
  VerifyOptions
} from 'jsonwebtoken'

type duration = SignOptions['expiresIn']

export type generateAccessTokenType = (args: {
  payload: object
  duration?: duration
}) => string

export type generateRefreshTokenType = (args: {
  payload: object
  duration?: duration
  secret?: string
}) => {
  secret: string
  token: string
}

export type decodeType = (args: {
  token: string
  options?: DecodeOptions
}) => string | JwtPayload | null

export type verifyType = (args: {
  token: string
  options?: VerifyOptions
  secret?: string
}) => string | JwtPayload | Jwt

export type randomSecretType = () => string

export type refreshTokenCookieType = (args: { refreshToken: string }) => string

export type bearerAccessTokenType = (args: { accessToken: string }) => string

export type refreshAccessTokenType = (args: {
  accessToken: string
  refreshToken: string
}) => {
  refresTokenCookie: string
  bearerAccessToken: string
}

interface Success<T> {
  data: T
  error: null
}

interface Failure<E> {
  data: null
  error: E
}

type Result<T, E> = Success<T> | Failure<E>

export type sendDocumentType = (args: {
  document: DocumentoFacturacion
}) => Promise<Result<BillingApiSuccessResponse, BillingApiErrorResponse>>

export type consultDocumentType = (args: {
  document: ConsultDocument
}) => Promise<Result<BillingApiSuccessResponse, BillingApiErrorResponse>>

export type cancelDocumentType = (args: {
  document: ConsultDocument
}) => Promise<Result<BillingApiSuccessResponse, BillingApiErrorResponse>>

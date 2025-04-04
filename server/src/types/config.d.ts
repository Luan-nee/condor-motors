import type {
  DecodeOptions,
  Jwt,
  JwtPayload,
  SignOptions,
  VerifyOptions
} from 'jsonwebtoken'

type duration = SignOptions['expiresIn']

export type generateAccessTokenType = (args: {
  payload: Record<string, any>
  duration?: duration
}) => string

export type generateRefreshTokenType = (args: {
  payload: Record<string, any>
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

export type generateDownloadTokenType = (args: {
  payload: Record<string, any>
  durationMs?: number
  secret?: string
}) => {
  token: string
  expiresAt: number
}

export type validateDownloadTokenType = (args: {
  token: string
  payload: Record<string, any>
  expiresAt: number
  secret?: string
}) => boolean

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
}) => Promise<Result<BillingApiConsultDocResponse, BillingApiErrorResponse>>

export type cancelDocumentType = (args: {
  document: CancelDoc
}) => Promise<Result<BillingApiCancelDocResponse, BillingApiErrorResponse>>

export type searchClientType = (args: {
  numeroDocumento: string
}) => Promise<Result<ConsultApiSuccessResponse, ConsultApiErrorResponse>>

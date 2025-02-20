import type { DecodeOptions, JwtPayload, SignOptions } from 'jsonwebtoken'

type duration = SignOptions['expiresIn']

interface generateAccessTokenArgs {
  payload: object
  duration?: duration
}

interface generateRefreshTokenArgs {
  payload: object
  duration?: duration
  secret?: string
}

interface decodeArgs {
  token: string
  options?: DecodeOptions
}

export type generateAccessTokenType = (args: generateAccessTokenArgs) => string
export type generateRefreshTokenType = (args: generateRefreshTokenArgs) => {
  secret: string
  token: string
}
export type decodeType = (args: decodeArgs) => string | JwtPayload | null
export type randomSecretType = () => string

import { envs } from '@/config/envs'
import { CustomError } from '@/core/errors/custom.error'
import type {
  decodeType,
  generateAccessTokenType,
  generateDownloadTokenType,
  generateRefreshTokenType,
  randomSecretType,
  validateDownloadTokenType,
  verifyType
} from '@/types/config'
import { randomBytes, createHmac } from 'crypto'
import { decode, sign, verify } from 'jsonwebtoken'

const {
  JWT_SEED,
  REFRESH_TOKEN_DURATION,
  ACCESS_TOKEN_DURATION,
  JWT_DOWNLOAD_SEED
} = envs

export class JwtAdapter {
  static generateAccessToken: generateAccessTokenType = ({
    payload,
    duration
  }) => {
    const tokenDuration = duration ?? ACCESS_TOKEN_DURATION
    return sign(payload, JWT_SEED, { expiresIn: tokenDuration })
  }

  static generateRefreshToken: generateRefreshTokenType = ({
    payload,
    duration,
    secret
  }) => {
    const privateSecret = secret ?? this.randomSecret()
    const tokenDuration = duration ?? REFRESH_TOKEN_DURATION

    const token = sign(payload, privateSecret, { expiresIn: tokenDuration })

    return {
      secret: privateSecret,
      token
    }
  }

  static decode: decodeType = ({ token, options }) => decode(token, options)

  static verify: verifyType = ({ token, options, secret }) => {
    const privateSecret = secret ?? JWT_SEED

    return verify(token, privateSecret, options)
  }

  static randomSecret: randomSecretType = () => randomBytes(64).toString('hex')

  static generateDownloadToken: generateDownloadTokenType = ({
    payload,
    durationMs,
    secret
  }) => {
    const privateSecret = secret ?? JWT_DOWNLOAD_SEED

    if (typeof privateSecret !== 'string') {
      throw CustomError.serviceUnavailable(
        'No se especificó un token para autorizar las descargas de archivos'
      )
    }

    const duration = durationMs ?? 15 * 60 * 1000

    const orderedPayload = JSON.stringify(payload, Object.keys(payload).sort())
    const expiresAt = Date.now() + duration
    const data = `${orderedPayload}:${expiresAt}`

    return createHmac('sha256', privateSecret)
      .update(data)
      .digest('base64url')
      .substring(0, 32)
  }

  static validateDownloadToken: validateDownloadTokenType = ({
    token,
    payload,
    expiresAt,
    secret
  }) => {
    const privateSecret = secret ?? JWT_DOWNLOAD_SEED

    if (typeof privateSecret !== 'string') {
      throw CustomError.serviceUnavailable(
        'No se especificó un token para autorizar las descargas de archivos'
      )
    }

    const orderedPayload = JSON.stringify(payload, Object.keys(payload).sort())

    if (Date.now() > expiresAt) {
      return false
    }

    const data = `${orderedPayload}:${expiresAt}`
    const expectedToken = createHmac('sha256', privateSecret)
      .update(data)
      .digest('base64url')
      .substring(0, 32)

    return token === expectedToken
  }
}

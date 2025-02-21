import { envs } from '@/config/envs'
import type {
  decodeType,
  generateAccessTokenType,
  generateRefreshTokenType,
  randomSecretType,
  verifyType
} from '@/types/config'
import { randomBytes } from 'crypto'
import { decode, sign, verify } from 'jsonwebtoken'

const { JWT_SEED, REFRESH_TOKEN_DURATION, ACCESS_TOKEN_DURATION } = envs

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
}

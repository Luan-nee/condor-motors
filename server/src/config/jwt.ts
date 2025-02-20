import { envs } from '@/config/envs'
import type {
  decodeType,
  generateAccessTokenType,
  generateRefreshTokenType,
  randomSecretType,
  verifyType
} from '@/config/types'
import { randomBytes } from 'crypto'
import { decode, sign, verify } from 'jsonwebtoken'

const { JWT_SEED } = envs

export class JwtAdapter {
  static generateAccessToken: generateAccessTokenType = ({
    payload,
    duration = '30m'
  }) => sign(payload, JWT_SEED, { expiresIn: duration })

  static generateRefreshToken: generateRefreshTokenType = ({
    payload,
    duration = '7d',
    secret
  }) => {
    const privateSecret = secret ?? this.randomSecret()
    const token = sign(payload, privateSecret, { expiresIn: duration })

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

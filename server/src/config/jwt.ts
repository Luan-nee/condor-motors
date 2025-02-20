import { envs } from '@/config/envs'
import type {
  decodeType,
  generateAccessTokenType,
  generateRefreshTokenType,
  randomSecretType
} from '@/config/types'
import { randomBytes } from 'crypto'
import { decode, sign } from 'jsonwebtoken'

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

  static randomSecret: randomSecretType = () => randomBytes(64).toString('hex')
}

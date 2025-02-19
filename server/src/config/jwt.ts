import { envs } from '@/config/envs'
import { randomBytes } from 'crypto'
import {
  decode,
  sign,
  type DecodeOptions,
  type SignOptions
} from 'jsonwebtoken'

const { JWT_SEED } = envs

type duration = SignOptions['expiresIn']

export class JwtAdapter {
  static generateToken(payload: object, duration: duration) {
    return sign(payload, JWT_SEED, { expiresIn: duration })
  }

  static generateAccessToken(payload: object, duration: duration = '30m') {
    return sign(payload, JWT_SEED, { expiresIn: duration })
  }

  static decode(token: string, options?: DecodeOptions) {
    return decode(token, options)
  }

  static generateRefreshToken(payload: object, duration: duration = '7d') {
    const secret = randomBytes(64).toString('hex')

    const token = sign(payload, secret, { expiresIn: duration })

    return {
      secret,
      token
    }
  }
}

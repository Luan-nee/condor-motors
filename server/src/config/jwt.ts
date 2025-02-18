import { sign, type SignOptions } from 'jsonwebtoken'
import { envs } from './envs'

const { JWT_SEED } = envs

type duration = SignOptions['expiresIn']

export class JwtAdapter {
  static generateToken(payload: object, duration: duration) {
    return sign(payload, JWT_SEED, { expiresIn: duration })
  }
}

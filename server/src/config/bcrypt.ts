import { compare, genSalt, hash } from 'bcryptjs'

export class BcryptAdapter {
  static async hash(password: string) {
    const salt = await genSalt(12)
    return await hash(password, salt)
  }

  static async compare(password: string, hash: string) {
    return await compare(password, hash)
  }
}

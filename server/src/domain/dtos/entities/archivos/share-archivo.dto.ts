import { shareArchivoValidator } from '@/domain/validators/entities/archivos/archivo.validator'

export class ShareArchivoDto {
  public filename: string
  public duration?: number

  private constructor({ filename, duration }: ShareArchivoDto) {
    this.filename = filename
    this.duration = duration
  }

  static create(input: any): [string?, ShareArchivoDto?] {
    const result = shareArchivoValidator(input)

    if (!result.success) {
      return [result.error.message, undefined]
    }

    return [undefined, new ShareArchivoDto(result.data)]
  }
}

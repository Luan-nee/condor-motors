/* eslint-disable @typescript-eslint/no-unsafe-type-assertion */
import { fileTypeValues } from '@/consts'
import { createArchivoValidator } from '@/domain/validators/entities/archivos/archivo.validator'
import type { FileTypeValues } from '@/types/zod'

export class CreateArchivoDto {
  public nombre: string
  public visible: boolean
  public tipo: FileTypeValues

  private constructor({ nombre, visible, tipo }: CreateArchivoDto) {
    this.nombre = nombre
    this.visible = visible
    this.tipo = tipo
  }
  private static isValidFileType(type: string): type is FileTypeValues {
    return Object.values(fileTypeValues).includes(type as FileTypeValues)
  }

  static validate(input: any): [string?, CreateArchivoDto?] {
    const result = createArchivoValidator(input)

    if (!result.success) {
      return [result.error.message, undefined]
    }

    const { data } = result

    if (!this.isValidFileType(data.tipo)) {
      return [
        'El tipo de archivo es inválido solo se permiten estos tipos (apk | desktop-app)',
        undefined
      ]
    }

    return [
      undefined,
      new CreateArchivoDto({
        nombre: data.nombre,
        visible: data.visible,
        tipo: data.tipo
      })
    ]
  }
}

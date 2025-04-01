import type { FileTypeValues } from '@/types/consts'

export interface SuccessUploadApk {
  file: {
    id: number
    nombre: string
    filename: string
    tipo: string
    size: string
    metadata: {
      encoding: string
      mimetype: string
      originalName: string
    }
    visible: boolean
    fechaCreacion: string
    user: {
      id: number
      nombre: string
    }
  }
}

export interface UploadApkFileDto {
  nombre: string
  visible: boolean
  tipo: FileTypeValues
  appFile: string
}

export type UploadApkFile = Method<UploadApkFileDto, SuccessUploadApk, ApiError>

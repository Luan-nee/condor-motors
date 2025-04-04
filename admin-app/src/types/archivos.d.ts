import type { FileTypeValues } from '@/types/consts'

export interface SuccessUploadApk {
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

export interface UploadFileDto {
  nombre: string
  version: string
  tipo: string
  appFile: File
}

export type uploadFile = MethodAll<UploadFileDto, SuccessUploadApk, ApiError>

export interface FileEntity {
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
  version: string
  fechaCreacion: string
  user: {
    id: number
    nombre: string
  }
}

export type GetFilesApi = MethodAll<void, FileEntity[], ApiError>
export type DeleteFileApi = MethodAll<{ id: number }, { id: number }, ApiError>

export type DownloadFileApi = MethodAll<
  { filename: string },
  { message: string },
  ApiError
>

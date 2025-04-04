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
  visible: boolean
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
  visible: boolean
  fechaCreacion: string
  user: {
    id: number
    nombre: string
  }
}

export type GetFilesApi = MethodAll<void, FileEntity[], ApiError>
export type DeleteFileApi = MethodAll<{ id: number }, { id: number }, ApiError>

export interface FileDownloadData {
  id: number
  filename: string
  path: string
}

export type DownloadFileApi = MethodAll<
  { filename: string },
  { message: string },
  ApiError
>

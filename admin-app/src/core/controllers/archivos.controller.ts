import { fileTypeValues } from '@/core/consts'
import type {
  DeleteFileApi,
  FileEntity,
  GetFilesApi,
  SuccessUploadApk,
  UploadApkFile,
  UploadApkFileDto
} from '@/types/archivos'
import { httpRequest } from '@/core/lib/network'

export const uploadApk: UploadApkFile = async (
  uploadApkFileDto: UploadApkFileDto
) => {
  if (uploadApkFileDto.tipo !== fileTypeValues.apk) {
    return { error: { message: 'El tipo de archivo debe ser apk' } }
  }

  const formData = new FormData()
  formData.append('nombre', uploadApkFileDto.nombre)
  formData.append('tipo', uploadApkFileDto.tipo)
  formData.append('app_file', uploadApkFileDto.appFile)
  if (uploadApkFileDto.visible) {
    formData.append('visible', 'true')
  }

  const { data, error } = await httpRequest<SuccessUploadApk>(
    '/api/archivos/apk',
    (accessToken) => ({
      method: 'POST',
      headers: {
        Authorization: accessToken
      },
      body: formData,
      credentials: 'include'
    })
  )

  console.log(data)

  if (error != null) {
    return { error }
  }

  return { data }
}

export const getFiles: GetFilesApi = async () => {
  const { data, error } = await httpRequest<FileEntity[]>(
    '/api/archivos',
    (accessToken) => ({
      method: 'GET',
      headers: {
        'Content-type': 'application/json',
        Authorization: accessToken
      },
      credentials: 'include'
    })
  )

  if (error != null) {
    return { error: { message: error.message } }
  }

  return { data }
}

export const deleteFile: DeleteFileApi = async ({ id: fileId }) => {
  const { data, error } = await httpRequest<{ id: number }>(
    `/api/archivos/${fileId}`,
    (accessToken) => ({
      method: 'DELETE',
      headers: {
        'Content-type': 'application/json',
        Authorization: accessToken
      },
      credentials: 'include'
    })
  )

  if (error != null) {
    return { error: error }
  }

  return {
    data
  }
}

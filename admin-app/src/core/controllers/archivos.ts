import type {
  DeleteFileApi,
  FileEntity,
  GetFilesApi,
  SuccessUploadApk,
  uploadFile,
  UploadFileDto
} from '@/types/archivos'
import { httpRequest } from '@/core/lib/network'

export const uploadApk: uploadFile = async (uploadFileDto: UploadFileDto) => {
  const formData = new FormData()
  formData.append('nombre', uploadFileDto.nombre)
  formData.append('tipo', uploadFileDto.tipo)
  formData.append('app_file', uploadFileDto.appFile)
  if (uploadFileDto.visible) {
    formData.append('visible', 'true')
  }

  const { data, error } = await httpRequest<SuccessUploadApk>(
    '/api/archivos/upload',
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

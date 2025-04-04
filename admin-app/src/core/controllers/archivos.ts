import type {
  DeleteFileApi,
  DownloadFileApi,
  FileDownloadData,
  FileEntity,
  GetFilesApi,
  SuccessUploadApk,
  uploadFile,
  UploadFileDto
} from '@/types/archivos'
import { httpRequest } from '@/core/lib/network'
import { backendRoutes } from '../routes'
import { tryCatchAll } from '../lib/try-catch'

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

const downloadBlobFile = (blob: Blob, filename: string) => {
  const url = window.URL.createObjectURL(blob)
  const a = document.createElement('a')

  a.style.display = 'none'
  a.href = url

  a.download = filename

  document.body.appendChild(a)
  a.click()

  document.body.removeChild(a)
  window.URL.revokeObjectURL(url)
}

export const downloadFile: DownloadFileApi = async ({ filename }) => {
  const { data: blob, error } = await httpRequest<Blob>(
    `${backendRoutes.downloadFile}/${filename}`,
    (accessToken) => ({
      method: 'GET',
      headers: {
        'Content-type': 'application/json',
        Authorization: accessToken
      },
      credentials: 'include'
    }),
    'blob'
  )

  if (error != null) {
    return { error: error }
  }

  const { error: blobError } = await tryCatchAll(() => {
    downloadBlobFile(blob, filename)
  })

  if (blobError != null) {
    return {
      error: {
        message: 'Ha ocurrido un error al intentar descargar el archivo'
      }
    }
  }

  return {
    data: {
      message: 'Archivo descargado'
    }
  }
}

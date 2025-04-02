import {
  accessTokenCookieName,
  apiBaseUrl,
  fileTypeValues
} from '@/core/consts'
import type {
  DeleteFileApi,
  GetFilesApi,
  UploadApkFile,
  UploadApkFileDto
} from '@/types/archivos'
import { getCookie } from '@/core/lib/cookies'
import { refreshAccessToken } from '@/core/lib/auth'

export const uploadApk: UploadApkFile = async (
  uploadApkFileDto: UploadApkFileDto
) => {
  if (uploadApkFileDto.tipo !== fileTypeValues.apk) {
    return { data: null, error: { message: 'El tipo de archivo debe ser apk' } }
  }

  const formData = new FormData()
  formData.append('nombre', uploadApkFileDto.nombre)
  formData.append('tipo', uploadApkFileDto.tipo)
  formData.append('app_file', uploadApkFileDto.appFile)
  if (uploadApkFileDto.visible) {
    formData.append('visible', 'true')
  }

  let accessToken = getCookie(accessTokenCookieName)

  const redirectToLogin = () => {
    window.location.replace('/login')
  }

  if (accessToken == null || accessToken.length < 1) {
    const { data, error } = await refreshAccessToken()

    if (error !== null) {
      return {
        data: null,
        error: { message: error.message, action: redirectToLogin }
      }
    }

    accessToken = data.accessToken
  }

  const res = await fetch(`${apiBaseUrl}/api/archivos/apk`, {
    method: 'POST',
    headers: {
      Authorization: accessToken
    },
    body: formData,
    credentials: 'include'
  })

  try {
    const textResponse = await res.text()
    const json = JSON.parse(textResponse)

    if (json.status !== 'success') {
      return { data: null, error: { message: String(json.error) } }
    }

    return {
      error: null,
      data: {
        file: json.data
      }
    }
  } catch (error) {
    return {
      error: {
        message: 'Unexpected format response'
      },
      data: null
    }
  }
}

export const getFiles: GetFilesApi = async () => {
  let accessToken = getCookie(accessTokenCookieName)

  const redirectToLogin = () => {
    window.location.replace('/login')
  }

  if (accessToken == null || accessToken.length < 1) {
    const { data, error } = await refreshAccessToken()

    if (error !== null) {
      return {
        data: null,
        error: { message: error.message, action: redirectToLogin }
      }
    }

    accessToken = data.accessToken
  }

  const res = await fetch(`${apiBaseUrl}/api/archivos`, {
    method: 'GET',
    headers: {
      Authorization: accessToken
    },
    credentials: 'include'
  })

  try {
    const textResponse = await res.text()
    const json = JSON.parse(textResponse)

    if (json.status !== 'success') {
      return { data: null, error: { message: String(json.error) } }
    }

    return {
      error: null,
      data: json.data
    }
  } catch (error) {
    return {
      error: {
        message: 'Unexpected format response'
      },
      data: null
    }
  }
}

export const deleteFile: DeleteFileApi = async ({ id: fileId }) => {
  let accessToken = getCookie(accessTokenCookieName)

  const redirectToLogin = () => {
    window.location.replace('/login')
  }

  if (accessToken == null || accessToken.length < 1) {
    const { data, error } = await refreshAccessToken()

    if (error !== null) {
      return {
        data: null,
        error: { message: error.message, action: redirectToLogin }
      }
    }

    accessToken = data.accessToken
  }

  const res = await fetch(`${apiBaseUrl}/api/archivos/${fileId}`, {
    method: 'DELETE',
    headers: {
      Authorization: accessToken
    },
    credentials: 'include'
  })

  try {
    const textResponse = await res.text()
    const json = JSON.parse(textResponse)

    if (json.status !== 'success') {
      return { data: null, error: { message: String(json.error) } }
    }

    return {
      error: null,
      data: json.data
    }
  } catch (error) {
    return {
      error: {
        message: 'Unexpected format response'
      },
      data: null
    }
  }
}

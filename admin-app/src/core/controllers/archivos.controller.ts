import { apiBaseUrl, fileTypeValues } from '@/core/consts'
import type { UploadApkFile, UploadApkFileDto } from '@/types/archivos'

export const uploadApk: UploadApkFile = async (
  uploadApkFileDto: UploadApkFileDto
) => {
  if (uploadApkFileDto.tipo !== fileTypeValues.apk) {
    return { data: null, error: { message: 'El tipo de archivo debe ser apk' } }
  }

  const data = {
    nombre: uploadApkFileDto.nombre,
    visible: uploadApkFileDto.visible,
    tipo: uploadApkFileDto.tipo,
    app_file: uploadApkFileDto.appFile
  }

  const res = await fetch(`${apiBaseUrl}/api/archivos/apk`, {
    method: 'POST',
    headers: {
      'Content-type': 'application/json'
    },
    credentials: 'include',
    body: JSON.stringify(data)
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

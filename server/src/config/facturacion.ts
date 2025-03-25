import { envs } from '@/config/envs'
import { CustomError } from '@/core/errors/custom.error'
import type { sendDocumentType } from '@/types/config'

const { TOKEN_FACTURACION, FACTURACION_API_BASE_URL } = envs

export class ServicioFacturacion {
  private static checkAvailability() {
    if (FACTURACION_API_BASE_URL === undefined) {
      throw CustomError.serviceUnavailable(
        'No se especificó la url base del servicio de facturación, por lo que no se puede utilizar este servicio.'
      )
    }

    if (TOKEN_FACTURACION === undefined) {
      throw CustomError.serviceUnavailable(
        'No se especificó un token de facturación, por lo que no se puede utilizar este servicio.'
      )
    }
  }

  static sendDocument: sendDocumentType = async ({ document }) => {
    ServicioFacturacion.checkAvailability()

    const res = await fetch(FACTURACION_API_BASE_URL + '/documentos', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${TOKEN_FACTURACION}`
      },
      body: JSON.stringify(document)
    })

    try {
      const textResponse = await res.text()

      if (!res.ok) {
        if (res.status === 401) {
          throw CustomError.serviceUnavailable('Token de facturación inválido')
        }
        if (res.status >= 500) {
          throw CustomError.serviceUnavailable(
            'El servicio de facturación no se encuentra activo en este momento'
          )
        }

        const error = JSON.parse(textResponse)
        return { data: null, error, rawTextResponse: textResponse }
      }

      const apiResponse = JSON.parse(textResponse)

      if (apiResponse.success !== true) {
        return { data: null, error: apiResponse, rawTextResponse: textResponse }
      }

      return { data: apiResponse, error: null, rawTextResponse: textResponse }
    } catch (e) {
      const textResponse = await res.text()
      const error = {
        message:
          'La respuesta obtenida del servicio de facturación se encuentra en un formato inesperado',
        success: false
      }
      return { data: null, error, rawTextResponse: textResponse }
    }
  }
}

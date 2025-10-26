import { envs } from '@/config/envs'
import { CustomError } from '@/core/errors/custom.error'
import type {
  cancelDocumentType,
  consultDocumentType,
  sendDocumentType
} from '@/types/config'
import { logger } from './logger'

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

  private static async formatResponse(res: Response) {
    if (res.status === 401) {
      throw CustomError.serviceUnavailable('Token de facturación inválido')
    }
    if (res.status >= 500) {
      throw CustomError.serviceUnavailable(
        'El servicio de facturación no se encuentra activo en este momento'
      )
    }

    try {
      const jsonResponse = await res.json()

      if (jsonResponse.success !== true) {
        return { data: null, error: jsonResponse }
      }

      return { data: jsonResponse, error: null }
    } catch (e) {
      logger.error({
        message: 'Unexpected error on ServicioFacturacion',
        context: { error: e }
      })

      const error = {
        message:
          'La respuesta obtenida del servicio de facturación se encuentra en un formato inesperado',
        success: false
      }
      return { data: null, error }
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

    const apiResponse = await this.formatResponse(res)

    return apiResponse
  }

  static consultDocument: consultDocumentType = async ({ document }) => {
    ServicioFacturacion.checkAvailability()

    const res = await fetch(FACTURACION_API_BASE_URL + '/consulta', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${TOKEN_FACTURACION}`
      },
      body: JSON.stringify(document)
    })

    const apiResponse = await this.formatResponse(res)

    return apiResponse
  }

  static cancelDocument: cancelDocumentType = async ({ document }) => {
    ServicioFacturacion.checkAvailability()

    const res = await fetch(FACTURACION_API_BASE_URL + '/anular', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${TOKEN_FACTURACION}`
      },
      body: JSON.stringify(document)
    })

    const apiResponse = await this.formatResponse(res)

    return apiResponse
  }
}

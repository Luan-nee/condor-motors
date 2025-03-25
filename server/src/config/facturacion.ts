import { envs } from '@/config/envs'
import { CustomError } from '@/core/errors/custom.error'
import type { sendDocumentType } from '@/types/config'

const { TOKEN_FACTURACION, FACTURACION_API_BASE_URL } = envs

export class ServicioFacturacion {
  private static checkAvailability(): void {
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

    if (!res.ok) {
      if (res.status === 401) {
        throw CustomError.serviceUnavailable('Token de facturación inválido')
      }
      if (res.status >= 500) {
        throw CustomError.serviceUnavailable(
          'El servicio de facturación no se encuentra activo en este momento'
        )
      }

      const error = await res.json()
      return { data: null, error }
    }

    const data = await res.json()
    return { data, error: null }
  }
}

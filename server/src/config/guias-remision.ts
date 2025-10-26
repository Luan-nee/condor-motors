import { envs } from '@/config/envs'
import { CustomError } from '@/core/errors/custom.error'
import { logger } from './logger'

const { GUIA_REMISION_API_BASE_URL, TOKEN_GUIA_REMISION, TOKEN_FACTURACION } =
  envs

export class ServicioGuiaRemision {
  private readonly apiBaseUrl?: string
  private readonly token?: string

  constructor() {
    this.apiBaseUrl = GUIA_REMISION_API_BASE_URL
    this.token = TOKEN_GUIA_REMISION ?? TOKEN_FACTURACION
  }

  private checkAvailability() {
    if (this.apiBaseUrl == null) {
      throw CustomError.serviceUnavailable(
        'No se especificó la url base del servicio de guias de remision, por lo que no se puede utilizar este servicio.'
      )
    }

    if (this.token == null) {
      throw CustomError.serviceUnavailable(
        'No se especificó un token de guias de remision o facturacion, por lo que no se puede utilizar este servicio.'
      )
    }
  }

  private async formatResponse(res: Response) {
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
    } catch (e: unknown) {
      logger.error({
        message: 'Unexpected error on ServicioGuiaRemision',
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
}

import { envs } from '@/config/envs'
import { CustomError } from '@/core/errors/custom.error'
import { Validator } from '@/domain/validators/validator'
import type { searchClientType } from '@/types/config'

const { TOKEN_CONSULTA, CONSULTA_API_BASE_URL } = envs

export class ServicioConsulta {
  private static checkAvailability() {
    if (CONSULTA_API_BASE_URL === undefined) {
      throw CustomError.serviceUnavailable(
        'No se especificó la url base del servicio de consulta, por lo que no se puede utilizar este servicio.'
      )
    }

    if (TOKEN_CONSULTA === undefined) {
      throw CustomError.serviceUnavailable(
        'No se especificó un token de consulta, por lo que no se puede utilizar este servicio.'
      )
    }
  }

  private static async formatResponse(res: Response) {
    if (res.status === 401) {
      throw CustomError.serviceUnavailable('Token de consulta inválido')
    }
    if (res.status >= 500) {
      throw CustomError.serviceUnavailable(
        'El servicio de consulta no se encuentra activo en este momento'
      )
    }

    try {
      const textResponse = await res.text()

      const jsonResponse = JSON.parse(textResponse)

      return { data: jsonResponse, error: null }
    } catch (e) {
      return {
        data: null,
        error: {
          detail:
            'La respuesta obtenida del servicio de consulta se encuentra en un formato inesperado'
        }
      }
    }
  }

  private static isValidRuc(val: string) {
    if (val.length !== 11 || !Validator.isOnlyNumbers(val)) {
      return false
    }

    if (!val.startsWith('20') && !val.startsWith('10')) {
      return false
    }

    return true
  }

  private static formatSuccessResponse(
    tipoDocumento: string,
    numeroDocumento: string,
    data: any
  ) {
    try {
      const response = {
        data: {
          tipoDocumento,
          numeroDocumento,
          denominacion: data?.nombres ?? data?.nombre ?? '',
          direccion: data?.direccion ?? ''
        },
        error: null
      }

      return response
    } catch (error) {
      return {
        data: null,
        error: {
          detail: 'No se encontró ninguna persona con ese número de documento'
        }
      }
    }
  }

  static searchClient: searchClientType = async ({ numeroDocumento }) => {
    ServicioConsulta.checkAvailability()

    const isValidDni =
      numeroDocumento.length === 8 && Validator.isOnlyNumbers(numeroDocumento)

    const isValidRuc = ServicioConsulta.isValidRuc(numeroDocumento)

    const tipoDocumento = isValidDni ? 'dni' : isValidRuc ? 'ruc' : undefined

    if (tipoDocumento == null) {
      return {
        data: null,
        error: {
          detail: 'No se encontró ninguna persona con ese número de documento'
        }
      }
    }

    const url = `${CONSULTA_API_BASE_URL}/${tipoDocumento}/${numeroDocumento}`
    const res = await fetch(url, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${TOKEN_CONSULTA}`
      }
    })

    const apiResponse = await this.formatResponse(res)

    if (apiResponse.error != null) {
      return apiResponse
    }

    return ServicioConsulta.formatSuccessResponse(
      tipoDocumento,
      numeroDocumento,
      apiResponse.data
    )
  }
}

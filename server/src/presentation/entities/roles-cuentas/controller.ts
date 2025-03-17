import { handleError } from '@/core/errors/handle.error'
import { CustomResponse } from '@/core/responses/custom.response'
import { GetRolesCuentas } from '@/domain/use-cases/entities/roles-cuentas/get-roles-cuentas.use-case'
import type { Request, Response } from 'express'

export class RolesCuentasController {
  getAll = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.unauthorized({ res })
      return
    }

    const { authPayload } = req

    const getRolesCuentas = new GetRolesCuentas(authPayload)

    getRolesCuentas
      .execute()
      .then((rolesCuentas) => {
        CustomResponse.success({ res, data: rolesCuentas })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
  }
}

import { AccessControl } from '@/core/access-control/access-control'
import { CustomError } from '@/core/errors/custom.error'
import { CustomResponse } from '@/core/responses/custom.response'
import type { NextFunction, Request, Response } from 'express'

export class AccessControlMiddleware {
  static readonly requests =
    (permissionCodes: string[]) =>
    (req: Request, res: Response, next: NextFunction) => {
      if (req.authPayload == null) {
        CustomResponse.unauthorized({ res })
        return
      }

      const { authPayload } = req

      AccessControl.verifyPermissions(authPayload, permissionCodes)
        .then((validPermissions) => {
          const permissionCodesMap = new Map(permissionCodes.map((p) => [p, p]))
          let hasPermission = false

          for (const permission of validPermissions) {
            const validPermission = permissionCodesMap.get(
              permission.codigoPermiso
            )

            if (validPermission != null) {
              hasPermission = true
              break
            }
          }

          if (hasPermission) {
            req.permissions = validPermissions
            next()
            return
          }

          next(CustomError.forbidden())
        })
        .catch(() => {
          next(CustomError.forbidden())
        })
    }
}

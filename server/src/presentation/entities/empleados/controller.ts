import { handleError } from '@/core/errors/handle.error'
import { CustomResponse } from '@/core/responses/custom.response'
import { CreateEmpleadoDto } from '@/domain/dtos/entities/empleados/create-empleados.dto'
import { NumericIdDto } from '@/domain/dtos/query-params/numeric-id.dto'
import { CreateEmpleado } from '@/domain/use-cases/entities/empleados/create-empleados.use-case'
import { GetEmpleadoById } from '@/domain/use-cases/entities/empleados/get-empleado-by-id.use-case'

import type { Request, Response } from 'express'

export class EmpleadosController {
  create = (req: Request, res: Response) => {
    if (req.authPayload === undefined) {
      CustomResponse.unauthorized({ res, error: 'Invalid access token' })
      return
    }

    const [error, createEmpleadoDto] = CreateEmpleadoDto.create(req.body)
    if (error !== undefined || createEmpleadoDto === undefined) {
      CustomResponse.badRequest({ res, error })
      return
    }

    // const { authPayload } = req

    // const createEmpleado = new CreateEmpleado(authPayload)
    const createEmpleado = new CreateEmpleado()

    createEmpleado
      .execute(createEmpleadoDto)
      .then((empleado) => {
        CustomResponse.success({ res, data: empleado })
      })
      .catch((error: unknown) => {
        handleError(error, res)
      })
    }
    getById = (req:Request,res:Response)=>{
      if(req.authPayload === undefined){
        CustomResponse.unauthorized({res,error:'Solo personas autorizadas'});
        return;
      }
      const [error,IdValor] = NumericIdDto.create(req.params);

      if(error !== undefined || IdValor === undefined){
        CustomResponse.badRequest({res,error:'Id no valido'});
        return;
      }
      const { authPayload } = req;
      const getEmpleadoById = new GetEmpleadoById(authPayload);

      getEmpleadoById
      .execute(IdValor)
      .then((empleado)=>{
        CustomResponse.success({res,data:empleado})
      })
      .catch((error:unknown)=>{
        handleError(error,res);        
      })

    }
}

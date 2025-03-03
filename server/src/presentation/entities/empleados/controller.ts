import { handleError } from '@/core/errors/handle.error'
import { CustomResponse } from '@/core/responses/custom.response'
import { CreateTrabajadorDto } from '@/domain/dtos/entities/trabajadores/create-empleados.dto'
import { CreateEmpleado } from '@/domain/use-cases/entities/empleados/create-empleados.use-case'

import type { Request, Response } from 'express'


export class ChambeadoresController{
    create = (req:Request,res:Response )=>{
        if (req.authPayload === undefined) {
              CustomResponse.unauthorized({ res, error: 'Token Invalido Para el Acceso' })
              return
        }

        const [error,crearChambeador] = CreateTrabajadorDto.create(req.body);
        if( !error || crearChambeador === undefined){
            CustomResponse.badRequest({res,error});
            return;
        }
        const { authPayload } = req;

        const createEmpleado = new CreateEmpleado(authPayload);


        createEmpleado.execute(crearChambeador).then((empleado)=>{
            CustomResponse.success({res,data:empleado})
        }).catch((error:unknown)=>{
            handleError(error,res)
        })
        //aun tengo errores en aqui , que no entiendo el por que 
    }
    
}
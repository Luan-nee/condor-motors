import { CustomResponse } from '@/core/responses/custom.response'
import type { Request, Response } from 'express'


export class ChambeadoresController{
    create = (req:Request,res:Response )=>{
        if (req.authPayload === undefined) {
              CustomResponse.unauthorized({ res, error: 'Token Invalido Para el Acceso' })
              return
        }
    }
}
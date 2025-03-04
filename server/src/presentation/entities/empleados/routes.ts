import {ChambeadoresController} from '@presentation/entities/empleados/controller'
import {Router} from 'express'

export class ChambeadorRoutes{
    static get routes(){
        const router = Router();

        const chambeadoresController = new ChambeadoresController();

        router.post('/',chambeadoresController.create); 
        return router;
    }
}
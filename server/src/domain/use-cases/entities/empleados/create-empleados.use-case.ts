import { CustomError } from "@/core/errors/custom.error";
import { empleadosTable } from "@/db/schema";
import {CreateTrabajadorDto} from '@/domain/dtos/entities/trabajadores/create-empleados.dto'
import { EmpleadoEntityMapper } from "@/domain/mappers/empleado-entity.mapper";
import { db } from '@db/connection'
import { ilike } from 'drizzle-orm'

export class CreateEmpleado{

    async execute( createEmpleadoDto : CreateTrabajadorDto){
        const empleadoConDNI = await db
            .select()
            .from(empleadosTable)
            .where(ilike(empleadosTable.dni,createEmpleadoDto.dni));
        
        if(empleadoConDNI.length > 0){
            throw CustomError.badRequest(`El empleado con este DNI ya esta registrado`)
        }
        const suelsostring = (createEmpleadoDto.sueldo === undefined)? undefined : createEmpleadoDto.sueldo.toFixed(2);
        const InsertarEmpleado = await db 
            .insert(empleadosTable)
            .values({
                nombre: createEmpleadoDto.nombre,
                apellidos:createEmpleadoDto.apellidos,
                edad:createEmpleadoDto.edad,
                dni:createEmpleadoDto.dni,
                horaInicioJornada:createEmpleadoDto.horaInicioJornada,
                horaFinJornada:createEmpleadoDto.horaFinJornada,
                fechaContratacion:createEmpleadoDto.fechaContratacion,
                sueldo: suelsostring , //aqui hay un error de validacion
                sucursalId:createEmpleadoDto.sucursalId
            })
            .returning();
        
        if( InsertarEmpleado.length <= 0){
            throw CustomError.internalServer("Ocurrio un error al registrar al empleado")
        }
        
        const [empleado] = InsertarEmpleado;

        const mappedEmpleado = EmpleadoEntityMapper.empleadoEntityFromObject(empleado)

        return mappedEmpleado;
    }

}
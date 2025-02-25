import { trabajadorSchema } from '@/domain/validators/entities/empleados/empleados.schema'
import { z } from 'zod'

const createtrabajadorSchema = z.object({
    nombre: trabajadorSchema.nombre,
    apellidos: trabajadorSchema.apellidos,
    edad:trabajadorSchema.edad,
    dni:trabajadorSchema.dni,
    horaInicioJornada: trabajadorSchema.horaInicioJornada ,
    horaFinJornada: trabajadorSchema.horaFinJornada,
    sueldo: trabajadorSchema.sueldo,
    sucursalId: trabajadorSchema.sucursalId
})


export const CreateTrabajadorValidador = (object:unknown)=> 
    createtrabajadorSchema.safeParse(object)

export const UbdateTrabajadorValidator = (object:unknown)=>
    createtrabajadorSchema.partial().safeParse(object)

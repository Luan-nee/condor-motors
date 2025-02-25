import { trabajadorSchema } from '@/domain/validators/entities/trabajadores/trabajadores.schema'
import { z } from 'zod'

const createtrabajadorSchema = z.object({
    nombre: trabajadorSchema.nombre,
    apellido: trabajadorSchema.apellido,
    DNI:trabajadorSchema.DNI,
    edad:trabajadorSchema.edad,
    H_incio: trabajadorSchema.H_inicio,
    H_final: trabajadorSchema.H_final,
    Sueldo: trabajadorSchema.Sueldo,
    SucursalPuesto: trabajadorSchema.SucursalPuesto
})


export const CreateTrabajadorValidador = (object:unknown)=> 
    createtrabajadorSchema.safeParse(object)

export const UbdateTrabajadorValidator = (object:unknown)=>
    createtrabajadorSchema.partial().safeParse(object)

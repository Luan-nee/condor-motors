
import {z} from 'zod'

const expresion = /^[a-zA-ZñÑáéíóúÁÉÍÓÚ\s]/;
const expresionNumbers = /^[0-9]/;
export const trabajadorSchema = {
    nombre:z.string({
        message:"El nombre de la persona es proviniente del DNI"
        })
        .min(2)
        .max(50)
        .refine((valor)=> expresion.test(valor),{
            message:"El nombre del trabajador no puede tener caracteres especiales"
        }),
    apellido:z.string({
        message:"El apellido debe ser tipo string obligatorio"
        })
        .min(2)
        .max(50)
        .refine((valor)=> expresion.test(valor),{
            message:"El apellido no puede contener caracteres especiales"
        }),
    edad:z.number({
        message:"La edad no puede ser representada en letras solo numeros"
    }).min(1).max(99).refine((valor)=> expresionNumbers.test(valor.toString() ),{
        message:"La edad "
    }),
    DNI:z.string({
        message:"El dni de preferencia tiene que ser tipo string"
    })
    .min(7)
    .max(7)
    .refine((valor)=> expresionNumbers.test(valor),{
        message:"El DNI no puede contener letras , solo numeros"
    }),
    H_inicio:z.number({
        message:"la hora es un tipo numero no otro tipo de variable"
    }).min(0).max(99).refine((valor)=>expresionNumbers.test(valor.toString()),{
        message:"La hora no puede ser mayor a 100 , y tampoco puede contener otros caracteres aparte de los numeros"
    }),
    H_final:z.number({
        message:"La hora de salida tienes que ser tipo numero"
    }).min(0).max(99).refine((valor)=> expresionNumbers.test(valor.toString()),{
        message:"La hora de salida no puede contener caracteres especiales"
    }),
    Sueldo:z.number({
        message:"El sueldo debe de ser interpretado en numeros"
    }).optional(),
    SucursalPuesto:z.number({
        message:"La Id del sucursal es un numero"
    })
}
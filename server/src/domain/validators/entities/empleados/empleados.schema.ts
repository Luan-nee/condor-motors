
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
    apellidos:z.string({
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
        }).optional(),
    dni:z.string({
            message:"El dni de preferencia tiene que ser tipo string"
        })
        // .min(6)
        // .max(7)
        .refine((valor)=> {
            if(!expresionNumbers.test(valor)){
                return false;
            }
            if(valor.length !== 8){
                return false;
            } 

            return true;
        },{
            message:"El DNI no puede contener letras , solo numeros"
        }),
    horaInicioJornada:z.string({
        message:"la hora es un tipo numero no otro tipo de variable"
    }),
    horaFinJornada:z.string({
        message:"La hora de salida tienes que ser tipo numero"
    }),
    fechaContratacion:z.string({
        message:"._. error"
    }).date().optional(),
    sueldo:z.number({
        message:"El sueldo debe de ser interpretado en numeros"
    }).min(0).max(5000).optional(),
    sucursalId:z.number({
        message:"La Id del sucursal es un numero"
    })
}
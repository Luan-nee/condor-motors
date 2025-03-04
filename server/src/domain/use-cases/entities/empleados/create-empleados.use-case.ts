import { permissionCodes } from "@/consts";
import { CustomError } from "@/core/errors/custom.error";
import { empleadosTable, sucursalesTable } from "@/db/schema";
import type {CreateTrabajadorDto} from '@/domain/dtos/entities/trabajadores/create-empleados.dto'
import { EmpleadoEntityMapper } from "@/domain/mappers/empleado-entity.mapper";
import { db } from '@db/connection'
import { eq, ilike } from 'drizzle-orm'

export class CreateEmpleado {
    private readonly authPayload: AuthPayload
    private readonly permissionCreateAny = permissionCodes.empleados

    constructor(authPayload: AuthPayload){
        this.authPayload = authPayload;
    }

    async execute( createEmpleadoDto : CreateTrabajadorDto){
        const empleadoConDNI = await db
            .select()
            .from(empleadosTable)
            .where(ilike(empleadosTable.dni,createEmpleadoDto.dni));
        

        if(empleadoConDNI.length > 0){
            throw CustomError.badRequest(`El empleado con este DNI ya esta registrado`)
        }

        const empleadoSucursal = await db.select()
            .from(sucursalesTable)
            .where(eq(sucursalesTable.id, createEmpleadoDto.sucursalId))

        if(empleadoSucursal.length < 1){
            throw CustomError.badRequest("La sucursal ingresada no existe");
        }

        const suelsostring = (createEmpleadoDto.sueldo === undefined)? undefined : createEmpleadoDto.sueldo.toFixed(2);
        const fechaContra  = ( typeof createEmpleadoDto.fechaContratacion !== "string")? undefined : new Date(createEmpleadoDto.fechaContratacion); 
        const InsertarEmpleado = await db 
            .insert(empleadosTable)
            .values({
                nombre: createEmpleadoDto.nombre,
                apellidos:createEmpleadoDto.apellidos,
                edad:createEmpleadoDto.edad,
                dni:createEmpleadoDto.dni,
                horaInicioJornada:createEmpleadoDto.horaInicioJornada,
                horaFinJornada:createEmpleadoDto.horaFinJornada,
                fechaContratacion: fechaContra,
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
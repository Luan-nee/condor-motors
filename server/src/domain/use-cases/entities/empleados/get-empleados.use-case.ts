import { orderValues } from '@/consts'
import { db } from "@/db/connection";
import { empleadosTable } from "@/db/schema";
import { QueriesDto } from "@/domain/dtos/query-params/queries.dto";
import { ilike, or, SQL } from "drizzle-orm";
import { asc,desc} from 'drizzle-orm'


export class GetEmpleados{
    private readonly authPayload: AuthPayload
    private readonly selectFields = {
        id: empleadosTable.id,
        nombre:empleadosTable.nombre,
        apellidos:empleadosTable.apellidos,
        ubicacionFoto:empleadosTable.ubicacionFoto,
        edad:empleadosTable.edad,
        dni:empleadosTable.dni,
        horaInicioJornada:empleadosTable.horaInicioJornada,
        horaFinJornada:empleadosTable.horaFinJornada,
        fechaContratacion:empleadosTable.fechaContratacion,
        sueldo:empleadosTable.sueldo,
        sucursalId:empleadosTable.sucursalId
    }   

    private readonly validSortBy= {
        fechaCreacion: empleadosTable.fechaCreacion,
        nombre: empleadosTable.nombre,
        dni: empleadosTable.dni
    } as const

    constructor(authPayload:AuthPayload){
        this.authPayload = authPayload;
    }

    private isValidSortBy(
        sortBy: string
      ): sortBy is keyof typeof this.validSortBy {
        return Object.keys(this.validSortBy).includes(sortBy)
      }
    
      private getSortByColumn(sortBy: string) {
        if (
          Object.keys(this.validSortBy).includes(sortBy) &&
          this.isValidSortBy(sortBy)
        ) {
          return this.validSortBy[sortBy]
        }
    
        return this.validSortBy.fechaCreacion
      }

    private async getAnyEmpleados(queriesDto : QueriesDto,order:SQL,whereCondition: SQL | undefined ){
        return await db.select(this.selectFields)
                .from(empleadosTable)
                .where(whereCondition)
                .orderBy(order)
                .limit(queriesDto.page_size)
                .offset(queriesDto.page_size * (queriesDto.page - 1));      
    }
    

    private async GetEmpleados(queriesDto: QueriesDto){
        const sortByColumn = this.getSortByColumn(queriesDto.sort_by)   
        const order =
              queriesDto.order === orderValues.asc
                ? asc(sortByColumn)
                : desc(sortByColumn)
        
        const whereCondition = queriesDto.search.length > 0 ? or(
                ilike(empleadosTable.dni,`%${queriesDto.search}%`),
                ilike(empleadosTable.nombre,`%${queriesDto.search}%`)
            ) : undefined;

        
        const empleados = await this.getAnyEmpleados(queriesDto,order, whereCondition);
        if(empleados.length <= 0){
            return [];
        }
        return empleados;
    }

    async execute(queriesDto: QueriesDto){

        const empleados = await this.GetEmpleados(queriesDto);

        return empleados;
    }

}


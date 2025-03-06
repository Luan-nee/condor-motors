import {
  paramsBaseSchema,
  queriesBaseSchema
} from '@/domain/validators/query-params/query-params.schema'
import z from 'zod'

const ParamsNumericIdSchema = z.object({
  id: paramsBaseSchema.numericId
})

export const paramsNumericIdValidator = (object: unknown) =>
  ParamsNumericIdSchema.safeParse(object)

const ParamsUUIDSchema = z.object({
  id: paramsBaseSchema.uuid
})

export const paramsUUIDValidator = (object: unknown) =>
  ParamsUUIDSchema.safeParse(object)

const ParamsSucursalIdSchema = z.object({
  sucursalId: paramsBaseSchema.numericId
})

export const paramsSucursalIdValidator = (object: unknown) =>
  ParamsSucursalIdSchema.safeParse(object)

export const QueriesSchema = z.object({
  sort_by: queriesBaseSchema.sort_by,
  order: queriesBaseSchema.order,
  page: queriesBaseSchema.page,
  search: queriesBaseSchema.search,
  page_size: queriesBaseSchema.page_size,
  filter: queriesBaseSchema.filter,
  filter_value: queriesBaseSchema.filter_value,
  filter_type: queriesBaseSchema.filter_type
})

export const queriesValidator = (object: unknown) =>
  QueriesSchema.safeParse(object)

/* 
Explicación de los Parámetros de Consulta
sort_by=name: Ordena los resultados por el campo name.
order=asc: Ordena los resultados en orden ascendente.
page=2: Solicita la segunda página de resultados.
search=engine: Filtra los resultados que contienen la palabra "engine".
page_size=10: Define el tamaño de la página como 10 elementos.
*/

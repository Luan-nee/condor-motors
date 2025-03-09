/* eslint-disable no-console */
import { envs } from '@/config/envs'
import { isProduction } from '@/consts'
import { db } from '@db/connection'
import * as schema from '@db/schema'
import { seed } from 'drizzle-seed'
import { exit } from 'process'

const generateIds = (length: number) =>
  Array.from({ length }).map((_, i) => i + 1)

const unidadesValues = [
  'No especificada',
  'Unidad',
  'Paquete',
  'Docena',
  'Decena'
]
const categoriasValues = [
  'No especificada',
  'Cascos',
  'Stickers',
  'Motos',
  'Toritos'
]
const marcasValues = ['Sin marca', 'Genérico', 'Honda', 'Suzuki', 'Bajaj']

const sucursalesCount = 3
const productosCount = 15

const getRandomNumber = (min: number, max: number) => {
  const minCeiled = Math.ceil(min)
  const maxFloored = Math.floor(max) + 1
  return Math.floor(Math.random() * (maxFloored - minCeiled) + minCeiled)
}

const newSchema = {
  sucursales: schema.sucursalesTable,
  unidades: schema.unidadesTable,
  categorias: schema.categoriasTable,
  marcas: schema.marcasTable,
  productos: schema.productosTable
}

const seedDatabase = async () => {
  await seed(db, newSchema).refine((f) => ({
    sucursales: {
      count: sucursalesCount,
      columns: {
        nombre: f.companyName(),
        ubicacion: f.streetAddress()
      }
    },
    unidades: {
      count: unidadesValues.length,
      columns: {
        nombre: f.valuesFromArray({
          values: unidadesValues,
          isUnique: true
        }),
        descripcion: f.loremIpsum()
      }
    },
    marcas: {
      count: marcasValues.length,
      columns: {
        nombre: f.valuesFromArray({
          values: marcasValues,
          isUnique: true
        }),
        descripcion: f.loremIpsum()
      }
    },
    categorias: {
      count: categoriasValues.length,
      columns: {
        nombre: f.valuesFromArray({
          values: categoriasValues,
          isUnique: true
        }),
        descripcion: f.loremIpsum()
      }
    },
    productos: {
      count: productosCount,
      columns: {
        sku: f.string({ isUnique: true }),
        nombre: f.companyName({ isUnique: true }),
        descripcion: f.loremIpsum(),
        maxDiasSinReabastecer: f.int({
          minValue: 1,
          maxValue: 300
        }),
        unidadId: f.valuesFromArray({
          values: generateIds(unidadesValues.length)
        }),
        categoriaId: f.valuesFromArray({
          values: generateIds(categoriasValues.length)
        }),
        marcaId: f.valuesFromArray({
          values: generateIds(marcasValues.length)
        })
      }
    }
  }))

  const preciosProductos = generateIds(productosCount).flatMap((productoId) =>
    generateIds(sucursalesCount).flatMap((sucursalId) => ({
      precioBase: getRandomNumber(50, 300).toFixed(2),
      precioMayorista: getRandomNumber(50, 300).toFixed(2),
      precioOferta: getRandomNumber(50, 300).toFixed(2),
      productoId,
      sucursalId
    }))
  )

  const inventarios = generateIds(productosCount).flatMap((productoId) =>
    generateIds(sucursalesCount).flatMap(() => ({
      stock: getRandomNumber(100, 300),
      productoId
    }))
  )

  const inventariosId = await db
    .insert(schema.inventariosTable)
    .values(inventarios)
    .returning({ id: schema.inventariosTable.id })

  await db.insert(schema.preciosProductosTable).values(preciosProductos)

  let index = 0
  const sucursalesInventarios = generateIds(productosCount).flatMap(() =>
    generateIds(sucursalesCount).flatMap((sucursalId) => {
      const values = {
        inventarioId: inventariosId[index].id,
        sucursalId
      }

      index += 1
      return values
    })
  )

  await db
    .insert(schema.sucursalesInventariosTable)
    .values(sucursalesInventarios)
}

const { NODE_ENV: nodeEnv } = envs

if (!isProduction) {
  seedDatabase()
    .then(() => {
      exit()
    })
    .catch((error: unknown) => {
      console.error(error)
      exit(1)
    })
} else {
  console.log(`Database not modified`)
  console.log(`You are in ${nodeEnv} enviroment`)
}

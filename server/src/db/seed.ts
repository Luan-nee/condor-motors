/* eslint-disable no-console */
import { BcryptAdapter } from '@/config/bcrypt'
import { envs } from '@/config/envs'
import { JwtAdapter } from '@/config/jwt'
import { isProduction, permissionCodes } from '@/consts'
import { formatCode } from '@/core/lib/format-values'
import { getRandomValueFromArray } from '@/core/lib/utils'
import { db } from '@db/connection'
import * as schema from '@db/schema'
import { faker } from '@faker-js/faker'
import { exit } from 'process'

const unidadesDefault = [
  'No especificada',
  'Unidad',
  'Paquete',
  'Docena',
  'Decena'
]

const categoriasDefault = [
  'No especificada',
  'Cascos',
  'Stickers',
  'Motos',
  'Toritos'
]

const marcasDefault = ['Sin marca', 'Genérico', 'Honda', 'Suzuki', 'Bajaj']

const estadosTransferenciasInventariosDefault = [
  'Pendiente',
  'Solicitando',
  'Rechazado',
  'Completado'
]

const tiposPersonasDefault = ['Persona Natural', 'Persona Juridica']

const sucursalesCount = 3
const empleadosCount = 6
const rolesCount = 2
const productosCount = 15

const sucursalesValues = Array.from({ length: sucursalesCount }).map((_, i) => {
  if (i === 0) {
    return {
      nombre: 'Sucursal Principal',
      sucursalCentral: true,
      direccion: 'Desconocida'
    }
  }

  return {
    nombre: faker.company.name() + i.toString(),
    sucursalCentral: faker.datatype.boolean(),
    direccion: faker.location.streetAddress({ useFullAddress: true })
  }
})

const rolesValues = Array.from({ length: rolesCount }).map((_, i) => {
  if (i === 0) {
    return {
      codigo: 'administrador',
      nombreRol: 'Adminstrador'
    }
  }

  const rol = faker.person.jobArea()

  return {
    codigo: rol.toLocaleLowerCase(),
    nombreRol: rol
  }
})

const unidadesValues = unidadesDefault.map((unidad) => ({
  nombre: unidad,
  descripcion: faker.lorem.words({ min: 10, max: 20 })
}))

const categoriasValues = categoriasDefault.map((categoria) => ({
  nombre: categoria,
  descripcion: faker.lorem.words({ min: 10, max: 20 })
}))

const marcasValues = marcasDefault.map((marca) => ({
  nombre: marca,
  descripcion: faker.lorem.words({ min: 10, max: 20 })
}))

const estadosTransferenciasInventariosValues =
  estadosTransferenciasInventariosDefault.map((estado) => ({
    nombre: estado,
    codigo: formatCode(estado)
  }))

const tiposPersonasValues = tiposPersonasDefault.map((tipoPersona) => ({
  nombre: tipoPersona,
  codigo: formatCode(tipoPersona)
}))

const adminUser = {
  usuario: envs.ADMIN_USER,
  clave: envs.ADMIN_PASSWORD
}

const transformPermissionCodes = (codes: typeof permissionCodes) =>
  Object.values(codes).flatMap((category) =>
    Object.values(category).map((code) => ({
      nombrePermiso: code,
      codigoPermiso: code
    }))
  )

const permissions = transformPermissionCodes(permissionCodes)

const seedDatabase = async () => {
  const hashedPassword = await BcryptAdapter.hash(adminUser.clave)
  const secret = JwtAdapter.randomSecret()

  const sucursales = await db
    .insert(schema.sucursalesTable)
    .values(sucursalesValues)
    .returning({ id: schema.sucursalesTable.id })

  const empleadosValues = Array.from({ length: empleadosCount }).map((_, i) => {
    const [fechaString] = faker.date.recent().toISOString().split('T')
    const baseValues = {
      edad: faker.number.int({ min: 18, max: 60 }),
      dni:
        faker.number.int({ min: 1111111, max: 9999999 }).toString() +
        i.toString(),
      horaInicioJornada: '08:00:00',
      horaFinJornada: '17:00:00',
      fechaContratacion: fechaString
    }

    if (i === 0) {
      const [sucursal] = sucursales
      return {
        nombre: 'Administrador',
        apellidos: 'Principal',
        sucursalId: sucursal.id,
        ...baseValues
      }
    }

    return {
      nombre: faker.person.firstName(),
      apellidos: faker.person.lastName(),
      sucursalId: getRandomValueFromArray(sucursales).id,
      ...baseValues
    }
  })

  const [admin] = await db
    .insert(schema.empleadosTable)
    .values(empleadosValues)
    .returning({ id: schema.empleadosTable.id })

  const [adminRole] = await db
    .insert(schema.rolesCuentasEmpleadosTable)
    .values(rolesValues)
    .returning({ id: schema.rolesCuentasEmpleadosTable.id })

  const permisosId = await db
    .insert(schema.permisosTable)
    .values(permissions)
    .returning({ id: schema.permisosTable.id })

  await db.insert(schema.rolesPermisosTable).values(
    permisosId.map((permiso) => ({
      permisoId: permiso.id,
      rolId: adminRole.id
    }))
  )

  await db.insert(schema.cuentasEmpleadosTable).values({
    usuario: adminUser.usuario,
    clave: hashedPassword,
    secret,
    rolCuentaEmpleadoId: adminRole.id,
    empleadoId: admin.id
  })

  const unidades = await db
    .insert(schema.unidadesTable)
    .values(unidadesValues)
    .returning({ id: schema.unidadesTable.id })

  const categorias = await db
    .insert(schema.categoriasTable)
    .values(categoriasValues)
    .returning({ id: schema.categoriasTable.id })

  const marcas = await db
    .insert(schema.marcasTable)
    .values(marcasValues)
    .returning({ id: schema.marcasTable.id })

  const productosValues = Array.from({ length: productosCount }).map(
    (_, i) => ({
      sku: faker.string.alphanumeric(11) + i.toString(),
      nombre: faker.commerce.productName() + i.toString(),
      descripcion: faker.commerce.productDescription(),
      maxDiasSinReabastecer: faker.number.int({ min: 20, max: 90 }),
      unidadId: getRandomValueFromArray(unidades).id,
      categoriaId: getRandomValueFromArray(categorias).id,
      marcaId: getRandomValueFromArray(marcas).id
    })
  )

  const productos = await db
    .insert(schema.productosTable)
    .values(productosValues)
    .returning({ id: schema.productosTable.id })

  const detallesProductosValues = productos.flatMap((producto) =>
    sucursales.flatMap((sucursal) => ({
      precioBase: faker.commerce.price({ min: 160, max: 200 }),
      precioMayorista: faker.commerce.price({ min: 150, max: 180 }),
      precioOferta: faker.commerce.price({ min: 155, max: 180 }),
      stock: faker.number.int({ min: 50, max: 200 }),
      productoId: producto.id,
      sucursalId: sucursal.id
    }))
  )

  await db.insert(schema.detallesProductoTable).values(detallesProductosValues)

  const fotosProductosValues = productos.map((producto) => ({
    ubicacion: faker.string.alphanumeric(10),
    productoId: producto.id
  }))

  await db.insert(schema.fotosProductosTable).values(fotosProductosValues)

  await db
    .insert(schema.estadosTransferenciasInventarios)
    .values(estadosTransferenciasInventariosValues)

  await db.insert(schema.tiposPersonasTable).values(tiposPersonasValues)
}

const { NODE_ENV: nodeEnv } = envs

if (!isProduction) {
  seedDatabase()
    .then(() => {
      console.log('Database has been seeded correctly!')
      console.log('user credentials:', adminUser)
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

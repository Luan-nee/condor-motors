/* eslint-disable no-console */
import { BcryptAdapter } from '@/config/bcrypt'
import { envs } from '@/config/envs'
import { JwtAdapter } from '@/config/jwt'
import { isProduction, tiposDocClienteCodes } from '@/consts'
import { formatCode } from '@/core/lib/format-values'
import {
  getRandomNumber,
  getRandomUniqueElementsFromArray,
  getRandomValueFromArray,
  productWithTwoDecimals,
  roundTwoDecimals
} from '@/core/lib/utils'
import { db } from '@db/connection'
import * as schema from '@db/schema'
import { exit } from 'process'
import {
  adminPermissions,
  seedConfig,
  vendedorPermisssions,
  computadoraPermissions
} from '@db/config/seed.config'
import { computePriceOffer } from '@/core/lib/seed-utils'

const BATCH_SIZE = 500

const insertInBatches = async (
  data: any[],
  table: any,
  returningFields?: any
) => {
  const results = []
  for (let i = 0; i < data.length; i += BATCH_SIZE) {
    const batch = data.slice(i, i + BATCH_SIZE)
    if (returningFields !== undefined) {
      const result = await db
        .insert(table)
        .values(batch)
        .returning(returningFields)
      results.push(...result)
    } else {
      await db.insert(table).values(batch)
    }
  }

  return returningFields !== undefined ? results : undefined
}

const rolesValues = seedConfig.rolesDefault.map((rol) => ({
  codigo: formatCode(rol),
  nombre: rol
}))

const categoriasValues = seedConfig.categoriasDefault.map((categoria) => ({
  nombre: categoria,
  descripcion: 'Descripción de la categoría'
}))

const marcasValues = seedConfig.marcasDefault.map((marca) => ({
  nombre: marca,
  descripcion: 'Descripción de la marca'
}))

const coloresValues = seedConfig.coloresDefault.map((color) => ({
  nombre: color.nombre,
  hex: color.hex
}))

const { cuentas } = seedConfig
const {
  admin: adminAccount,
  vendedor: vendedorAccount,
  computadora: computadoraAccount
} = cuentas

const seedDatabase = async () => {
  const { faker } = await import('@faker-js/faker')

  const sucursalesValues = Array.from({
    length: seedConfig.sucursalesCount
  }).map((_, i) => {
    const id = (i + 1).toString()
    const sucursal = {
      nombre: faker.company.name() + i.toString(),
      direccion: faker.location.streetAddress({ useFullAddress: true }),
      sucursalCentral: faker.datatype.boolean(),
      serieFactura: `F${id.padStart(3, '0')}`,
      serieBoleta: `B${id.padStart(3, '0')}`,
      codigoEstablecimiento: id.padStart(4, '0')
    }

    if (i === 0) {
      return {
        ...sucursal,
        nombre: 'Sucursal Principal',
        sucursalCentral: true
      }
    }

    return sucursal
  })

  const hashedAdminPassword = await BcryptAdapter.hash(adminAccount.clave)
  const hashedVendedorPassword = await BcryptAdapter.hash(vendedorAccount.clave)
  const hashedComputadoraPassword = await BcryptAdapter.hash(
    computadoraAccount.clave
  )
  const adminSecret = JwtAdapter.randomSecret()
  const vendedorSecret = JwtAdapter.randomSecret()
  const computadoraSecret = JwtAdapter.randomSecret()

  const sucursales = await db
    .insert(schema.sucursalesTable)
    .values(sucursalesValues)
    .returning({ id: schema.sucursalesTable.id })

  const empleadosValues = Array.from({ length: seedConfig.empleadosCount }).map(
    (_, i) => {
      const [fechaString] = faker.date.recent().toISOString().split('T')
      const empleado = {
        nombre: faker.person.firstName(),
        apellidos: faker.person.lastName(),
        activo: faker.datatype.boolean(),
        dni:
          faker.number.int({ min: 1111111, max: 9999999 }).toString() +
          i.toString(),
        celular: faker.phone.number({ style: 'international' }),
        horaInicioJornada: '08:00:00',
        horaFinJornada: '17:00:00',
        fechaContratacion: fechaString,
        sucursalId: getRandomValueFromArray(sucursales).id
      }

      if (i === 0) {
        const [sucursal] = sucursales
        return {
          ...empleado,
          nombre: 'Administrador',
          apellidos: 'Principal',
          sucursalId: sucursal.id
        }
      }

      return empleado
    }
  )

  const empleados = await db
    .insert(schema.empleadosTable)
    .values(empleadosValues)
    .returning({
      id: schema.empleadosTable.id,
      sucursalId: schema.empleadosTable.sucursalId
    })

  const [admin, vendedorEmpleado, computadoraEmpleado] = empleados

  const [adminRole, vendedorRole, computadoraRole] = await db
    .insert(schema.rolesTable)
    .values(rolesValues)
    .returning({ id: schema.rolesTable.id })

  const permisos = await db
    .insert(schema.permisosTable)
    .values(adminPermissions)
    .returning({
      id: schema.permisosTable.id,
      codigo: schema.permisosTable.codigo
    })

  const vendedorPermisosCodigos = new Set(
    vendedorPermisssions.map((permiso) => permiso.codigo)
  )

  const permisosVendedor = permisos.filter((permiso) =>
    vendedorPermisosCodigos.has(permiso.codigo)
  )

  const computadoraPermisosCodigos = new Set(
    computadoraPermissions.map((permiso) => permiso.codigo)
  )

  const permisosComputadora = permisos.filter((permiso) =>
    computadoraPermisosCodigos.has(permiso.codigo)
  )

  await db.insert(schema.rolesPermisosTable).values([
    ...permisos.map((permiso) => ({
      permisoId: permiso.id,
      rolId: adminRole.id
    })),
    ...permisosVendedor.map((permiso) => ({
      permisoId: permiso.id,
      rolId: vendedorRole.id
    })),
    ...permisosComputadora.map((permiso) => ({
      permisoId: permiso.id,
      rolId: computadoraRole.id
    }))
  ])

  await db.insert(schema.cuentasEmpleadosTable).values([
    {
      usuario: adminAccount.usuario,
      clave: hashedAdminPassword,
      secret: adminSecret,
      eliminable: false,
      rolId: adminRole.id,
      empleadoId: admin.id
    },
    {
      usuario: vendedorAccount.usuario,
      clave: hashedVendedorPassword,
      secret: vendedorSecret,
      rolId: vendedorRole.id,
      empleadoId: vendedorEmpleado.id
    },
    {
      usuario: computadoraAccount.usuario,
      clave: hashedComputadoraPassword,
      secret: computadoraSecret,
      rolId: computadoraRole.id,
      empleadoId: computadoraEmpleado.id
    }
  ])

  const categorias = await db
    .insert(schema.categoriasTable)
    .values(categoriasValues)
    .returning({ id: schema.categoriasTable.id })

  const marcas = await db
    .insert(schema.marcasTable)
    .values(marcasValues)
    .returning({ id: schema.marcasTable.id })

  const colores = await db
    .insert(schema.coloresTable)
    .values(coloresValues)
    .returning({ id: schema.coloresTable.id })

  const productosValues = Array.from({ length: seedConfig.productosCount }).map(
    (_, i) => {
      const descuentoProdGratis = faker.datatype.boolean()

      const cantidadGratisDescuento = descuentoProdGratis
        ? faker.number.int({ min: 1, max: 2 })
        : undefined

      const porcentajeDescuento = !descuentoProdGratis
        ? faker.number.int({ min: 5, max: 10 })
        : undefined

      return {
        nombre: faker.commerce.productName() + i.toString(),
        descripcion: faker.commerce.productDescription(),
        maxDiasSinReabastecer: faker.number.int({ min: 20, max: 90 }),
        stockMinimo: faker.number.int({ min: 20, max: 30 }),
        cantidadMinimaDescuento: faker.number.int({ min: 2, max: 5 }),
        cantidadGratisDescuento,
        porcentajeDescuento,
        colorId: getRandomValueFromArray(colores).id,
        categoriaId: getRandomValueFromArray(categorias).id,
        marcaId: getRandomValueFromArray(marcas).id
      }
    }
  )

  const productos = await insertInBatches(
    productosValues,
    schema.productosTable,
    {
      id: schema.productosTable.id,
      nombre: schema.productosTable.nombre,
      stockMinimo: schema.productosTable.stockMinimo,
      cantidadMinimaDescuento: schema.productosTable.cantidadMinimaDescuento,
      cantidadGratisDescuento: schema.productosTable.cantidadGratisDescuento,
      porcentajeDescuento: schema.productosTable.porcentajeDescuento
    }
  )

  if (productos === undefined) {
    throw new Error(
      'Ha ocurrido un error inesperado al intentar insertar productos en la base de datos'
    )
  }

  const detallesProductosValues = productos.flatMap((producto) =>
    sucursales.flatMap((sucursal) => {
      const precioCompra = faker.commerce.price({ min: 100, max: 150 })
      const precioVenta = faker.commerce.price({ min: 160, max: 180 })
      const porcentajeGanancia = roundTwoDecimals(
        100 - (parseFloat(precioCompra) * 100) / parseFloat(precioVenta)
      )

      const stock = faker.number.int({ min: 10, max: 200 })

      return {
        precioCompra,
        precioVenta,
        precioOferta: faker.commerce.price({ min: 140, max: 160 }),
        porcentajeGanancia,
        stock,
        stockBajo:
          producto.stockMinimo !== null ? stock < producto.stockMinimo : false,
        liquidacion: faker.datatype.boolean(),
        productoId: producto.id,
        sucursalId: sucursal.id
      }
    })
  )

  await insertInBatches(detallesProductosValues, schema.detallesProductoTable)

  const fotosProductoValues = productos.map((producto) => ({
    path: `assets/${faker.string.alphanumeric(10)}.webp`,
    productoId: producto.id
  }))

  await db.insert(schema.fotosProductoTable).values(fotosProductoValues)

  await db
    .insert(schema.estadosTransferenciasInventarios)
    .values(seedConfig.estadosTransferenciasInvDefault)

  const detallesProductosMap = new Map(
    detallesProductosValues.map((detalle) => [
      `${detalle.productoId}:${detalle.sucursalId}`,
      detalle
    ])
  )

  const generateDetalles = (length: number, sucursalId: number) => {
    let total = 0

    const detalles = getRandomUniqueElementsFromArray(productos, length).map(
      (producto) => {
        const detallesProducto = detallesProductosMap.get(
          `${producto.id}:${sucursalId}`
        )

        if (detallesProducto === undefined) {
          throw new Error('Product not found')
        }

        const cantidad = faker.number.int({ min: 1, max: 12 })

        const { free, price } = computePriceOffer({
          cantidad,
          cantidadMinimaDescuento: producto.cantidadMinimaDescuento,
          cantidadGratisDescuento: producto.cantidadGratisDescuento,
          porcentajeDescuento: producto.porcentajeDescuento,
          precioVenta: detallesProducto.precioVenta,
          precioOferta: detallesProducto.precioOferta,
          liquidacion: producto.liquidacion
        })

        const cantidadTotal = cantidad + free
        const subtotal = productWithTwoDecimals(price, cantidad)
        total += subtotal

        return {
          productoId: detallesProducto.productoId,
          nombre: producto.nombre,
          cantidadGratis: free,
          descuento: producto.descuento,
          cantidadPagada: cantidad,
          cantidadTotal,
          precioUnitario: price,
          precioOriginal: parseFloat(detallesProducto.precioVenta),
          subtotal
        }
      }
    )

    return {
      detalles,
      total
    }
  }

  const proformasVentaValues = Array.from({
    length: seedConfig.proformasVentaCount
  }).map(() => {
    const empleado = getRandomValueFromArray(empleados)
    const { detalles, total } = generateDetalles(
      getRandomNumber(2, 12),
      empleado.sucursalId
    )

    return {
      nombre: faker.lorem.words({ min: 3, max: 6 }),
      total: total.toFixed(2),
      detalles,
      empleadoId: empleado.id,
      sucursalId: empleado.sucursalId
    }
  })

  await db.insert(schema.proformasVentaTable).values(proformasVentaValues)

  const notificacionesValues = Array.from({
    length: seedConfig.notificacionesCount
  }).flatMap(() =>
    sucursales.flatMap((sucursal) => ({
      titulo: faker.company.name(),
      descripcion: faker.lorem.words(20),
      sucursalId: sucursal.id
    }))
  )

  const tiposDocumentoCliente = await db
    .insert(schema.tiposDocumentoClienteTable)
    .values(seedConfig.tiposDocumentoClienteDefault)
    .returning({
      id: schema.tiposDocumentoClienteTable.id,
      codigo: schema.tiposDocumentoClienteTable.codigo
    })

  const clientesValues = Array.from({ length: seedConfig.clientesCount }).map(
    () => {
      const tipoDocumento = getRandomValueFromArray(tiposDocumentoCliente)
      const isPersonaJuridica =
        tipoDocumento.codigo === tiposDocClienteCodes.ruc
      const dni = faker.number.int({ min: 11111111, max: 99999999 }).toString()
      const numeroDocumento = isPersonaJuridica
        ? getRandomValueFromArray(['10', '20']) + dni + getRandomNumber(1, 9)
        : dni

      const denominacion = isPersonaJuridica
        ? faker.person.fullName()
        : faker.company.name()

      return {
        tipoDocumentoId: tipoDocumento.id,
        numeroDocumento,
        denominacion,
        direccion: faker.location.streetAddress(true),
        correo: faker.internet.email({ provider: 'mail.fake.local' }),
        telefono: faker.phone.number({ style: 'international' })
      }
    }
  )

  /* const clientes = */ await db
    .insert(schema.clientesTable)
    .values(clientesValues)
    .returning({
      id: schema.clientesTable.id,
      tipoDocumentoId: schema.clientesTable.tipoDocumentoId
    })

  /* const tiposDocFacturacion = */ await db
    .insert(schema.tiposDocFacturacionTable)
    .values(seedConfig.tiposDocumentoFacturacionDefault)
    .returning({
      id: schema.tiposDocFacturacionTable.id,
      codigo: schema.tiposDocFacturacionTable.codigo
    })

  await db
    .insert(schema.monedasFacturacionTable)
    .values(seedConfig.monedasFacturacionDefault)

  await db.insert(schema.metodosPagoTable).values(seedConfig.metodosPagoDefault)

  await db.insert(schema.tiposTaxTable).values(seedConfig.tiposTaxDefault)

  await db
    .insert(schema.estadosDocFacturacionTable)
    .values(seedConfig.estadosDocFacturacion)

  // const ventasValues = Array.from({ length: seedConfig.ventasCount }).map(
  //   () => {
  //     const cliente = getRandomValueFromArray(clientes)
  //     const isPersonaJuridica = false

  //     const tipoDocumento = getRandomValueFromArray(tiposDocFacturacion)

  //     return {
  //       observaciones: faker.lorem.words({ min: 4, max: 8 }),
  //       tipoDocumentoId: tipoDocumento.id
  //     }
  //   }
  // )

  await db.insert(schema.notificacionesTable).values(notificacionesValues)
}

const { NODE_ENV: nodeEnv } = envs

if (!isProduction) {
  if (seedConfig.empleadosCount < 3) {
    throw new Error('La cantidad de empleados configurada debe ser al menos 3')
  }

  seedDatabase()
    .then(() => {
      console.log('Database has been seeded correctly!')
      console.log('users credentials:', seedConfig.cuentas)
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

import { envs } from '@/config/envs'
import {
  permissionCodes,
  tiposDocFacturacionCodes,
  tiposTaxCodes
} from '@/consts'
import {
  transformPermissionsCodesFromArray,
  transformPermissionCodes
} from '@/core/lib/utils'

// El primer rol siempre será tratado como administrador y tendrá todos los permisos
export const seedConfig: SeedConfig = {
  cuentas: {
    admin: {
      usuario: envs.ADMIN_USER,
      clave: envs.ADMIN_PASSWORD
    },
    vendedor: {
      usuario: 'Vendedor',
      clave: 'Vende123'
    },
    computadora: {
      usuario: 'Computadora',
      clave: 'Compu123'
    }
  },
  rolesDefault: ['Administrador', 'Vendedor', 'Computadora'],
  categoriasDefault: [
    'No especificada',
    'Cascos',
    'Stickers',
    'Motos',
    'Toritos'
  ],
  marcasDefault: ['Sin marca', 'Genérico', 'Honda', 'Suzuki', 'Bajaj'],
  coloresDefault: [
    { nombre: 'No definido', hex: '#FFFFFF' },
    { nombre: 'Negro', hex: '#000000' },
    { nombre: 'Amarillo', hex: '#FFFF00' },
    { nombre: 'Rojo', hex: '#FF0000' },
    { nombre: 'Verde', hex: '#008000' },
    { nombre: 'Naranja', hex: '#FFA500' },
    { nombre: 'Morado', hex: '#800080' }
  ],
  estadosTransferenciasInventariosDefault: [
    'Pendiente',
    'Solicitando',
    'Rechazado',
    'Completado'
  ],
  tiposDocumentoClienteDefault: [
    {
      nombre: 'RUC',
      codigoSunat: '6'
    },
    {
      nombre: 'DNI',
      codigoSunat: '1'
    },
    {
      nombre: 'CARNET DE EXTRANJERÍA',
      codigoSunat: '4'
    },
    {
      nombre: 'PASAPORTE',
      codigoSunat: '7'
    },
    {
      nombre: 'CÉDULA DIPLOMÁTICA DE IDENTIDAD',
      codigoSunat: 'A'
    },
    {
      nombre: 'NO DOMICILIADO, SIN RUC',
      codigoSunat: '0'
    }
  ],
  tiposDocumentoFacturacionDefault: [
    {
      nombre: 'Factura electrónica',
      codigoSunat: '01',
      codigo: tiposDocFacturacionCodes.factura
    },
    {
      nombre: 'Boleta de venta electrónica',
      codigoSunat: '03',
      codigo: tiposDocFacturacionCodes.boleta
    }
  ],
  monedasFacturacionDefault: [{ nombre: 'Soles', codigoSunat: 'PEN' }],
  metodosPagoDefault: [
    {
      nombre: 'Contado',
      codigoSunat: 'Contado',
      codigoTipo: '0',
      activado: true
    }
  ],
  tiposTaxDefault: [
    {
      nombre: 'Con impuestos... not stonks 📉📉📉',
      codigoSunat: '10',
      porcentaje: 18,
      codigo: tiposTaxCodes.gravado
    },
    {
      nombre: 'Sin impuestos STONKS 📈📈📈',
      codigoSunat: '20',
      porcentaje: 0,
      codigo: tiposTaxCodes.exonerado
    },
    {
      nombre: 'Gratis y sin impuestos stonks? 📉📈❔',
      codigoSunat: '21',
      porcentaje: 0,
      codigo: tiposTaxCodes.gratuito
    }
  ],
  sucursalesCount: 3,
  empleadosCount: 9,
  productosCount: 30,
  proformasVentaCount: 16,
  notificacionesCount: 5,
  clientesCount: 5
}

export const adminPermissions = transformPermissionCodes(permissionCodes)

export const vendedorPermisssions = transformPermissionsCodesFromArray([
  permissionCodes.sucursales.getRelated,
  permissionCodes.empleados.getRelated,
  permissionCodes.productos.createRelated,
  permissionCodes.productos.getRelated,
  permissionCodes.productos.updateRelated,
  permissionCodes.inventarios.addRelated,
  permissionCodes.ventas.createRelated,
  permissionCodes.ventas.getRelated,
  permissionCodes.cuentasEmpleados.getRelated,
  permissionCodes.cuentasEmpleados.updateSelf,
  permissionCodes.reservasProductos.createAny,
  permissionCodes.reservasProductos.updateAny,
  permissionCodes.reservasProductos.deleteAny
])

export const computadoraPermissions = transformPermissionsCodesFromArray([
  permissionCodes.sucursales.getRelated,
  permissionCodes.empleados.getRelated,
  permissionCodes.productos.getRelated,
  permissionCodes.ventas.getRelated,
  permissionCodes.cuentasEmpleados.getRelated,
  permissionCodes.categorias.createAny
])

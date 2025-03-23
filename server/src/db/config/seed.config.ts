import { envs } from '@/config/envs'
import { permissionCodes } from '@/consts'
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
  rolesDefault: ['Adminstrador', 'Vendedor', 'Computadora'],
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
      codigo: '6'
    },
    {
      nombre: 'DNI',
      codigo: '1'
    },
    {
      nombre: 'CARNET DE EXTRANJERÍA',
      codigo: '4'
    },
    {
      nombre: 'PASAPORTE',
      codigo: '7'
    },
    {
      nombre: 'CÉDULA DIPLOMÁTICA DE IDENTIDAD',
      codigo: 'A'
    },
    {
      nombre: 'NO DOMICILIADO, SIN RUC',
      codigo: '0'
    }
  ],
  tiposDocumentoFacturacionDefault: [
    { nombre: 'Factura electrónica', codigo: '01' },
    { nombre: 'Boleta de venta electrónica', codigo: '03' }
  ],
  monedasFacturacionDefault: [{ nombre: 'Soles', codigo: 'PEN' }],
  metodosPagoDefault: [
    {
      nombre: 'Contado',
      codigo: 'Contado',
      tipo: '0',
      activado: true
    },
    {
      nombre: 'Crédito',
      codigo: 'Credito',
      tipo: '1',
      activado: false
    }
  ],
  tiposTaxDefault: [
    {
      nombre: 'Con impuestos... not stonks 📉📉📉',
      codigo: '10',
      tax: 18,
      tipo: 'gravado'
    },
    {
      nombre: 'Sin impuestos STONKS 📈📈📈',
      codigo: '20',
      tax: 0,
      tipo: 'exonerado'
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
  permissionCodes.cuentasEmpleados.updateSelf
])

export const computadoraPermissions = transformPermissionsCodesFromArray([
  permissionCodes.sucursales.getRelated,
  permissionCodes.empleados.getRelated,
  permissionCodes.productos.getRelated,
  permissionCodes.ventas.getRelated,
  permissionCodes.cuentasEmpleados.getRelated,
  permissionCodes.categorias.createAny
])

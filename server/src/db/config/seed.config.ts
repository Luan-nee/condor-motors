// El primer rol siempre será tratado como administrador y tendrá todos los permisos
export const seedConfig: SeedConfig = {
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
    'No definido',
    'Negro',
    'Amarillo',
    'Rojo',
    'Verde',
    'Naranja',
    'Morado'
  ],
  estadosTransferenciasInventariosDefault: [
    'Pendiente',
    'Solicitando',
    'Rechazado',
    'Completado'
  ],
  tiposPersonasDefault: ['Persona Natural', 'Persona Juridica'],
  sucursalesCount: 3,
  empleadosCount: 6,
  productosCount: 15
}

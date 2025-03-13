// El primer rol siempre será tratado como administrador y tendrá todos los permisos
export const seedConfig: SeedConfig = {
  rolesDefault: ['Adminstrador', 'Vendedor', 'Computadora'],
  unidadesDefault: ['No especificada', 'Unidad', 'Paquete', 'Docena', 'Decena'],
  categoriasDefault: [
    'No especificada',
    'Cascos',
    'Stickers',
    'Motos',
    'Toritos'
  ],
  marcasDefault: ['Sin marca', 'Genérico', 'Honda', 'Suzuki', 'Bajaj'],
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

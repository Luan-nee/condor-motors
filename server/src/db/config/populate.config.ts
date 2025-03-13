import { envs } from '@/config/envs'

export const populateConfig: PopulateConfig = {
  user: {
    usuario: envs.ADMIN_USER,
    clave: envs.ADMIN_PASSWORD
  },
  sucursal: {
    nombre: 'Sucursal Principal',
    sucursalCentral: true,
    direccion: 'Desconocida'
  },
  empleado: {
    nombre: 'Administrador',
    apellidos: 'Principal'
  },
  rolEmpleado: {
    codigo: 'administrador',
    nombreRol: 'Adminstrador'
  },
  defaultUnidad: {
    nombre: 'No especificada',
    descripcion: 'Unidad por defecto del sistema'
  },
  defaultCategoria: {
    nombre: 'No especificada',
    descripcion: 'Categoria por defecto del sistema'
  },
  defaultMarca: {
    nombre: 'Sin marca',
    descripcion: 'Marca por defecto del sistema'
  }
}
